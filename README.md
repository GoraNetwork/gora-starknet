# Example contract for Starknet

This project is an example of an ApiConnector contract for Starknet that allows querying data from external APIs and receiving results through an oracle.

- [Dependencies installation](#dependencies-installation)
- [Contract Creation](#contract-creation)
- [Configuration](#configuration)
- [Deployment](#deployment)
  - [Create an account](#create-an-account)
  - [Deploy the contract on the Starknet network](#deploy-the-contract-on-the-starknet-network)

## Addresses

| Contract | Address                                                            |
| -------- | ------------------------------------------------------------------ |
| Oracle   | 0x06061cee76f6e94191c848b9976c2460cbedc62e6a0a1cce037819b1e97810fb |

#### Example of Oracle-interacting contracts:

| Contract       | Address                                                            |
| -------------- | ------------------------------------------------------------------ |
| Score Consumer | 0x024ea726628b301edc0ffdc456b1e8ed96b53b2c73ff10b4580cb178c3e575f8 |
| Api connector  | 0x6a80cf1101fe1c5697669d8f4b2327b589bca35785da70988c0382f8e4ec322  |

## Dependencies installation

Before you begin, make sure you have the following installed:

- [Scarb v2.6.4](https://docs.swmansion.com/scarb/download.html)
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html)

## Contract Creation

1. Create a new project using Scarb:

   ```
   scarb new api_connector
   cd api_connector
   ```

2. Replace the contents of the `src/lib.cairo` file with the code from `contract.cairo`.

3. Add to `Scarb.toml`:

```
[dependencies]
sncast_std = { git = "https://github.com/foundry-rs/starknet-foundry", tag = "v0.30.0" }
starknet = "2.6.3"

[[target.starknet-contract]]
sierra = true
```

## Configuration

If you want to change the API request parameters to your own, you can do this in the `requestData` method. The array structure should be as follows:

1. The first elements - the complete URL for the GET request (without parameters)
2. Subsequent elements - pairs of "key:" and "value" for query parameters

Example:

```
let requestparams: Array<felt252> = array![
'https://api.example.com/data'.into(),
'key1:'.into(), 'value1'.into(),
'key2:'.into(), 'value2'.into()
];
```

###### Note: URL elements should not end with a `:`. If necessary, the URL can be split into multiple array elements.

###### Keys should end with a `:`.

## Deployment

### Create an account

Before deploying the contract, you need to create an account and get url for rpc:

1. Create an account using Braavos wallet:

   - Visit [Braavos](https://braavos.app/) and follow the instructions to create a new account.

   - Deploy your account. Simple variant - send some ETH tokens to another account.

2. Get rpc url. For example you can use [Alchemy](https://www.alchemy.com/).

3. Create an account in starknet-foundry.

```
sncast account add --url <rpc url> -n <account name> -a <address> --private-key <private key> --public-key <public key> --type <possible values: braavos, oz, argent,>
```

###### Note: You can find your account in `~/.starknet_accounts/starknet_open_zeppelin_accounts.json`

### Deploy the contract on the Starknet network

1. Build the contract

```
scarb build
```

2. Declare the contract

```
sncast --account <account name> declare --url <rpc url> --contract-name <contract name> --version v2
```

###### Note: If you get an error about the class being already declared, you can take the class hash from the error message and deploy the contract with the same class hash.

3. To deploy the contract, copy the class hash from the previous step.

```
sncast --account <account name> deploy --url <rpc url> --class-hash <class hash> --constructor-calldata 2724677851781709329171264455584760824081747553904876517112336346128798191867 --version v1
```

###### The constructor takes 1 parameter - the oracle address.

## Notes

- This contract is an example and may require additional configuration and optimization for production use.
