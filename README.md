# Example contract for Starknet

This project is an example of an ApiConnector contract for Starknet that allows querying data from external APIs and receiving results through an oracle.

## Dependencies installation

Before you begin, make sure you have the following installed:

- [Scarb v2.6.4](https://docs.swmansion.com/scarb/download.html)
- [Starknet Foundry v0.21.0](https://foundry-rs.github.io/starknet-foundry/getting-started/installation.html)

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
sncast_std = { git = "https://github.com/foundry-rs/starknet-foundry", tag = "v0.21.0" }
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

## Usage

##### Deploy the contract on the Starknet network.

1. Build the contract

```
scarb build
```

### Create an account and obtain test tokens

Before deploying the contract, you need to create an account and get url for rpc:

1. Create an account using Braavos wallet:

   - Visit [Braavos](https://braavos.app/) and follow the instructions to create a new account.

2. Obtain test ETH tokens:

   - Go to [Starknet Goerli Faucet](https://faucet.goerli.starknet.io/) to receive test ETH tokens for your account.

3. Get rpc url. For example you can use [Alchemy](https://www.alchemy.com/).

4. Create an account in starknet-foundry.

```
sncast --url <rpc url> account add -n <account name>  -a <address> --private-key <private key> --public-key <public key>
```

###### Note: You can find your account in `~/.starknet_accounts/starknet_open_zeppelin_accounts.json`

### Deploy the contract on the Starknet network

2. Declare the contract

```
sncast --url <rpc url> --account <account name> declare --contract-name <contract name>
```

###### Note: If you have problems with declaring, you can add version to your declare command.

```
sncast --url <rpc url> --account <account name> declare --contract-name <contract name> --version <version>
```

3. To deploy the contract, copy the class hash from the previous step.

```
sncast --url <rpc url> --account <account name> deploy --class-hash <class hash> --constructor-calldata 2205249715583413338377019548642867583009021157045587175888304002146507151129 --unique
```

###### The constructor takes 1 parameter - the oracle address.

## Notes

- This contract is an example and may require additional configuration and optimization for production use.
