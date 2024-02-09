import { doScript } from "./core";

/**
 * We used a bunch of these scripts running in parallel to fetch the proofs for every
 * snapshot of the official whitelist.
 *
 * This was done to speed up the whitelist generation process.
 */
doScript(2, 25000);
