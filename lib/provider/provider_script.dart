// lib/ethereum/provider/provider_script.dart
import 'dart:convert';
import '../models/models.dart';

class ProviderScriptGenerator {
  static String generate({
    required String chainId,
    required List<String> accounts,
    required bool isConnected,
    required EIP6963ProviderInfo providerInfo,
  }) {
    return '''
    (function() {
      class EthereumProvider extends EventTarget {
        constructor() {
          super();
          this._isConnected = ${isConnected};
          this._chainId = '${chainId}';
          this._accounts = ${jsonEncode(accounts)};
          this._initialized = false;
          
          // Standard properties
          this.isMetaMask = true;
          this.isWallet = true;
          this._networkVersion = parseInt(this._chainId, 16).toString();
          
          // Initialize
          this._initialize();
        }

        async _initialize() {
          try {
            this._initialized = true;
            
            if (this._isConnected) {
              this._emit('connect', { chainId: this._chainId });
              if (this._accounts.length > 0) {
                this._emit('accountsChanged', this._accounts);
              }
            }
          } catch (error) {
            console.error('Failed to initialize provider:', error);
          }
        }

        async request(args) {
          if (!args || typeof args !== 'object' || !args.method) {
            throw new Error('Invalid request args');
          }

          const { method, params = [] } = args;

          if (params && !Array.isArray(params)) {
            throw new Error('Invalid params');
          }

          try {
            const result = await window.flutter_inappwebview.callHandler(
              'ethereumRequest',
              {
                method,
                params,
                chainId: this._chainId
              }
            );

            if (method === 'eth_requestAccounts') {
              this._handleAccountsChanged(result);
            }

            return result;
          } catch (error) {
            throw this._processError(error);
          }
        }

        on(eventName, listener) {
          this.addEventListener(eventName, (event) => {
            listener(event.detail);
          });
        }

        once(eventName, listener) {
          const handler = (event) => {
            this.removeEventListener(eventName, handler);
            listener(event.detail);
          };
          this.addEventListener(eventName, handler);
        }

        removeListener(eventName, listener) {
          this.removeEventListener(eventName, listener);
        }

        _emit(eventName, data) {
          const event = new CustomEvent(eventName, { detail: data });
          this.dispatchEvent(event);
        }

        _handleAccountsChanged(accounts) {
          if (Array.isArray(accounts)) {
            const changed = !this._arrayEquals(this._accounts, accounts);
            if (changed) {
              this._accounts = accounts;
              this._emit('accountsChanged', accounts);
            }
          }
        }

        async _handleChainChanged(chainId) {
          if (this._chainId !== chainId) {
            this._chainId = chainId;
            this._networkVersion = parseInt(chainId, 16).toString();
            this._emit('chainChanged', chainId);
          }
        }

        _arrayEquals(a, b) {
          return Array.isArray(a) && Array.isArray(b) &&
                 a.length === b.length &&
                 a.every((val, index) => val === b[index]);
        }

        _processError(error) {
          if (typeof error === 'string') {
            return new Error(error);
          }
          return error;
        }

        isConnected() {
          return this._isConnected;
        }

        enable() {
          console.warn('ethereum.enable() is deprecated, use ethereum.request({method: "eth_requestAccounts"}) instead.');
          return this.request({ method: 'eth_requestAccounts' });
        }

        get selectedAddress() {
          return this._accounts[0] || null;
        }

        get chainId() {
          return this._chainId;
        }

        get networkVersion() {
          return this._networkVersion;
        }
      }

      if (typeof window.ethereum === 'undefined') {
        const provider = new EthereumProvider();
        window.ethereum = provider;

        if (typeof window.web3 === 'undefined') {
          window.web3 = {
            currentProvider: provider
          };
        }
        
        const walletInfo = {
            uuid: "${providerInfo.uuid}",
            name: "${providerInfo.name}",
            icon: "${providerInfo.icon}",
            rdns: "${providerInfo.rdns}",
        };
        
        const announcement = {
            info: walletInfo,
            provider: provider
        };

        window.addEventListener('eip6963:requestProvider', (event) => {
            window.dispatchEvent(new CustomEvent('eip6963:announceProvider', {
                detail: announcement
            }));
        });
        
        console.log('EIP-6963 wallet provider injected');
      }
    })();
    ''';
  }
}
