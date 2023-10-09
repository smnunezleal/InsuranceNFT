# InsuranceNFT

InsuranceNFT is a decentralized application that allows users to purchase NFT-based insurance policies for their positions in a lending protocol. The insurance policies are represented as NFTs, and users can claim the insured amount if their position is liquidated.

## Features

- **Integration with Lending Protocols**: Fetch user positions from a lending protocol like AAVE or Compound.
- **Purchase Insurance**: Users can deposit USDC to purchase an NFT representing an insurance policy.
- **Claim Insurance**: Users can burn the NFT to claim the insured amount in USDC if their position is liquidated.
- **Governance**: The contract is governable, allowing for updates and management by a governance entity.
- **Oracle Integration**: Utilizes an oracle to determine the health of a position and whether a policy is claimable.

## Smart Contracts

- `InsuranceNFT`: Main contract that handles the purchase, claim, and management of insurance policies.
- `InsuranceOracle`: Oracle contract that determines whether a policy is claimable based on the health of the user's position.

## Setup and Installation

### Prerequisites

- [Rust](https://www.rust-lang.org/)
- [Foundry](https://book.getfoundry.sh/)

### Installation

1. **Clone the Repository**

   ```sh
   git clone https://github.com/[YourUsername]/InsuranceNFT.git
   cd InsuranceNFT

2. **Build Contracts**

   ```sh
   forge build

3. **Deploy Contracts**
Replace <your_rpc_url> and <your_private_key> with your actual RPC URL and private key.

   ```sh
   forge script script/InsuranceNFT.s.sol:InsuranceNFTScript --rpc-url <your_rpc_url> --private-key <your_private_key>

## Testing

Ensure to have a local Ethereum node like Anvil running.

```sh
   forge test

## Security
This project is in development. Use at your own risk. Always ensure to thoroughly test the smart contracts and have them audited before deploying them on the mainnet.

## Contributing
Contributions are welcome! Please read the contributing guidelines first.

## License
MIT

