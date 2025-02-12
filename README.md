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
Web3WebView(
    chainId: 56, // Replace your chain id network you want connect
    rpcUrl: 'https://bsc-dataseed.binance.org/', // Replace your rpc url network you want connect
    walletAddress: walletAddress,
    signCallback: (rawData, eip1193, controller) {
      // Handler callback when dapp interact with blockchain
      switch (eip1193) {
        case EIP1193.requestAccounts:
          controller?.setAddress(walletAddress, id);
          print('requestAccounts');
          break;
        case EIP1193.signTransaction:
          print('signTransaction');
          break;
        case EIP1193.signMessage:
          print('signMessage');
          break;
        case EIP1193.signPersonalMessage:
          print('signPersonalMessage');
          break;
        case EIP1193.signTypedMessage:
          print('addEthereumChain');
          break;
        case EIP1193.addEthereumChain:
          print('addEthereumChain');
          break;  
    },
    initialUrlRequest: URLRequest(
        url: WebUri(
        'https://position.exchange', // Replace your dapp domain
        ),
    ),
);
```

If you want use your provider script
you provide [customPathProvider] and [customWalletName]

`signCallback: (rawData, eip1193, controller)`: callback was called when dapp when interact with blockchain. <br/>
- `rawData`: data received.
- `eip1193`: type function support.
  - requestAccounts: Pass when web app connect wallet
  - signTransaction: Pass when web app approve contract or send transaction
  - signMessage: Pass when web app sign a message
  - signPersonalMessage: Pass when web app sign a personal message
  - signTypedMessage: Pass when web app sign a type message
  - addEthereumChain: Pass when web app add a new chain


When you pass data from dapp to your app
```
const args = {/* Pass data you want */};
if (window.flutter_inappwebview.callHandler) {
    window.flutter_inappwebview.callHandler('functionName', args)
        .then(function(result) {
          /// Receive data from your app
    });
}
```

And receive in your app
```
onWebViewCreated: (controller) {
    controller.addJavaScriptHandler(
        handlerName: 'functionName',
        callback: (args) {
          /// Receive data from dapp
          
          
          /// Send data to dapp;
          return /* anything */;
        },
    );
},
```
# Thanks for: 
* https://github.com/PositionExchange/flutter-web3-provider
* https://github.com/PositionExchange/js-web3-provider