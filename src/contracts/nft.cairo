use starknet::{ContractAddress, ClassHash};
use gol2::contracts::gol::GoL2::Snapshot;

#[starknet::interface]
trait IGoL2NFT<TContractState> {
    /// Reads
    fn merkle_root(self: @TContractState) -> felt252;
    fn mint_price(self: @TContractState) -> u256;
    fn mint_token_address(self: @TContractState) -> ContractAddress;
    fn game_state_copies(self: @TContractState, game_state: felt252) -> felt252;
    /// Writes
    fn set_merkle_root(ref self: TContractState, new_root: felt252);
    fn set_mint_price(ref self: TContractState, new_price: u256);
    fn set_mint_token_address(ref self: TContractState, new_addr: ContractAddress);
    fn mint(ref self: TContractState, generation: felt252);
    fn whitelist_mint(
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

/// @dev Not using the one from OpenZeppelin so we can return 
/// an Array<felt252> instead of a felt252 for token_uri, and 
/// also to implement a total_supply function.
#[starknet::interface]
trait IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> Array<felt252>;
    fn total_supply(self: @TContractState) -> u256;
}


#[starknet::contract]
mod GoL2NFT {
    use super::{IGoL2NFTDispatcher, IGoL2NFTDispatcherTrait};
    use gol2::{
        utils::{
            life_rules::evaluate_rounds, packing::{unpack_game}, uri::make_uri_array,
            constants::{INFINITE_GAME_GENESIS}, whitelist::{assert_valid_proof, create_leaf_hash},
        },
        contracts::gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait,}
    };
    use openzeppelin::{
        access::ownable::OwnableComponent, introspection::src5::SRC5Component,
        upgrades::{UpgradeableComponent, interface::IUpgradeable}, token::erc721::{ERC721Component},
        token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait, interface::IERC20},
    };
    use starknet::{get_caller_address, get_contract_address, ContractAddress, ClassHash};
    use debug::PrintTrait;

    /// Components
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

    /// Constructor
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
    ) {
        /// Set admin.
        self.ownable.initializer(_owner);
        /// Set name & symbol.
        self.erc721.initializer(_name, _symbol);
        /// Set address of GoL2 contract.
        self.gol2_addr.write(_gol2_addr);
        /// Set mint token address.
        self.mint_token_addr.write(_mint_token_addr);
        /// Set mint price.
        self.mint_price.write(_mint_price);
        /// Set merkle root.
        self.merkle_root.write(_merkle_root);
    }

    /// Storage
    #[storage]
    struct Storage {
        /// Total number of tokens minted.
        total_supply: u256,
        /// GoL2 game contract address.
        gol2_addr: ContractAddress,
        /// Mint price (wei).
        mint_price: u256,
        /// Mint token contract address.
        mint_token_addr: ContractAddress,
        /// Map of gamestates to the number of times it was minted.
        /// @dev There is an assumption that overflow limits will not be reached.
        /// With gas costs alone, to overflow would be an astronomical amount of money.
        /// (A trillion trillion trillion... dollars for each atom in the universe
        /// type of money with a bunch of 0s left over).
        game_state_copies: LegacyMap<felt252, felt252>,
        /// Merkle root for whitelist mints.
        merkle_root: felt252,
        /// Component storage.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    /// Events
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
            IGoL2NFTDispatcher { contract_address: get_contract_address() }.initializer();
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
            let generation: felt252 = token_id.try_into().unwrap();
            let snapshot = gol.view_snapshot(generation);
            let game_state = gol.view_game(INFINITE_GAME_GENESIS, generation);
            let cell_array = unpack_game(game_state);
            let copies = self.game_state_copies.read(game_state);

            make_uri_array(token_id, game_state, cell_array, copies, snapshot.timestamp)
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }
    }

    #[external(v0)]
    impl GoL2NFTImpl of super::IGoL2NFT<ContractState> {
        /// Reads

        /// Get the mint fee token address.
        fn mint_token_address(self: @ContractState) -> ContractAddress {
            self.mint_token_addr.read()
        }

        /// Get the price to mint 1 token (in wei).
        fn mint_price(self: @ContractState) -> u256 {
            self.mint_price.read()
        }

        /// Get the merkle root of the whitelist.
        fn merkle_root(self: @ContractState) -> felt252 {
            self.merkle_root.read()
        }

        /// Get the number of copies that a game state has been minted.
        fn game_state_copies(self: @ContractState, game_state: felt252) -> felt252 {
            self.game_state_copies.read(game_state)
        }

        /// Writes

        /// Owner only

        /// Set a new merkle root for the whitelist.
        fn set_merkle_root(ref self: ContractState, new_root: felt252) {
            self.ownable.assert_only_owner();
            self.merkle_root.write(new_root);
        }

        /// Set a new mint price (in wei).
        fn set_mint_price(ref self: ContractState, new_price: u256) {
            self.ownable.assert_only_owner();
            self.mint_price.write(new_price);
        }

        /// Set a new mint fee token address.
        fn set_mint_token_address(ref self: ContractState, new_addr: ContractAddress) {
            self.ownable.assert_only_owner();
            self.mint_token_addr.write(new_addr);
        }

        /// Withdraw ERC20 tokens from contract to `to`.
        fn withdraw(
            ref self: ContractState, token_addr: ContractAddress, amount: u256, to: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            assert(
                ERC20ABIDispatcher { contract_address: token_addr }.transfer(to, amount),
                'GoL2NFT: withdraw failed'
            );
        }

        /// Empty function for interface definition.
        /// @dev Useful for future contract upgrades.
        fn initializer(ref self: ContractState) {}

        /// Public

        /// Mint a token to the caller if they are the generation's owner.
        fn mint(ref self: ContractState, generation: felt252) {
            /// Verify caller owns snapshot
            self.assert_caller_owns_snapshot(generation);
            /// Mint 
            self.mint_helper(get_caller_address(), generation.into());
        }

        /// Mint a token to the caller if they have a vaild proof.
        /// @dev Because snapshots are only stored in the GoL2 contract post
        /// Cairo 1 migration, this function allows users to mint tokens for
        /// generations that were evolved before the migration.
        /// @dev If the caller's proof is valid, this contract writes the snapshot
        /// to the GoL2 contract.
        fn whitelist_mint(
            ref self: ContractState,
            generation: felt252,
            state: felt252,
            timestamp: u64,
            proof: Array<felt252>
        ) {
            /// Generate the leaf hash for the caller
            let leaf = create_leaf_hash(generation, state, timestamp);
            /// Verify proof
            assert_valid_proof(self.merkle_root.read(), leaf, proof);
            /// Save snapshot details. 
            self.handle_snapshot(generation, get_caller_address(), state, timestamp);
            /// Mint 
            self.mint_helper(get_caller_address(), generation.into());
        }
    }

    /// Internal Functions
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Charge the user to mint.
        fn charge_user(ref self: ContractState) {
            assert(
                ERC20ABIDispatcher { contract_address: self.mint_token_addr.read() }
                    .transfer_from(
                        get_caller_address(), get_contract_address(), self.mint_price.read()
                    ),
                'GoL2NFT: Payment failed'
            );
        }

        /// Increment the number of times a generation's gamestate is minted.
        fn increment_copies(ref self: ContractState, generation: felt252) {
            /// Increment game_state duplicates
            let game_state = IGoL2Dispatcher { contract_address: self.gol2_addr.read() }
                .view_game(INFINITE_GAME_GENESIS, generation.into());
            self.game_state_copies.write(game_state, self.game_state_copies.read(game_state) + 1);
        }

        /// Helper function for minting.
        fn mint_helper(ref self: ContractState, to: ContractAddress, generation: felt252) {
            /// Increment total supply
            self.total_supply.write(self.total_supply.read() + 1);
            /// Increment game_state duplicates
            self.increment_copies(generation);
            /// Charge caller for mint
            self.charge_user();
            /// Mint caller 1 token
            self.erc721._mint(get_caller_address(), generation.into());
        }

        /// Verify the caller is the owner of a generation.
        fn assert_caller_owns_snapshot(self: @ContractState, generation: felt252) {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            let snapshot = gol.view_snapshot(generation);
            assert(snapshot.user_id == get_caller_address(), 'GoL2NFT: Not snapshot owner');
        }

        /// Save (pre-migration) snapshot details.
        /// @dev Post migration snapshots are stored during evolution (in infinite game).
        /// This writes pre-migration snapshots into the GoL2 contract during 
        /// whitelist minting.
        /// @dev The GoL2 contract will need to have this contract's address set as 
        /// a snapshotter for this function to succeed.
        fn handle_snapshot(
            ref self: ContractState,
            generation: felt252,
            user_id: ContractAddress,
            game_state: felt252,
            timestamp: u64
        ) {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            assert(
                gol.add_snapshot(generation, user_id, game_state, timestamp),
                'GoL2NFT: Snapshot save failed'
            );
        }
    }
}
