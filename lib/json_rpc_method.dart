enum JsonRpcMethod {
  ETH_REQUEST_ACCOUNTS('eth_requestaccounts'),
  ETH_ACCOUNTS('eth_accounts'),
  ETH_BLOCK_NUMBER('eth_blocknumber'),
  ETH_CALL('eth_call'),
  ETH_CHAIN_ID('eth_chainid'),
  ETH_COINBASE('eth_coinbase'),
  ETH_ESTIMATE_GAS('eth_estimategas'),
  ETH_FEE_HISTORY('eth_feehistory'),
  ETH_GAS_PRICE('eth_gasprice'),
  ETH_GET_BALANCE('eth_getbalance'),
  ETH_GET_BLOCK_BY_HASH('eth_getblockbyhash'),
  ETH_GET_BLOCK_BY_NUMBER('eth_getblockbynumber'),
  ETH_GET_CODE('eth_getcode'),
  ETH_GET_FILTER_CHANGES('eth_getfilterchanges'),
  ETH_GET_FILTER_LOGS('eth_getfilterlogs'),
  ETH_GET_LOGS('eth_getlogs'),
  ETH_GET_PROOF('eth_getproof'),
  ETH_GET_STORAGE_AT('eth_getstorageat'),
  ETH_GET_TRANSACTION_BY_BLOCK_HASH_AND_INDEX(
      'eth_gettransactionbyblockhashandindex'),
  ETH_GET_TRANSACTION_BY_BLOCK_NUMBER_AND_INDEX(
      'eth_gettransactionbyblocknumberandindex'),
  ETH_GET_TRANSACTION_BY_HASH('eth_gettransactionbyhash'),
  ETH_GET_TRANSACTION_COUNT('eth_gettransactioncount'),
  ETH_GET_TRANSACTION_RECEIPT('eth_gettransactionreceipt'),
  ETH_GET_UNCLE_BY_BLOCK_HASH_AND_INDEX('eth_getunclebyblockhashandindex'),
  ETH_GET_UNCLE_BY_BLOCK_NUMBER_AND_INDEX('eth_getunclebyblocknumberandindex'),
  ETH_GET_UNCLE_COUNT_BY_BLOCK_HASH('eth_getunclecountbyblockhash'),
  ETH_GET_UNCLE_COUNT_BY_BLOCK_NUMBER('eth_getunclecountbyblocknumber'),
  ETH_GET_WORK('eth_getwork'),
  ETH_HASHRATE('eth_hashrate'),
  ETH_MINING('eth_mining'),
  ETH_NEW_BLOCK_FILTER('eth_newblockfilter'),
  ETH_NEW_FILTER('eth_newfilter'),
  ETH_NEW_PENDING_TRANSACTION_FILTER('eth_newpendingtransactionfilter'),
  ETH_PROTOCOL_VERSION('eth_protocolversion'),
  ETH_SEND_RAW_TRANSACTION('eth_sendrawtransaction'),
  ETH_SEND_TRANSACTION('eth_sendtransaction'),
  ETH_SIGN('eth_sign'),
  ETH_SIGN_TRANSACTION('eth_signtransaction'),
  ETH_SUBMIT_HASHRATE('eth_submithashrate'),
  ETH_SUBMIT_WORK('eth_submitwork'),
  ETH_SYNCING('eth_syncing'),
  ETH_UNINSTALL_FILTER('eth_uninstallfilter'),

  // Personal API
  PERSONAL_SIGN('personal_sign'),
  PERSONAL_EC_RECOVER('personal_ecrecover'),
  PERSONAL_IMPORT_RAW_KEY('personal_importrawkey'),
  PERSONAL_LIST_ACCOUNTS('personal_listaccounts'),
  PERSONAL_LOCK_ACCOUNT('personal_lockaccount'),
  PERSONAL_NEW_ACCOUNT('personal_newaccount'),
  PERSONAL_UNLOCK_ACCOUNT('personal_unlockaccount'),
  PERSONAL_SEND_TRANSACTION('personal_sendtransaction'),
  PERSONAL_SIGN_TRANSACTION('personal_signtransaction'),

  // Typed Data Signing (EIP-712)
  ETH_SIGN_TYPED_DATA('eth_signtypeddata'),
  ETH_SIGN_TYPED_DATA_V1('eth_signtypeddata_v1'),
  ETH_SIGN_TYPED_DATA_V3('eth_signtypeddata_v3'),
  ETH_SIGN_TYPED_DATA_V4('eth_signtypeddata_v4'),

  // Wallet Methods
  WALLET_ADD_ETHEREUM_CHAIN('wallet_addethereumchain'),
  WALLET_SWITCH_ETHEREUM_CHAIN('wallet_switchethereumchain'),
  WALLET_REQUEST_PERMISSIONS('wallet_requestpermissions'),
  WALLET_GET_PERMISSIONS('wallet_getpermissions'),
  WALLET_WATCH_ASSET('wallet_watchasset'),
  WALLET_REVOKE_PERMISSIONS('wallet_revokepermissions'),

  // Net Methods
  NET_VERSION('net_version'),
  NET_LISTENING('net_listening'),
  NET_PEER_COUNT('net_peercount'),

  // Web3 Methods
  WEB3_CLIENT_VERSION('web3_clientversion'),
  WEB3_SHA3('web3_sha3');

  final String value;
  const JsonRpcMethod(this.value);

  static JsonRpcMethod fromString(String? method) {
    if (method == null) {
      throw Exception('Method cannot be null');
    }

    return JsonRpcMethod.values.firstWhere(
      (e) => e.value.toLowerCase() == method.toLowerCase(),
      orElse: () => throw Exception('Unknown JSON-RPC method: $method'),
    );
  }
}
