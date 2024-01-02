use starknet::{ContractAddress, ClassHash};
use gol2::contracts::gol::GoL2::Snapshot;

#[starknet::interface]
trait IGoL2NFT<TContractState> {
    /// Read
    fn view_snapshot(self: @TContractState, generation: felt252) -> Snapshot;
    fn mint_token_address(self: @TContractState) -> ContractAddress;
    fn mint_price(self: @TContractState) -> u256;
    fn merkle_root(self: @TContractState) -> felt252;
    fn game_state_copies(self: @TContractState, game_state: felt252) -> u256;
    /// Write
    fn set_mint_price(ref self: TContractState, new_price: u256);
    fn set_mint_token_address(ref self: TContractState, new_addr: ContractAddress);
    fn set_merkle_root(ref self: TContractState, new_root: felt252);
    fn mint(ref self: TContractState, generation: felt252);
    // poseidon
    fn wl_mint(
        ref self: TContractState,
        generation: felt252,
        state: felt252,
        timestamp: u64,
        proof: Array<felt252>
    );
    fn wl_mint_ped(
        ref self: TContractState,
        generation: felt252,
        state: felt252,
        timestamp: u64,
        proof: Array<felt252>
    );
    fn withdraw(
        ref self: TContractState, token_addr: ContractAddress, amount: u256, to: ContractAddress
    );
    /// For future contract upgrades
    fn initializer(ref self: TContractState);
}

#[starknet::interface]
trait IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> Array<felt252>;
}


