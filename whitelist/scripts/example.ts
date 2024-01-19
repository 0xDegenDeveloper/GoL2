import { doScript } from "./core";

/**
 * We used a bunch of these scripts running in parallel to fetch the proofs for every
 * snapshot of the official whitelist.
 *
 * @dev Just if you were curious, we did this by running 3 batches back to back to back.
 * Each batch was 8 scripts running in parallel, each fetching 25,000 leaf's proofs.
 * It took ~2.5 hours to finish (m1 pro chip, 16gb ram, 8 core cpu, 14 core gpu).
 */
doScript(2, 25000);
