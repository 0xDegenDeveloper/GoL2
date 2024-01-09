mod utils {
    mod life_rules;
    mod packing;
    mod whitelist;
}

mod contracts {
    mod setup;
    mod gol {
        mod gol_gas;
        mod gol_internal;
        mod gol_ownable;
        mod gol_upgradeable;
        mod gol;
    }

    mod nft {
        mod nft_gas;
        mod nft_ownable;
        mod nft_upgradeable;
        mod nft_uri_and_svg;
        mod nft;
    }
}

mod forking {
    mod mainnet;
}

