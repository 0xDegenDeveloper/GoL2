use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IGoLNFT<TContractState> {
    /// Read 
    fn get_whitelist_root(self: @TContractState) -> felt252;
    /// Write 
    fn set_whitelist_root(ref self: TContractState, root: felt252);
    fn whitelist_mint(
        ref self: TContractState, generation: felt252, proof: Array<felt252>, root: felt252
    );
    fn mint(ref self: TContractState, generation: felt252);
    fn withdraw(
        ref self: TContractState, token_addr: ContractAddress, amount: u256, to: ContractAddress
    );
// batch mints ? 
}


#[starknet::contract]
mod GoL2NFT {
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, ClassHash,
        replace_class_syscall, contract_address_try_from_felt252
    };
    use openzeppelin::{
        access::ownable::OwnableComponent, introspection::src5::SRC5Component,
        upgrades::{UpgradeableComponent, interface::IUpgradeable},
        token::erc721::{ERC721Component, interface::IERC721Metadata},
        token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait, interface::IERC20},
    };
    use gol2::{
        utils::{
            life_rules::evaluate_rounds, packing::{pack_game, unpack_game, revive_cell},
            constants::{
                INFINITE_GAME_GENESIS, DIM, CREATE_CREDIT_REQUIREMENT, GIVE_LIFE_CREDIT_REQUIREMENT,
                INITIAL_ADMIN
            },
        },
        contracts::gol::{GoL2, IGoL2Dispatcher, IGoL2DispatcherTrait,}
    };

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
        owner: ContractAddress,
        name: felt252,
        symbol: felt252,
        whitelist_root: felt252
    ) {
        self.ownable.initializer(owner);
        self.erc721.initializer(name, symbol);
        self.whitelist_root.write(whitelist_root);
    }


    #[storage]
    struct Storage {
        /// GoL2 game address
        gol2_addr: ContractAddress,
        /// Mint price (wei)
        mint_price: u256,
        mint_token_addr: ContractAddress,
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
        WhitelistRootChanged: WhitelistRootChanged,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct WhitelistRootChanged {
        old_root: felt252,
        new_roow: felt252,
    }

    /// External Functions
    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[external(v0)]
    impl ERC721MetadataImpl of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.erc721.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc721.symbol()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 { //
            // todo: on chain metadata + svg images
            token_id.try_into().unwrap()
        }
    }

    #[external(v0)]
    impl GoL2NFTImpl of super::IGoLNFT<ContractState> {
        /// Read
        fn get_whitelist_root(self: @ContractState) -> felt252 {
            self.whitelist_root.read()
        }

        /// Write
        fn set_whitelist_root(ref self: ContractState, root: felt252) {
            self.ownable.assert_only_owner();
            self.whitelist_root.write(root);
        }

        fn mint(ref self: ContractState, generation: felt252) {
            /// verify caller is generation owner
            let caller = get_caller_address();
            let gol = IGoL2Dispatcher { contract_address: self.gol2_addr.read() };
            /// might need to pass snapshot state instead (depends on if duplicates or not)
            let creator = gol.get_snapshot_creator(generation);
            assert(caller == creator, 'Only snapshot creator can mint');
            /// pay for mint
            self.pay(caller);
            /// mint token
            self.erc721._safe_mint(caller, generation.into(), array![].span());
        }

        fn whitelist_mint(
            ref self: ContractState, generation: felt252, proof: Array<felt252>, root: felt252
        ) {
            let caller = get_caller_address();

            // verify that hash([caller, generation] + proof) is able to create the merkle root 

            /// pay for mint
            self.pay(caller);
            /// mint token
            self.erc721._safe_mint(caller, generation.into(), array![].span())
        }

        fn withdraw(
            ref self: ContractState, token_addr: ContractAddress, amount: u256, to: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            let token = ERC20ABIDispatcher { contract_address: token_addr };
            let success = token.transfer_from(starknet::get_contract_address(), to, amount);
            assert(success, 'ERC20 transfer failed');
        }
    }

    /// Internal Functions
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn pay(ref self: ContractState, user: ContractAddress) {
            let token = ERC20ABIDispatcher { contract_address: self.mint_token_addr.read() };
            let success = token
                .transfer_from(user, starknet::get_contract_address(), self.mint_price.read());
            assert(success, 'ERC20 transfer failed');
        }
    }
}

