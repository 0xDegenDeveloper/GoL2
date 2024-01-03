mod utils {
    mod life_rules;
    mod packing;
}

mod contracts {
    mod setup;
    mod gol {
        mod gol;
        mod gol_internal;
        mod gol_ownable;
        mod gol_upgradeable;
        mod gol_gas;
    }

    mod nft {
        mod nft;
        mod nft_upgradeable;
        mod nft_ownable;
        mod uri_svg;
        mod nft_gas;
    }
}

mod forking {
    mod mainnet;
}

