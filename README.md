# web3_webview
The project supported send and receive messages between Dapp and in-app webview “Only EIP-1193 standard supported”

# Requirements
* Flutter 3.24.0 or higher

# Installation
* Add this to your package's pubspec.yaml file:
```web3_webview: ^latest```

## Usage

```dart
import 'package:web3_webview/web3_webview.dart';

/// By default config
final _defaultNetwork = NetworkConfig(
  chainId: '0x1',
  chainName: 'Ethereum Mainnet',
  nativeCurrency: NativeCurrency(
    name: 'Ethereum',
    symbol: 'ETH',
    decimals: 18,
  ),
  rpcUrls: ['https://mainnet.infura.io/v3/'],
  blockExplorerUrls: ['https://etherscan.io'],
);

Web3WebView(
  customIconWalletBase64: 'data:image/png;base64,... /// Your icon wallet base64',
  customWalletName: 'Your wallet name',
  customIdWallet: 'com.your.wallet',
  customDialogWalletTheme: WalletDialogTheme(), // Custom your dialog wallet theme
  currentNetwork: _defaultNetwork, // Default network
  supportNetworks: [_defaultNetwork], // Support network
  privateKeyWallet: '0x...', // Your private key
  walletAddress: walletAddress,
  initialUrlRequest: URLRequest(
      url: WebUri(
      'https://position.exchange', // Replace your dapp domain
      ),
  ),
);
```

- `eip1193`: type function support.
  - requestAccounts: Pass when web app connect wallet
  - signTransaction: Pass when web app approve contract or send transaction
  - signMessage: Pass when web app sign a message
  - signPersonalMessage: Pass when web app sign a personal message
  - signTypedMessage: Pass when web app sign a type message
  - addEthereumChain: Pass when web app add a new chain
  - switchEthereumChain: Pass when web app switch chain
  
# Thanks for: 
* https://github.com/PositionExchange/flutter-web3-provider
* https://docs.ethers.org/v6/