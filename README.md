# Catain

Catain is an experiment in making transaction ordering fair.

Most blockchains decide order based on who gets there first. In practice, that means faster bots and better infrastructure win. Catain takes a different approach: it removes timing from the equation and replaces it with verifiable randomness.

---

## What it does

Instead of processing transactions as they arrive, Catain groups them into rounds.

Within each round:

* Everyone commits first
* Then reveals their input
* A shared random value is generated
* The final order is derived from that randomness

No one can predict or manipulate the final order ahead of time, and everyone in the same round is treated equally.

---

## Why this exists

This project started from a simple question:

What if transaction ordering wasn’t a race?

Current systems incentivize:

* speed
* infrastructure advantage
* MEV extraction

Catain explores a model where:

* timing doesn’t matter
* ordering is deterministic but unpredictable
* fairness is built into the system, not enforced externally

---

## How it works (high level)

1. Users submit commitments (hashed secrets)
2. Users reveal their secrets
3. A combined seed is generated
4. An off-chain sequencer computes results
5. Results are compressed into a Merkle root
6. Users claim their outcome with a proof

The heavy computation happens off-chain, but the results are still verifiable on-chain.

---

## What’s in this repo

* `contracts/`
  Core smart contracts (round logic, Merkle verification, claims)

* `scripts/`
  Sequencer and Merkle tree generation scripts

* `frontend/`
  Minimal interface for interacting with the system

* `test/`
  Foundry-based tests covering claim logic and edge cases

---

## Running it locally

Start a local chain:

```bash
anvil
```

Build contracts:

```bash
forge build
```

Run tests:

```bash
forge test
```

Start the sequencer:

```bash
node scripts/sequencer.js
```

Open the frontend:

```
frontend/index.html
```

Make sure MetaMask is connected to your local network.

---

## Current state

This is a working prototype.

* Core flow is implemented
* Commit–reveal works
* Merkle-based claims work
* Sequencer automation works

Things that are still missing or simplified:

* Sequencer is centralized
* No Sybil resistance
* No incentive mechanism
* No economic security model

---

## What’s interesting here

This isn’t trying to be faster than existing chains.

It’s trying to change what “ordering” means.

Instead of:

> whoever is first wins

It becomes:

> everyone in the same round has an equal chance

That shift has implications for:

* NFT mints
* airdrops
* on-chain games
* any system where ordering matters

---

## Next steps

* Decentralize the sequencer
* Improve randomness (VRF / VDF)
* Add incentive and slashing mechanisms
* Explore real-world use cases

---

## Contributing

If you’re interested in:

* protocol design
* MEV resistance
* randomness in distributed systems

feel free to open an issue or reach out.

---

Catain is still early, but the idea is simple:

ordering doesn’t have to be a race.