#[starknet::contract]
mod GoL2NFT {
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ClassHash,
        replace_class_syscall, contract_address_try_from_felt252
    };
    use openzeppelin::{
        access::ownable::OwnableComponent, introspection::src5::SRC5Component,
        upgrades::{UpgradeableComponent, interface::IUpgradeable}, token::erc721::{ERC721Component},
        token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait, interface::IERC20},
    };
    use gol2::{
        utils::{
            life_rules::evaluate_rounds, packing::{pack_game, unpack_game, revive_cell},
            uri::make_uri_array,
            constants::{
                INFINITE_GAME_GENESIS, DIM, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT
            },
            whitelist_pedersen::verify_pedersen_merkle, whitelist_poseidon::verify_poseidon_merkle
        },
        contracts::gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait,}
    };
    use super::{IGoL2NFTDispatcher, IGoL2NFTDispatcherTrait};
    use core::pedersen::pedersen;
    use core::poseidon::{PoseidonTrait, poseidon_hash_span};

    use debug::PrintTrait;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);


    /// Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    /// ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    /// SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;


    #[constructor]
    fn constructor(
        ref self: ContractState,
        _owner: ContractAddress,
        _name: felt252,
        _symbol: felt252,
        _gol2_addr: ContractAddress,
        _mint_token_addr: ContractAddress,
        _mint_price: u256,
        _merkle_root: felt252,
        _merkle_root_ped: felt252,
    ) {
        self.ownable.initializer(_owner);
        self.erc721.initializer(_name, _symbol);
        self.gol2_addr.write(_gol2_addr);
        self.mint_token_addr.write(_mint_token_addr);
        self.mint_price.write(_mint_price);
        self.merkle_root.write(_merkle_root);
        self.merkle_root_ped.write(_merkle_root_ped);
    }


    #[storage]
    struct Storage {
        /// GoL2 game address
        gol2_addr: ContractAddress,
        /// Mint price (wei)
        mint_price: u256,
        /// Mint token address
        mint_token_addr: ContractAddress,
        /// Map of gamestates -> number of times minted
        game_state_copies: LegacyMap<felt252, u256>,
        /// Merkle root for whitelist mints 
        merkle_root: felt252,
        merkle_root_ped: felt252,
        /// Snapshots of wl claims (pre-migration evolutions)
        snapshots: LegacyMap<felt252, super::Snapshot>,
        ///
        /// Component Storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    /// External Functions
    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
            IGoL2NFTDispatcher { contract_address: starknet::get_contract_address() }.initializer();
        }
    }

    #[external(v0)]
    impl ERC721MetadataImpl of super::IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.erc721.ERC721_name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc721.ERC721_symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            let current_generation_int = gol.get_current_generation(INFINITE_GAME_GENESIS).into();
            assert(0 < token_id && token_id <= current_generation_int, 'NFT: invalid token id');
            let game_state = gol.view_game(INFINITE_GAME_GENESIS, token_id.try_into().unwrap());
            let copies = self.game_state_copies.read(game_state);
            let timestamp = self.get_generation_snapshot(token_id.try_into().unwrap()).timestamp;
            let mut uri_path = make_uri_array(token_id, game_state, copies, timestamp);

            let mut token_uri: Array<felt252> = array![];
            loop {
                match uri_path.pop_front() {
                    Option::Some(el) => token_uri.append(el),
                    Option::None => { break; }
                };
            };
            token_uri
        }
    }

    #[external(v0)]
    impl GoL2NFTImpl of super::IGoL2NFT<ContractState> {
        /// Reads

        /// Get snapshot details (pre & post migration)
        fn view_snapshot(self: @ContractState, generation: felt252) -> super::Snapshot {
            self.get_generation_snapshot(generation)
        }

        /// Mint token address
        fn mint_token_address(self: @ContractState) -> ContractAddress {
            self.mint_token_addr.read()
        }

        /// Price to mint 1 token (in wei)
        fn mint_price(self: @ContractState) -> u256 {
            self.mint_price.read()
        }

        /// Gets the merkle root of the whitelist
        fn merkle_root(self: @ContractState) -> felt252 {
            self.merkle_root.read()
        }

        /// Gets the number of copies of a game state that have been minted
        // todo: internal or public ?
        fn game_state_copies(self: @ContractState, game_state: felt252) -> u256 {
            self.game_state_copies.read(game_state)
        }


        /// Owner only

        /// Set new mint price (in wei)
        fn set_mint_price(ref self: ContractState, new_price: u256) {
            self.ownable.assert_only_owner();
            self.mint_price.write(new_price);
        }

        /// Set new mint token address
        fn set_mint_token_address(ref self: ContractState, new_addr: ContractAddress) {
            self.ownable.assert_only_owner();
            self.mint_token_addr.write(new_addr);
        }

        /// Set new merkle root 
        // todo: event ? ped/pos 
        fn set_merkle_root(ref self: ContractState, new_root: felt252) {
            self.ownable.assert_only_owner();
            self.merkle_root.write(new_root);
        }

        /// Write

        /// Empty function for interface definition for future upgrades to contract
        fn initializer(ref self: ContractState) {}


        /// Mint token to caller
        fn mint(ref self: ContractState, generation: felt252) {
            /// Verify post-migration generation exists
            self.assert_valid_generation_post_migration(generation);
            /// Mint 
            self.mint_helper(get_caller_address(), generation.into());
        }

        /// Mint token to caller if their proof checks out
        fn wl_mint_ped(
            ref self: ContractState,
            generation: felt252,
            state: felt252,
            timestamp: u64,
            proof: Array<felt252>
        ) {
            /// Verify pre-migration generation exists (todo: upon migrate, the current gen needs to be saved for reference)
            self.assert_valid_generation_pre_migration(generation);
            /// Verify proof
            let leaf: felt252 = pedersen(
                pedersen(pedersen(pedersen(0, generation), get_caller_address().into()), state),
                timestamp.into()
            );
            verify_pedersen_merkle(self.merkle_root_ped.read(), leaf, proof);
            /// Mint 
            self.mint_helper(get_caller_address(), generation.into());
            /// Save snapshot details. 
            self.handle_snapshot(generation, get_caller_address(), state, timestamp);
        }

        fn wl_mint(
            ref self: ContractState,
            generation: felt252,
            state: felt252,
            timestamp: u64,
            proof: Array<felt252>
        ) {
            /// Verify pre-migration generation exists (todo: upon migrate, the current gen needs to be saved for reference)
            self.assert_valid_generation_pre_migration(generation);
            /// Verify proof
            let leaf: felt252 = poseidon_hash_span(
                array![generation, get_caller_address().into(), state, timestamp.into()].span()
            );
            verify_pedersen_merkle(self.merkle_root.read(), leaf, proof);
            /// Mint 
            self.mint_helper(get_caller_address(), generation.into());
            /// Save snapshot details. 
            self.handle_snapshot(generation, get_caller_address(), state, timestamp);
        }

        /// Withdraw erc20 tokens from contract to `to`.
        fn withdraw(
            ref self: ContractState, token_addr: ContractAddress, amount: u256, to: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            let token = ERC20ABIDispatcher { contract_address: token_addr };
            let success = token.transfer_from(starknet::get_contract_address(), to, amount);
            assert(success, 'NFT: withdraw failed');
        }
    }

    /// Internal Functions
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Fetch a generation snapshot pre & post migration
        fn get_generation_snapshot(self: @ContractState, generation: felt252) -> super::Snapshot {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            let generations_in_gol: u256 = gol.pre_migration_generations().into();
            if generation.into() > generations_in_gol {
                gol.view_snapshot(generation)
            } else {
                self.snapshots.read(generation)
            }
        }


        /// Charge user to mint
        fn charge_user(ref self: ContractState) {
            let payment_token = ERC20ABIDispatcher {
                contract_address: self.mint_token_addr.read()
            };
            let success = payment_token
                .transfer_from(
                    get_caller_address(), starknet::get_contract_address(), self.mint_price.read()
                );
            assert(success, 'NFT: payment failed');
        }

        fn increment_copies(ref self: ContractState, generation: felt252) {
            /// Increment game_state duplicates
            let game_state = IGoL2Dispatcher { contract_address: self.gol2_addr.read() }
                .view_game(INFINITE_GAME_GENESIS, generation.into());
            self.game_state_copies.write(game_state, self.game_state_copies.read(game_state) + 1);
        }

        fn mint_helper(ref self: ContractState, to: ContractAddress, generation: felt252) {
            /// Charge caller for mint
            self.charge_user();
            /// Mint caller 1 token
            self.erc721._mint(get_caller_address(), generation.into());
            /// Increment game_state duplicates
            self.increment_copies(generation);
        }


        /// Returns the number of generations in the infinite game at the time of migration.
        /// @dev Marker for when generation snapshots started being saved in contract. 
        fn get_pre_migration_generations(self: @ContractState) -> u256 {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            gol.pre_migration_generations().into()
        }

        /// Checks if a generation is valid in the GoL2 contract post-migration.
        /// @dev A post-migration generation is valid if it is greater than the 
        /// miration marker stored in the gol contract, and less than or equal to
        /// the current generation.
        fn assert_valid_generation_post_migration(self: @ContractState, generation: felt252) {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            let generation_int: u256 = generation.into();
            let current_generation_int: u256 = gol
                .get_current_generation(INFINITE_GAME_GENESIS)
                .into();
            assert(
                (self.get_pre_migration_generations() < generation_int)
                    && (generation_int <= current_generation_int),
                'NFT: invalid generation'
            );
        }

        /// Checks if a generation is valid in the GoL2 contract pre-migration.
        /// @dev A pre-generation is valid if it is greater than 0, and less 
        /// than or equal to the miration marker stored in the gol contract.
        fn assert_valid_generation_pre_migration(self: @ContractState, generation: felt252) {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            /// Verify generation exists
            let generation_int: u256 = generation.into();
            let current_generation_int: u256 = gol
                .get_current_generation(INFINITE_GAME_GENESIS)
                .into();
            assert(
                (0 < generation_int) && (generation_int <= self.get_pre_migration_generations()),
                'NFT: invalid generation'
            );
        }

        /// Saves snapshot details.
        /// @dev This is done because the GoL2 contract does not save snapshot details pre-migration.
        /// @dev These details are used to generate the token URI.
        fn handle_snapshot(
            ref self: ContractState,
            generation: felt252,
            user_id: ContractAddress,
            game_state: felt252,
            timestamp: u64
        ) {
            self.snapshots.write(generation, super::Snapshot { user_id, game_state, timestamp });
        }
    }
}
