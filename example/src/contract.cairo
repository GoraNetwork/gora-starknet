use core::result::{Result, ResultTrait};
use starknet::{ContractAddress};
use starknet::storage_access::{Store, StorageBaseAddress, storage_address_from_base_and_offset};
use starknet::{SyscallResult, SyscallResultTrait};

#[starknet::interface]
pub trait IDataConsumer<TContractState> {
    fn response(ref self: TContractState, result: Array<felt252>, ID: felt252);
}

#[starknet::interface]
pub trait IApiConnector<TContractState> {
    fn getResult(self: @TContractState, address: ContractAddress) -> Array<felt252>;
    fn requestData(ref self: TContractState);
}

#[starknet::interface]
pub trait IOracle<TContractState> {
    fn request(
        ref self: TContractState, externalReqID: felt252, srcParam: Array<felt252>, deadline: u64
    );
    fn fullfill(ref self: TContractState, reqID: felt252, result: Array<felt252>);
}

pub impl StoreFelt252Array of Store<Array<felt252>> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Array<felt252>> {
        StoreFelt252Array::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Array<felt252>
    ) -> SyscallResult<()> {
        StoreFelt252Array::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8
    ) -> SyscallResult<Array<felt252>> {
        let mut arr: Array<felt252> = array![];

        // Read the stored array's length. If the length is greater than 255, the read will fail.
        let len: u8 = Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = Store::<felt252>::read_at_offset(address_domain, base, offset).unwrap();
            arr.append(value);
            offset += Store::<felt252>::size();
        };

        // Return the array.
        Result::Ok(arr)
    }

    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8, mut value: Array<felt252>
    ) -> SyscallResult<()> {
        // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        Store::<u8>::write_at_offset(address_domain, base, offset, len).unwrap();
        offset += 1;

        // Store the array elements sequentially
        while let Option::Some(element) = value
            .pop_front() {
                Store::<felt252>::write_at_offset(address_domain, base, offset, element).unwrap();
                offset += Store::<felt252>::size();
            };

        Result::Ok(())
    }

    fn size() -> u8 {
        255 * Store::<felt252>::size()
    }
}

#[starknet::contract]
pub mod ApiConnector {
    use starknet::{ContractAddress, get_caller_address, get_block_number, get_block_timestamp,};
    use super::StoreFelt252Array;
    use super::{IDataConsumer, IOracleDispatcher, IOracleDispatcherTrait, IApiConnector};
    use core::hash::{Hash, HashStateTrait, HashStateExTrait};
    use core::poseidon::{PoseidonTrait, poseidon_hash_span};

    #[storage]
    struct Storage {
        oracle: ContractAddress,
        reqId: LegacyMap<felt252, ContractAddress>,
        results: LegacyMap<ContractAddress, Array<felt252>>,
    }

    const DEADLINE: u64 = 600;

    #[constructor]
    fn constructor(ref self: ContractState, oracle: ContractAddress) {
        self.oracle.write(oracle);
    }

    #[derive(Drop)]
    pub struct HashInfo {
        pub user: ContractAddress,
        pub block: u64,
        pub arguments: Array<felt252>,
    }

    #[abi(embed_v0)]
    impl ApiConnector of IApiConnector<ContractState> {
        fn getResult(self: @ContractState, address: ContractAddress) -> Array<felt252> {
            return self.results.read(address);
        }

        fn requestData(ref self: ContractState) {
            let caller = get_caller_address();

            // request params
            let https: felt252 = 'https://'.into();
            let domain: felt252 = 'min-api.cryptocompare.com'.into();
            let path: felt252 = '/data/price'.into();
            let fsym: felt252 = 'fsym:'.into();
            let fsym_value: felt252 = 'ETH'.into();
            let tsym: felt252 = 'tsyms:'.into();
            let tsym_value: felt252 = 'USD'.into();

            let requestparams: Array<felt252> = array![
                https, domain, path, fsym, fsym_value, tsym, tsym_value
            ];

            let mut argsSpan = requestparams.span();

            let idtohash = HashInfo {
                user: caller, block: get_block_number(), arguments: requestparams
            };
            let mut reqid = PoseidonTrait::new()
                .update(idtohash.user.into())
                .update(idtohash.block.into())
                .update(poseidon_hash_span(idtohash.arguments.span()))
                .finalize();

            let reqtype: felt252 = 1;

            let mut srcparam: Array<felt252> = array![reqtype];
            let mut i: usize = 0;

            loop {
                if i == argsSpan.len() {
                    break;
                }
                srcparam.append(*argsSpan[i]);
                i += 1;
            };

            let oracleadd = self.oracle.read();
            let oracle = IOracleDispatcher { contract_address: oracleadd };

            let deadlinedata = get_block_timestamp() + DEADLINE;
            oracle.request(reqid, srcparam, deadlinedata);
            self.reqId.write(reqid, caller);
        }
    }
    #[abi(embed_v0)]
    impl DataConsumer of IDataConsumer<ContractState> {
        fn response(ref self: ContractState, result: Array<felt252>, ID: felt252) {
            assert(get_caller_address() == self.oracle.read(), 'Oracle contract call only');

            let user = self.reqId.read(ID);
            self.results.write(user, result);
        }
    }
}
