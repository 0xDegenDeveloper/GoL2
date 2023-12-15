use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IGoL2NFT<TContractState> {
    /// Read
    fn total_supply(self: @TContractState) -> u256;
    fn mint_token_address(self: @TContractState) -> ContractAddress;
    fn mint_price(self: @TContractState) -> u256;
    fn board_state_to_token_id(self: @TContractState, board_state: felt252) -> u256;
    /// Write
    fn set_mint_price(ref self: TContractState, new_price: u256);
    fn set_mint_token_address(ref self: TContractState, new_addr: ContractAddress);
    // todo: batch/owner mints ? 
    fn mint(ref self: TContractState, generation: felt252);
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
        },
        contracts::gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait,}
    };
    use super::{IGoL2NFTDispatcher, IGoL2NFTDispatcherTrait};
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
    ) {
        self.ownable.initializer(_owner);
        self.erc721.initializer(_name, _symbol);
        self.gol2_addr.write(_gol2_addr);
        self.mint_token_addr.write(_mint_token_addr);
        self.mint_price.write(_mint_price);
    }


    #[storage]
    struct Storage {
        /// GoL2 game address
        gol2_addr: ContractAddress,
        /// Total # of NFTs minted
        total_supply: u256,
        /// Mint price (wei)
        mint_price: u256,
        mint_token_addr: ContractAddress,
        /// Map of gamestates -> token_ids
        board_state_to_token_id: LegacyMap<felt252, u256>,
        /// Merkle root for whitelist mints 
        whitelist_root: felt252,
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
            let board_state = gol.view_game(INFINITE_GAME_GENESIS, token_id.try_into().unwrap());
            let mut uri_path = make_uri_array(token_id, board_state, token_id.try_into().unwrap());
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
        /// Read
        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        /// Map of board_states -> token_ids (0 if not minted yet)
        fn board_state_to_token_id(self: @ContractState, board_state: felt252) -> u256 {
            self.board_state_to_token_id.read(board_state)
        }

        /// Mint token address
        fn mint_token_address(self: @ContractState) -> ContractAddress {
            self.mint_token_addr.read()
        }

        /// Price to mint 1 token (in wei)
        fn mint_price(self: @ContractState) -> u256 {
            self.mint_price.read()
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

        /// Write

        /// Empty function for interface definition for future upgrades to contract
        fn initializer(ref self: ContractState) {}


        /// Mint token to caller if the board_state at `generation` has not been minted yet.
        fn mint(ref self: ContractState, generation: felt252) {
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            /// Verify generation exists
            let generation_int: u256 = generation.into();
            let current_generation_int: u256 = gol
                .get_current_generation(INFINITE_GAME_GENESIS)
                .into();
            assert(
                (0 < generation_int) && (generation_int <= current_generation_int),
                'NFT: invalid generation'
            );
            /// Verify board state has not been minted yet
            let board_state = gol.view_game(INFINITE_GAME_GENESIS, generation);
            self.assert_unique_board_state(board_state);
            /// Charge caller for mint
            self.pay();
            /// Mint caller 1 token
            self.erc721._mint(get_caller_address(), generation_int);
            /// Update total supply
            self.total_supply.write(self.total_supply.read() + 1);
            /// Make board state non mintable again
            self.board_state_to_token_id.write(board_state, generation_int);
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
        /// Charge user to mint
        fn pay(ref self: ContractState) {
            let payment_token = ERC20ABIDispatcher {
                contract_address: self.mint_token_addr.read()
            };
            let success = payment_token
                .transfer_from(
                    get_caller_address(), starknet::get_contract_address(), self.mint_price.read()
                );
            assert(success, 'NFT: payment failed');
        }

        /// Has this board state been minted before ?
        fn assert_unique_board_state(ref self: ContractState, board_state: felt252) {
            assert(
                self.board_state_to_token_id.read(board_state) == 0,
                'NFT: board state already minted'
            );
        }
    }
}

