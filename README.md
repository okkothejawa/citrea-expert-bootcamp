## 1. Better Privacy on Bitcoin
### Prerequisites
- MetaMask
- Foundry
- Node.js
- npm
- yarn
- nvm
- Rust
- circom
- snarkjs

Recommended installation:

```
# To install MetaMask consult: `https://metamask.io/en-GB/download`

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Install Node.js
nvm install 16


# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install circom
cd ..
git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
cd ..

# Install snarkjs
npm install -g snarkjs@latest
```

### Steps
1. Clone Tornado Cash Rebuilt repository.
```
cd ..
git clone https://github.com/ekrembal/tornado-cash-rebuilt.git
```

2. Consult this repository's README to deploy Tornado Cash on Citrea.

3. Get testnet cBTC from `https://citrea.xyz/faucet`. Alternatively, you can use [Garden Finance](https://testnet.garden.finance/) if you have testnet4 BTC and want to have a more authentic experience. Choose `Citrea Bitcoin` as token to receive.

4. Clone Tornado Cash UI repository, or visit `https://citrea-testnet-tornado-cash.netlify.app/` for an already deployed version:
```
git clone https://github.com/ekrembal/classic-ui.git
```

5. If you did your own deployment, optionally change `networkConfig.js`'s `5115` part with your own `instanceAddress`, `deployedBlockNumber`, `NOTE_ACCOUNT_BLOCK` and `ENCRYPTED_NOTES_BLOCK`. You can use deployment block number from your deployment output for all three mentioned block numbers.

6. Update `withdraw.wasm` and `withdraw_final.zkey` with your versions from `tornado-cash-rebuilt`.

7. Run the UI on `http://localhost:3000`:
```
cd classic-ui
nvm use
yarn install
yarn generate
yarn dev
```

## 2. Benefiting Miner Economy
### Prerequisites
- Foundry

Recommended installation:

```
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Steps
1. Read through `BitcoinMinerIncentives.sol`.
2. Run tests:
```
forge test
```