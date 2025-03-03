library web3_webview;

import 'dart:collection';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uuid/uuid.dart';

import 'json_rpc_method.dart';
import 'ethereum/ethereum_provider.dart';
import 'ethereum/wallet_dialog_service.dart';
import 'models/models.dart';

/// InAppWebViewEIP1193 wrap InAppWebView(https://pub.dev/packages/flutter_inappwebview)
/// and config communicate between web app and wallet via standard EIP-1193
class Web3WebView extends StatefulWidget {
  const Web3WebView({
    super.key,
    required this.web3WalletConfig,
    this.windowId,
    this.initialUrlRequest,
    this.initialFile,
    this.initialData,
    this.initialSettings,
    this.initialUserScripts,
    this.pullToRefreshController,
    this.contextMenu,
    this.onWebViewCreated,
    this.onLoadStart,
    this.onLoadStop,
    this.onReceivedError,
    this.onReceivedHttpError,
    this.onConsoleMessage,
    this.onProgressChanged,
    this.shouldOverrideUrlLoading,
    this.onLoadResource,
    this.onScrollChanged,
    this.onDownloadStartRequest,
    this.onLoadResourceWithCustomScheme,
    this.onCreateWindow,
    this.onCloseWindow,
    this.onJsAlert,
    this.onJsConfirm,
    this.onJsPrompt,
    this.onReceivedHttpAuthRequest,
    this.onReceivedServerTrustAuthRequest,
    this.onReceivedClientCertRequest,
    this.onFindResultReceived,
    this.shouldInterceptAjaxRequest,
    this.onAjaxReadyStateChange,
    this.onAjaxProgress,
    this.shouldInterceptFetchRequest,
    this.onUpdateVisitedHistory,
    this.onPrintRequest,
    this.onLongPressHitTestResult,
    this.onEnterFullscreen,
    this.onExitFullscreen,
    this.onPageCommitVisible,
    this.onTitleChanged,
    this.onWindowFocus,
    this.onWindowBlur,
    this.onOverScrolled,
    this.onZoomScaleChanged,
    this.onSafeBrowsingHit,
    this.onPermissionRequest,
    this.onGeolocationPermissionsShowPrompt,
    this.onGeolocationPermissionsHidePrompt,
    this.shouldInterceptRequest,
    this.onRenderProcessGone,
    this.onRenderProcessResponsive,
    this.onRenderProcessUnresponsive,
    this.onFormResubmission,
    this.onReceivedIcon,
    this.onReceivedTouchIconUrl,
    this.onJsBeforeUnload,
    this.onReceivedLoginRequest,
    this.onWebContentProcessDidTerminate,
    this.onDidReceiveServerRedirectForProvisionalNavigation,
    this.onNavigationResponse,
    this.shouldAllowDeprecatedTLS,
    this.gestureRecognizers,
  });

  final Web3WalletConfig? web3WalletConfig;

  //------------------------------------------------------------------------------
  /// `gestureRecognizers` specifies which gestures should be consumed by the WebView.
  /// It is possible for other gesture recognizers to be competing with the web view on pointer
  /// events, e.g if the web view is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The web view will claim gestures that are recognized by any of the
  /// recognizers on this list.
  /// When `gestureRecognizers` is empty or null, the web view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  ///The window id of a [CreateWindowAction.windowId].
  final int? windowId;

  ///Event fired when the [WebView] is created.
  final void Function(InAppWebViewController controller)? onWebViewCreated;

  ///Event fired when the [WebView] starts to load an [url].
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView ([Official API - WebViewClient.onPageStarted](https://developer.android.com/reference/android/webkit/WebViewClient#onPageStarted(android.webkit.WebView,%20java.lang.String,%20android.graphics.Bitmap)))
  ///- iOS ([Official API - WKNavigationDelegate.webView](https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455621-webview))
  final void Function(InAppWebViewController controller, Uri? url)? onLoadStart;

  ///Event fired when the [WebView] finishes loading an [url].
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView ([Official API - WebViewClient.onPageFinished](https://developer.android.com/reference/android/webkit/WebViewClient#onPageFinished(android.webkit.WebView,%20java.lang.String)))
  ///- iOS ([Official API - WKNavigationDelegate.webView](https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455629-webview))
  final void Function(InAppWebViewController controller, Uri? url)? onLoadStop;

  ///Event fired when the [WebView] encounters an error loading an [url].
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onReceivedError(android.webkit.WebView,%20int,%20java.lang.String,%20java.lang.String)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455623-webview
  final void Function(InAppWebViewController controller,
      WebResourceRequest request, WebResourceError error)? onReceivedError;

  ///Event fired when the [WebView] main page receives an HTTP error.
  ///
  ///[url] represents the url of the main page that received the HTTP error.
  ///
  ///[statusCode] represents the status code of the response. HTTP errors have status codes >= 400.
  ///
  ///[description] represents the description of the HTTP error. On iOS, it is always an empty string.
  ///
  ///**NOTE**: available on Android 23+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onReceivedHttpError(android.webkit.WebView,%20android.webkit.WebResourceRequest,%20android.webkit.WebResourceResponse)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455643-webview
  final void Function(
      InAppWebViewController controller,
      WebResourceRequest request,
      WebResourceResponse response)? onReceivedHttpError;

  ///Event fired when the current [progress] of loading a page is changed.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView ([Official API - WebChromeClient.onProgressChanged](https://developer.android.com/reference/android/webkit/WebChromeClient#onProgressChanged(android.webkit.WebView,%20int)))
  ///- iOS
  final void Function(InAppWebViewController controller, int progress)?
      onProgressChanged;

  ///Event fired when the [WebView] receives a [ConsoleMessage].
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onConsoleMessage(android.webkit.ConsoleMessage)
  final void Function(
          InAppWebViewController controller, ConsoleMessage consoleMessage)?
      onConsoleMessage;

  ///Give the host application a chance to take control when a URL is about to be loaded in the current WebView. This event is not called on the initial load of the WebView.
  ///
  ///Note that on Android there isn't any way to load an URL for a frame that is not the main frame, so if the request is not for the main frame, the navigation is allowed by default.
  ///However, if you want to cancel requests for subframes, you can use the [AndroidInAppWebViewSettings.regexToCancelSubFramesLoading] option
  ///to write a Regular Expression that, if the url request of a subframe matches, then the request of that subframe is canceled.
  ///
  ///Also, on Android, this method is not called for POST requests.
  ///
  ///[navigationAction] represents an object that contains information about an action that causes navigation to occur.
  ///
  ///**NOTE**: In order to be able to listen this event, you need to set [InAppWebViewSettings.useShouldOverrideUrlLoading] option to `true`.
  ///Also, on Android this event is not called on the first page load.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#shouldOverrideUrlLoading(android.webkit.WebView,%20java.lang.String)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455641-webview
  final Future<NavigationActionPolicy?> Function(
          InAppWebViewController controller, NavigationAction navigationAction)?
      shouldOverrideUrlLoading;

  ///Event fired when the [WebView] loads a resource.
  ///
  ///**NOTE**: In order to be able to listen this event, you need to set [InAppWebViewSettings.useOnLoadResource] and [InAppWebViewSettings.javaScriptEnabled] options to `true`.
  final void Function(
          InAppWebViewController controller, LoadedResource resource)?
      onLoadResource;

  ///Event fired when the [WebView] scrolls.
  ///
  ///[x] represents the current horizontal scroll origin in pixels.
  ///
  ///[y] represents the current vertical scroll origin in pixels.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#onScrollChanged(int,%20int,%20int,%20int)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollviewdelegate/1619392-scrollviewdidscroll
  final void Function(InAppWebViewController controller, int x, int y)?
      onScrollChanged;

  ///Event fired when [WebView] recognizes a downloadable file.
  ///To download the file, you can use the [flutter_downloader](https://pub.dev/packages/flutter_downloader) plugin.
  ///
  ///[downloadStartRequest] represents the request of the file to download.
  ///
  ///**NOTE**: In order to be able to listen this event, you need to set [InAppWebViewSettings.useOnDownloadStart] option to `true`.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#setDownloadListener(android.webkit.DownloadListener)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455643-webview
  final void Function(InAppWebViewController controller,
      DownloadStartRequest downloadStartRequest)? onDownloadStartRequest;

  ///Event fired when the [WebView] finds the `custom-scheme` while loading a resource. Here you can handle the url request and return a [CustomSchemeResponse] to load a specific resource encoded to `base64`.
  ///
  ///[url] represents the url of the request.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkurlschemehandler
  final Future<CustomSchemeResponse?> Function(
      InAppWebViewController controller,
      WebResourceRequest webResourceRequest)? onLoadResourceWithCustomScheme;

  ///Event fired when the [WebView] requests the host application to create a new window,
  ///for example when trying to open a link with `target="_blank"` or when `window.open()` is called by JavaScript side.
  ///If the host application chooses to honor this request, it should return `true` from this method, create a new WebView to host the window.
  ///If the host application chooses not to honor the request, it should return `false` from this method.
  ///The default implementation of this method does nothing and hence returns `false`.
  ///
  ///- [createWindowAction] represents the request.
  ///
  ///**NOTE**: to allow JavaScript to open windows, you need to set [InAppWebViewSettings.javaScriptCanOpenWindowsAutomatically] option to `true`.
  ///
  ///**NOTE**: on Android you need to set [AndroidInAppWebViewSettings.supportMultipleWindows] option to `true`.
  ///Also, if the request has been created using JavaScript (`window.open()`), then there are some limitation: check the [NavigationAction] class.
  ///
  ///**NOTE**: on iOS, setting these initial options: [InAppWebViewSettings.supportZoom], [InAppWebViewSettings.useOnLoadResource], [InAppWebViewSettings.useShouldInterceptAjaxRequest],
  ///[InAppWebViewSettings.useShouldInterceptFetchRequest], [InAppWebViewSettings.applicationNameForUserAgent], [InAppWebViewSettings.javaScriptCanOpenWindowsAutomatically],
  ///[InAppWebViewSettings.javaScriptEnabled], [InAppWebViewSettings.minimumFontSize], [InAppWebViewSettings.preferredContentMode], [InAppWebViewSettings.incognito],
  ///[InAppWebViewSettings.cacheEnabled], [InAppWebViewSettings.mediaPlaybackRequiresUserGesture],
  ///[InAppWebViewSettings.resourceCustomSchemes], [IOSInAppWebViewSettings.sharedCookiesEnabled],
  ///[IOSInAppWebViewSettings.enableViewportScale], [IOSInAppWebViewSettings.allowsAirPlayForMediaPlayback],
  ///[IOSInAppWebViewSettings.allowsPictureInPictureMediaPlayback], [IOSInAppWebViewSettings.isFraudulentWebsiteWarningEnabled],
  ///[IOSInAppWebViewSettings.allowsInlineMediaPlayback], [IOSInAppWebViewSettings.suppressesIncrementalRendering], [IOSInAppWebViewSettings.selectionGranularity],
  ///[IOSInAppWebViewSettings.ignoresViewportScaleLimits], [IOSInAppWebViewSettings.limitsNavigationsToAppBoundDomains],
  ///will have no effect due to a `WKWebView` limitation when creating the new window WebView: it's impossible to return the new `WKWebView`
  ///with a different `WKWebViewConfiguration` instance (see https://developer.apple.com/documentation/webkit/wkuidelegate/1536907-webview).
  ///So, these options will be inherited from the caller WebView.
  ///Also, note that calling [InAppWebViewController.setSettings] method using the controller of the new created WebView,
  ///it will update also the WebView options of the caller WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onCreateWindow(android.webkit.WebView,%20boolean,%20boolean,%20android.os.Message)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkuidelegate/1536907-webview
  final Future<bool?> Function(InAppWebViewController controller,
      CreateWindowAction createWindowAction)? onCreateWindow;

  ///Event fired when the host application should close the given WebView and remove it from the view system if necessary.
  ///At this point, WebCore has stopped any loading in this window and has removed any cross-scripting ability in javascript.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onCloseWindow(android.webkit.WebView)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkuidelegate/1537390-webviewdidclose
  final void Function(InAppWebViewController controller)? onCloseWindow;

  ///Event fired when the JavaScript `window` object of the WebView has received focus.
  ///This is the result of the `focus` JavaScript event applied to the `window` object.
  final void Function(InAppWebViewController controller)? onWindowFocus;

  ///Event fired when the JavaScript `window` object of the WebView has lost focus.
  ///This is the result of the `blur` JavaScript event applied to the `window` object.
  final void Function(InAppWebViewController controller)? onWindowBlur;

  ///Event fired when javascript calls the `alert()` method to display an alert dialog.
  ///If [JsAlertResponse.handledByClient] is `true`, the webview will assume that the client will handle the dialog.
  ///
  ///[jsAlertRequest] contains the message to be displayed in the alert dialog and the of the page requesting the dialog.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onJsAlert(android.webkit.WebView,%20java.lang.String,%20java.lang.String,%20android.webkit.JsResult)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkuidelegate/1537406-webview
  final Future<JsAlertResponse?> Function(
          InAppWebViewController controller, JsAlertRequest jsAlertRequest)?
      onJsAlert;

  ///Event fired when javascript calls the `confirm()` method to display a confirm dialog.
  ///If [JsConfirmResponse.handledByClient] is `true`, the webview will assume that the client will handle the dialog.
  ///
  ///[jsConfirmRequest] contains the message to be displayed in the confirm dialog and the of the page requesting the dialog.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onJsConfirm(android.webkit.WebView,%20java.lang.String,%20java.lang.String,%20android.webkit.JsResult)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkuidelegate/1536489-webview
  final Future<JsConfirmResponse?> Function(
          InAppWebViewController controller, JsConfirmRequest jsConfirmRequest)?
      onJsConfirm;

  ///Event fired when javascript calls the `prompt()` method to display a prompt dialog.
  ///If [JsPromptResponse.handledByClient] is `true`, the webview will assume that the client will handle the dialog.
  ///
  ///[jsPromptRequest] contains the message to be displayed in the prompt dialog, the default value displayed in the prompt dialog, and the of the page requesting the dialog.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onJsPrompt(android.webkit.WebView,%20java.lang.String,%20java.lang.String,%20java.lang.String,%20android.webkit.JsPromptResult)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkuidelegate/1538086-webview
  final Future<JsPromptResponse?> Function(
          InAppWebViewController controller, JsPromptRequest jsPromptRequest)?
      onJsPrompt;

  ///Event fired when the WebView received an HTTP authentication request. The default behavior is to cancel the request.
  ///
  ///[challenge] contains data about host, port, protocol, realm, etc. as specified in the [URLAuthenticationChallenge].
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onReceivedHttpAuthRequest(android.webkit.WebView,%20android.webkit.HttpAuthHandler,%20java.lang.String,%20java.lang.String)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455638-webview
  final Future<HttpAuthResponse?> Function(InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? onReceivedHttpAuthRequest;

  ///Event fired when the WebView need to perform server trust authentication (certificate validation).
  ///The host application must return either [ServerTrustAuthResponse] instance with [ServerTrustAuthResponseAction.CANCEL] or [ServerTrustAuthResponseAction.PROCEED].
  ///
  ///[challenge] contains data about host, port, protocol, realm, etc. as specified in the [URLAuthenticationChallenge].
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onReceivedSslError(android.webkit.WebView,%20android.webkit.SslErrorHandler,%20android.net.http.SslError)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455638-webview
  final Future<ServerTrustAuthResponse?> Function(
      InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? onReceivedServerTrustAuthRequest;

  ///Notify the host application to handle an SSL client certificate request.
  ///Webview stores the response in memory (for the life of the application) if [ClientCertResponseAction.PROCEED] or [ClientCertResponseAction.CANCEL]
  ///is called and does not call [onReceivedClientCertRequest] again for the same host and port pair.
  ///Note that, multiple layers in chromium network stack might be caching the responses.
  ///
  ///[challenge] contains data about host, port, protocol, realm, etc. as specified in the [ClientCertChallenge].
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onReceivedClientCertRequest(android.webkit.WebView,%20android.webkit.ClientCertRequest)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455638-webview
  final Future<ClientCertResponse?> Function(InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? onReceivedClientCertRequest;

  ///Event fired as find-on-page operations progress.
  ///The listener may be notified multiple times while the operation is underway, and the [numberOfMatches] value should not be considered final unless [isDoneCounting] is true.
  ///
  ///[activeMatchOrdinal] represents the zero-based ordinal of the currently selected match.
  ///
  ///[numberOfMatches] represents how many matches have been found.
  ///
  ///[isDoneCounting] whether the find operation has actually completed.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView ([Official API - WebView.FindListener.onFindResultReceived](https://developer.android.com/reference/android/webkit/WebView.FindListener#onFindResultReceived(int,%20int,%20boolean)))
  ///- iOS
  final void Function(InAppWebViewController controller, int activeMatchOrdinal,
      int numberOfMatches, bool isDoneCounting)? onFindResultReceived;

  ///Event fired when an `XMLHttpRequest` is sent to a server.
  ///It gives the host application a chance to take control over the request before sending it.
  ///
  ///[ajaxRequest] represents the `XMLHttpRequest`.
  ///
  ///**NOTE**: In order to be able to listen this event, you need to set [InAppWebViewSettings.useShouldInterceptAjaxRequest] option to `true`.
  ///Also, unlike iOS that has [WKUserScript](https://developer.apple.com/documentation/webkit/wkuserscript) that
  ///can inject javascript code right after the document element is created but before any other content is loaded, in Android the javascript code
  ///used to intercept ajax requests is loaded as soon as possible so it won't be instantaneous as iOS but just after some milliseconds (< ~100ms).
  ///Inside the `window.addEventListener("flutterInAppWebViewPlatformReady")` event, the ajax requests will be intercept for sure.
  final Future<AjaxRequest?> Function(
          InAppWebViewController controller, AjaxRequest ajaxRequest)?
      shouldInterceptAjaxRequest;

  ///Event fired whenever the `readyState` attribute of an `XMLHttpRequest` changes.
  ///It gives the host application a chance to abort the request.
  ///
  ///[ajaxRequest] represents the [XMLHttpRequest].
  ///
  ///**NOTE**: In order to be able to listen this event, you need to set [InAppWebViewSettings.useShouldInterceptAjaxRequest] option to `true`.
  ///Also, unlike iOS that has [WKUserScript](https://developer.apple.com/documentation/webkit/wkuserscript) that
  ///can inject javascript code right after the document element is created but before any other content is loaded, in Android the javascript code
  ///used to intercept ajax requests is loaded as soon as possible so it won't be instantaneous as iOS but just after some milliseconds (< ~100ms).
  ///Inside the `window.addEventListener("flutterInAppWebViewPlatformReady")` event, the ajax requests will be intercept for sure.
  final Future<AjaxRequestAction?> Function(
          InAppWebViewController controller, AjaxRequest ajaxRequest)?
      onAjaxReadyStateChange;

  ///Event fired as an `XMLHttpRequest` progress.
  ///It gives the host application a chance to abort the request.
  ///
  ///[ajaxRequest] represents the [XMLHttpRequest].
  ///
  ///**NOTE**: In order to be able to listen this event, you need to set [InAppWebViewSettings.useShouldInterceptAjaxRequest] option to `true`.
  ///Also, unlike iOS that has [WKUserScript](https://developer.apple.com/documentation/webkit/wkuserscript) that
  ///can inject javascript code right after the document element is created but before any other content is loaded, in Android the javascript code
  ///used to intercept ajax requests is loaded as soon as possible so it won't be instantaneous as iOS but just after some milliseconds (< ~100ms).
  ///Inside the `window.addEventListener("flutterInAppWebViewPlatformReady")` event, the ajax requests will be intercept for sure.
  final Future<AjaxRequestAction> Function(
          InAppWebViewController controller, AjaxRequest ajaxRequest)?
      onAjaxProgress;

  ///Event fired when a request is sent to a server through [Fetch API](https://developer.mozilla.org/it/docs/Web/API/Fetch_API).
  ///It gives the host application a chance to take control over the request before sending it.
  ///
  ///[fetchRequest] represents a resource request.
  ///
  ///**NOTE**: In order to be able to listen this event, you need to set [InAppWebViewSettings.useShouldInterceptFetchRequest] option to `true`.
  ///Also, unlike iOS that has [WKUserScript](https://developer.apple.com/documentation/webkit/wkuserscript) that
  ///can inject javascript code right after the document element is created but before any other content is loaded, in Android the javascript code
  ///used to intercept fetch requests is loaded as soon as possible so it won't be instantaneous as iOS but just after some milliseconds (< ~100ms).
  ///Inside the `window.addEventListener("flutterInAppWebViewPlatformReady")` event, the fetch requests will be intercept for sure.
  final Future<FetchRequest?> Function(
          InAppWebViewController controller, FetchRequest fetchRequest)?
      shouldInterceptFetchRequest;

  ///Event fired when the host application updates its visited links database.
  ///This event is also fired when the navigation state of the [WebView] changes through the usage of
  ///javascript **[History API](https://developer.mozilla.org/en-US/docs/Web/API/History_API)** functions (`pushState()`, `replaceState()`) and `onpopstate` event
  ///or, also, when the javascript `window.location` changes without reloading the webview (for example appending or modifying an hash to the url).
  ///
  ///[url] represents the url being visited.
  ///
  ///[androidIsReload] indicates if this url is being reloaded. Available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#doUpdateVisitedHistory(android.webkit.WebView,%20java.lang.String,%20boolean)
  final void Function(
          InAppWebViewController controller, Uri? url, bool? androidIsReload)?
      onUpdateVisitedHistory;

  ///Event fired when `window.print()` is called from JavaScript side.
  ///
  ///[url] represents the url on which is called.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  ///- iOS
  final Future<bool?> Function(
      InAppWebViewController controller,
      WebUri? webUri,
      PlatformPrintJobController? platformPrintJobController)? onPrintRequest;

  ///Event fired when an HTML element of the webview has been clicked and held.
  ///
  ///[hitTestResult] represents the hit result for hitting an HTML elements.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/view/View#setOnLongClickListener(android.view.View.OnLongClickListener)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uilongpressgesturerecognizer
  final void Function(InAppWebViewController controller,
      InAppWebViewHitTestResult hitTestResult)? onLongPressHitTestResult;

  ///Event fired when the current page has entered full screen mode.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onShowCustomView(android.view.View,%20android.webkit.WebChromeClient.CustomViewCallback)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiwindow/1621621-didbecomevisiblenotification
  final void Function(InAppWebViewController controller)? onEnterFullscreen;

  ///Event fired when the current page has exited full screen mode.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onHideCustomView()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiwindow/1621617-didbecomehiddennotification
  final void Function(InAppWebViewController controller)? onExitFullscreen;

  ///Called when the web view begins to receive web content.
  ///
  ///This event occurs early in the document loading process, and as such
  ///you should expect that linked resources (for example, CSS and images) may not be available.
  ///
  ///[url] represents the URL corresponding to the page navigation that triggered this callback.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onPageCommitVisible(android.webkit.WebView,%20java.lang.String)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455635-webview
  final void Function(InAppWebViewController controller, Uri? url)?
      onPageCommitVisible;

  ///Event fired when a change in the document title occurred.
  ///
  ///[title] represents the string containing the new title of the document.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onReceivedTitle(android.webkit.WebView,%20java.lang.String)
  final void Function(InAppWebViewController controller, String? title)?
      onTitleChanged;

  ///Event fired to respond to the results of an over-scroll operation.
  ///
  ///[x] represents the new X scroll value in pixels.
  ///
  ///[y] represents the new Y scroll value in pixels.
  ///
  ///[clampedX] is `true` if [x] was clamped to an over-scroll boundary.
  ///
  ///[clampedY] is `true` if [y] was clamped to an over-scroll boundary.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#onOverScrolled(int,%20int,%20boolean,%20boolean)
  final void Function(InAppWebViewController controller, int x, int y,
      bool clampedX, bool clampedY)? onOverScrolled;

  ///Event fired when the zoom scale of the WebView has changed.
  ///
  ///[oldScale] The old zoom scale factor.
  ///
  ///[newScale] The new zoom scale factor.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onScaleChanged(android.webkit.WebView,%20float,%20float)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollviewdelegate/1619409-scrollviewdidzoom
  final void Function(
          InAppWebViewController controller, double oldScale, double newScale)?
      onZoomScaleChanged;

  ///Event fired when the webview notifies that a loading URL has been flagged by Safe Browsing.
  ///The default behavior is to show an interstitial to the user, with the reporting checkbox visible.
  ///
  ///[url] represents the url of the request.
  ///
  ///[threatType] represents the reason the resource was caught by Safe Browsing, corresponding to a [SafeBrowsingThreat].
  ///
  ///**NOTE**: available only on Android 27+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onSafeBrowsingHit(android.webkit.WebView,%20android.webkit.WebResourceRequest,%20int,%20android.webkit.SafeBrowsingResponse)
  final Future<SafeBrowsingResponse?> Function(
      InAppWebViewController controller,
      Uri url,
      SafeBrowsingThreat? threatType)? onSafeBrowsingHit;

  ///Event fired when the WebView is requesting permission to access the specified resources and the permission currently isn't granted or denied.
  ///
  ///[origin] represents the origin of the web page which is trying to access the restricted resources.
  ///
  ///[resources] represents the array of resources the web content wants to access.
  ///
  ///**NOTE**: available only on Android 23+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onPermissionRequest(android.webkit.PermissionRequest)
  final Future<PermissionResponse?> Function(InAppWebViewController controller,
      PermissionRequest permissionRequest)? onPermissionRequest;

  ///Event that notifies the host application that web content from the specified origin is attempting to use the Geolocation API, but no permission state is currently set for that origin.
  ///Note that for applications targeting Android N and later SDKs (API level > `Build.VERSION_CODES.M`) this method is only called for requests originating from secure origins such as https.
  ///On non-secure origins geolocation requests are automatically denied.
  ///
  ///[origin] represents the origin of the web content attempting to use the Geolocation API.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onGeolocationPermissionsShowPrompt(java.lang.String,%20android.webkit.GeolocationPermissions.Callback)
  final Future<GeolocationPermissionShowPromptResponse?> Function(
          InAppWebViewController controller, String origin)?
      onGeolocationPermissionsShowPrompt;

  ///Notify the host application that a request for Geolocation permissions, made with a previous call to [onGeolocationPermissionsShowPrompt] has been canceled.
  ///Any related UI should therefore be hidden.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onGeolocationPermissionsHidePrompt()
  final void Function(InAppWebViewController controller)?
      onGeolocationPermissionsHidePrompt;

  ///Notify the host application of a resource request and allow the application to return the data.
  ///If the return value is `null`, the WebView will continue to load the resource as usual.
  ///Otherwise, the return response and data will be used.
  ///
  ///This callback is invoked for a variety of URL schemes (e.g., `http(s):`, `data:`, `file:`, etc.),
  ///not only those schemes which send requests over the network.
  ///This is not called for `javascript:` URLs, `blob:` URLs, or for assets accessed via `file:///android_asset/` or `file:///android_res/` URLs.
  ///
  ///In the case of redirects, this is only called for the initial resource URL, not any subsequent redirect URLs.
  ///
  ///[request] Object containing the details of the request.
  ///
  ///**NOTE**: available only on Android. In order to be able to listen this event, you need to set [AndroidInAppWebViewSettings.useShouldInterceptRequest] option to `true`.
  ///
  ///**Official Android API**:
  ///- https://developer.android.com/reference/android/webkit/WebViewClient#shouldInterceptRequest(android.webkit.WebView,%20android.webkit.WebResourceRequest)
  ///- https://developer.android.com/reference/android/webkit/WebViewClient#shouldInterceptRequest(android.webkit.WebView,%20java.lang.String)
  final Future<WebResourceResponse?> Function(
          InAppWebViewController controller, WebResourceRequest request)?
      shouldInterceptRequest;

  ///Event called when the renderer currently associated with the WebView becomes unresponsive as a result of a long running blocking task such as the execution of JavaScript.
  ///
  ///If a WebView fails to process an input event, or successfully navigate to a new URL within a reasonable time frame, the renderer is considered to be unresponsive, and this callback will be called.
  ///
  ///This callback will continue to be called at regular intervals as long as the renderer remains unresponsive.
  ///If the renderer becomes responsive again, [onRenderProcessResponsive] will be called once,
  ///and this method will not subsequently be called unless another period of unresponsiveness is detected.
  ///
  ///The minimum interval between successive calls to `onRenderProcessUnresponsive` is 5 seconds.
  ///
  ///No action is taken by WebView as a result of this method call.
  ///Applications may choose to terminate the associated renderer via the object that is passed to this callback,
  ///if in multiprocess mode, however this must be accompanied by correctly handling [onRenderProcessGone] for this WebView,
  ///and all other WebViews associated with the same renderer. Failure to do so will result in application termination.
  ///
  ///**NOTE**: available only on Android 29+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewRenderProcessClient#onRenderProcessUnresponsive(android.webkit.WebView,%20android.webkit.WebViewRenderProcess)
  final Future<WebViewRenderProcessAction?> Function(
      InAppWebViewController controller, Uri? url)? onRenderProcessUnresponsive;

  ///Event called once when an unresponsive renderer currently associated with the WebView becomes responsive.
  ///
  ///After a WebView renderer becomes unresponsive, which is notified to the application by [onRenderProcessUnresponsive],
  ///it is possible for the blocking renderer task to complete, returning the renderer to a responsive state.
  ///In that case, this method is called once to indicate responsiveness.
  ///
  ///No action is taken by WebView as a result of this method call.
  ///
  ///**NOTE**: available only on Android 29+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewRenderProcessClient#onRenderProcessResponsive(android.webkit.WebView,%20android.webkit.WebViewRenderProcess)
  final Future<WebViewRenderProcessAction?> Function(
      InAppWebViewController controller, Uri? url)? onRenderProcessResponsive;

  ///Event fired when the given WebView's render process has exited.
  ///The application's implementation of this callback should only attempt to clean up the WebView.
  ///The WebView should be removed from the view hierarchy, all references to it should be cleaned up.
  ///
  ///[detail] the reason why it exited.
  ///
  ///**NOTE**: available only on Android 26+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onRenderProcessGone(android.webkit.WebView,%20android.webkit.RenderProcessGoneDetail)
  final void Function(
          InAppWebViewController controller, RenderProcessGoneDetail detail)?
      onRenderProcessGone;

  ///As the host application if the browser should resend data as the requested page was a result of a POST. The default is to not resend the data.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onFormResubmission(android.webkit.WebView,%20android.os.Message,%20android.os.Message)
  final Future<FormResubmissionAction?> Function(
      InAppWebViewController controller, Uri? url)? onFormResubmission;

  ///Event fired when there is new favicon for the current page.
  ///
  ///[icon] represents the favicon for the current page.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onReceivedIcon(android.webkit.WebView,%20android.graphics.Bitmap)
  final void Function(InAppWebViewController controller, Uint8List icon)?
      onReceivedIcon;

  ///Event fired when there is an url for an apple-touch-icon.
  ///
  ///[url] represents the icon url.
  ///
  ///[precomposed] is `true` if the url is for a precomposed touch icon.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onReceivedTouchIconUrl(android.webkit.WebView,%20java.lang.String,%20boolean)
  final void Function(
          InAppWebViewController controller, Uri url, bool precomposed)?
      onReceivedTouchIconUrl;

  ///Event fired when the client should display a dialog to confirm navigation away from the current page.
  ///This is the result of the `onbeforeunload` javascript event.
  ///If [JsBeforeUnloadResponse.handledByClient] is `true`, WebView will assume that the client will handle the confirm dialog.
  ///If [JsBeforeUnloadResponse.handledByClient] is `false`, a default value of `true` will be returned to javascript to accept navigation away from the current page.
  ///The default behavior is to return `false`.
  ///Setting the [JsBeforeUnloadResponse.action] to [JsBeforeUnloadResponseAction.CONFIRM] will navigate away from the current page,
  ///[JsBeforeUnloadResponseAction.CANCEL] will cancel the navigation.
  ///
  ///[jsBeforeUnloadRequest] contains the message to be displayed in the alert dialog and the of the page requesting the dialog.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebChromeClient#onJsBeforeUnload(android.webkit.WebView,%20java.lang.String,%20java.lang.String,%20android.webkit.JsResult)
  final Future<JsBeforeUnloadResponse?> Function(
      InAppWebViewController controller,
      JsBeforeUnloadRequest jsBeforeUnloadRequest)? onJsBeforeUnload;

  ///Event fired when a request to automatically log in the user has been processed.
  ///
  ///[loginRequest] contains the realm, account and args of the login request.
  ///
  ///**NOTE**: available only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebViewClient#onReceivedLoginRequest(android.webkit.WebView,%20java.lang.String,%20java.lang.String,%20java.lang.String)
  final void Function(
          InAppWebViewController controller, LoginRequest loginRequest)?
      onReceivedLoginRequest;

  ///Invoked when the web view's web content process is terminated.
  ///
  ///**NOTE**: available only on iOS.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455639-webviewwebcontentprocessdidtermi
  final void Function(InAppWebViewController controller)?
      onWebContentProcessDidTerminate;

  ///Called when a web view receives a server redirect.
  ///
  ///**NOTE**: available only on iOS.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455627-webview
  final void Function(InAppWebViewController controller)?
      onDidReceiveServerRedirectForProvisionalNavigation;

  ///Called when a web view asks for permission to navigate to new content after the response to the navigation request is known.
  ///
  ///[navigationResponse] represents the navigation response.
  ///
  ///**NOTE**: available only on iOS. In order to be able to listen this event, you need to set [IOSInAppWebViewSettings.useOnNavigationResponse] option to `true`.
  ///
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455643-webview
  final Future<NavigationResponseAction?> Function(
      InAppWebViewController controller,
      NavigationResponse navigationResponse)? onNavigationResponse;

  ///Called when a web view asks whether to continue with a connection that uses a deprecated version of TLS (v1.0 and v1.1).
  ///
  ///[challenge] represents the authentication challenge.
  ///
  ///**NOTE**: available only on iOS 14.0+.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wknavigationdelegate/3601237-webview
  final Future<ShouldAllowDeprecatedTLSAction?> Function(
      InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? shouldAllowDeprecatedTLS;

  ///Initial url request that will be loaded.
  ///
  ///**NOTE for Android**: when loading an URL Request using "POST" method, headers are ignored.
  final URLRequest? initialUrlRequest;

  ///Initial asset file that will be loaded. See [InAppWebViewController.loadFile] for explanation.
  final String? initialFile;

  ///Initial [InAppWebViewInitialData] that will be loaded.
  final InAppWebViewInitialData? initialData;

  ///Initial options that will be used.
  final InAppWebViewSettings? initialSettings;

  ///Context menu which contains custom menu items to be shown when [ContextMenu] is presented.
  final ContextMenu? contextMenu;

  ///Initial list of user scripts to be loaded at start or end of a page loading.
  ///To add or remove user scripts, you have to use the [InAppWebViewController]'s methods such as [InAppWebViewController.addUserScript],
  ///[InAppWebViewController.removeUserScript], [InAppWebViewController.removeAllUserScripts], etc.
  ///
  ///**NOTE for iOS**: this property will be ignored if the [WebView.windowId] has been set.
  ///There isn't any way to add/remove user scripts specific to iOS window WebViews.
  ///This is a limitation of the native iOS WebKit APIs.
  final UnmodifiableListView<UserScript>? initialUserScripts;

  ///Represents the pull-to-refresh feature controller.
  ///
  ///**NOTE for Android**: to be able to use the "pull-to-refresh" feature, [AndroidInAppWebViewSettings.useHybridComposition] must be `true`.
  final PullToRefreshController? pullToRefreshController;

  @override
  State<Web3WebView> createState() => _InAppWebViewEIP1193State();
}

class _InAppWebViewEIP1193State extends State<Web3WebView> {
  /// Script provider will inject in web app
  String? jsProviderScript;

  /// Load provider and function initial web3 end
  bool isLoadJs = false;
  InAppWebViewController? _webViewController;
  final EthereumProvider _provider = EthereumProvider();
  final _ethNetwork = NetworkConfig(
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
  final _bscNetwork = NetworkConfig(
    chainId: '0x38',
    chainName: 'Binance Smart Chain Mainnet',
    nativeCurrency: NativeCurrency(
      name: 'Binance Coin',
      symbol: 'BNB',
      decimals: 18,
    ),
    rpcUrls: ['https://bsc-dataseed.binance.org/'],
    blockExplorerUrls: ['https://bscscan.com'],
  );

  @override
  void initState() {
    super.initState();
    _loadWeb3();
    _provider.initialize(
      defaultNetwork: widget.web3WalletConfig?.currentNetwork ?? _ethNetwork,
      additionalNetworks: widget.web3WalletConfig?.supportNetworks ??
          [_ethNetwork, _bscNetwork],
      privateKey: widget.web3WalletConfig?.privateKey ?? '',
      providerInfo: EIP6963ProviderInfo(
        uuid: const Uuid().v4(),
        name: widget.web3WalletConfig?.name ?? 'MetaMask',
        icon: widget.web3WalletConfig?.icon ??
            'data:image/svg+xml;base64,PHN2ZyBmaWxsPSJub25lIiBoZWlnaHQ9IjMzIiB2aWV3Qm94PSIwIDAgMzUgMzMiIHdpZHRoPSIzNSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIHN0cm9rZS13aWR0aD0iLjI1Ij48cGF0aCBkPSJtMzIuOTU4MiAxLTEzLjEzNDEgOS43MTgzIDIuNDQyNC01LjcyNzMxeiIgZmlsbD0iI2UxNzcyNiIgc3Ryb2tlPSIjZTE3NzI2Ii8+PGcgZmlsbD0iI2UyNzYyNSIgc3Ryb2tlPSIjZTI3NjI1Ij48cGF0aCBkPSJtMi42NjI5NiAxIDEzLjAxNzE0IDkuODA5LTIuMzI1NC01LjgxODAyeiIvPjxwYXRoIGQ9Im0yOC4yMjk1IDIzLjUzMzUtMy40OTQ3IDUuMzM4NiA3LjQ4MjkgMi4wNjAzIDIuMTQzNi03LjI4MjN6Ii8+PHBhdGggZD0ibTEuMjcyODEgMjMuNjUwMSAyLjEzMDU1IDcuMjgyMyA3LjQ2OTk0LTIuMDYwMy0zLjQ4MTY2LTUuMzM4NnoiLz48cGF0aCBkPSJtMTAuNDcwNiAxNC41MTQ5LTIuMDc4NiAzLjEzNTggNy40MDUuMzM2OS0uMjQ2OS03Ljk2OXoiLz48cGF0aCBkPSJtMjUuMTUwNSAxNC41MTQ5LTUuMTU3NS00LjU4NzA0LS4xNjg4IDguMDU5NzQgNy40MDQ5LS4zMzY5eiIvPjxwYXRoIGQ9Im0xMC44NzMzIDI4Ljg3MjEgNC40ODE5LTIuMTYzOS0zLjg1ODMtMy4wMDYyeiIvPjxwYXRoIGQ9Im0yMC4yNjU5IDI2LjcwODIgNC40Njg5IDIuMTYzOS0uNjEwNS01LjE3MDF6Ii8+PC9nPjxwYXRoIGQ9Im0yNC43MzQ4IDI4Ljg3MjEtNC40NjktMi4xNjM5LjM2MzggMi45MDI1LS4wMzkgMS4yMzF6IiBmaWxsPSIjZDViZmIyIiBzdHJva2U9IiNkNWJmYjIiLz48cGF0aCBkPSJtMTAuODczMiAyOC44NzIxIDQuMTU3MiAxLjk2OTYtLjAyNi0xLjIzMS4zNTA4LTIuOTAyNXoiIGZpbGw9IiNkNWJmYjIiIHN0cm9rZT0iI2Q1YmZiMiIvPjxwYXRoIGQ9Im0xNS4xMDg0IDIxLjc4NDItMy43MTU1LTEuMDg4NCAyLjYyNDMtMS4yMDUxeiIgZmlsbD0iIzIzMzQ0NyIgc3Ryb2tlPSIjMjMzNDQ3Ii8+PHBhdGggZD0ibTIwLjUxMjYgMjEuNzg0MiAxLjA5MTMtMi4yOTM1IDIuNjM3MiAxLjIwNTF6IiBmaWxsPSIjMjMzNDQ3IiBzdHJva2U9IiMyMzM0NDciLz48cGF0aCBkPSJtMTAuODczMyAyOC44NzIxLjY0OTUtNS4zMzg2LTQuMTMxMTcuMTE2N3oiIGZpbGw9IiNjYzYyMjgiIHN0cm9rZT0iI2NjNjIyOCIvPjxwYXRoIGQ9Im0yNC4wOTgyIDIzLjUzMzUuNjM2NiA1LjMzODYgMy40OTQ2LTUuMjIxOXoiIGZpbGw9IiNjYzYyMjgiIHN0cm9rZT0iI2NjNjIyOCIvPjxwYXRoIGQ9Im0yNy4yMjkxIDE3LjY1MDctNy40MDUuMzM2OS42ODg1IDMuNzk2NiAxLjA5MTMtMi4yOTM1IDIuNjM3MiAxLjIwNTF6IiBmaWxsPSIjY2M2MjI4IiBzdHJva2U9IiNjYzYyMjgiLz48cGF0aCBkPSJtMTEuMzkyOSAyMC42OTU4IDIuNjI0Mi0xLjIwNTEgMS4wOTEzIDIuMjkzNS42ODg1LTMuNzk2Ni03LjQwNDk1LS4zMzY5eiIgZmlsbD0iI2NjNjIyOCIgc3Ryb2tlPSIjY2M2MjI4Ii8+PHBhdGggZD0ibTguMzkyIDE3LjY1MDcgMy4xMDQ5IDYuMDUxMy0uMTAzOS0zLjAwNjJ6IiBmaWxsPSIjZTI3NTI1IiBzdHJva2U9IiNlMjc1MjUiLz48cGF0aCBkPSJtMjQuMjQxMiAyMC42OTU4LS4xMTY5IDMuMDA2MiAzLjEwNDktNi4wNTEzeiIgZmlsbD0iI2UyNzUyNSIgc3Ryb2tlPSIjZTI3NTI1Ii8+PHBhdGggZD0ibTE1Ljc5NyAxNy45ODc2LS42ODg2IDMuNzk2Ny44NzA0IDQuNDgzMy4xOTQ5LTUuOTA4N3oiIGZpbGw9IiNlMjc1MjUiIHN0cm9rZT0iI2UyNzUyNSIvPjxwYXRoIGQ9Im0xOS44MjQyIDE3Ljk4NzYtLjM2MzggMi4zNTg0LjE4MTkgNS45MjE2Ljg3MDQtNC40ODMzeiIgZmlsbD0iI2UyNzUyNSIgc3Ryb2tlPSIjZTI3NTI1Ii8+PHBhdGggZD0ibTIwLjUxMjcgMjEuNzg0Mi0uODcwNCA0LjQ4MzQuNjIzNi40NDA2IDMuODU4NC0zLjAwNjIuMTE2OS0zLjAwNjJ6IiBmaWxsPSIjZjU4NDFmIiBzdHJva2U9IiNmNTg0MWYiLz48cGF0aCBkPSJtMTEuMzkyOSAyMC42OTU4LjEwNCAzLjAwNjIgMy44NTgzIDMuMDA2Mi42MjM2LS40NDA2LS44NzA0LTQuNDgzNHoiIGZpbGw9IiNmNTg0MWYiIHN0cm9rZT0iI2Y1ODQxZiIvPjxwYXRoIGQ9Im0yMC41OTA2IDMwLjg0MTcuMDM5LTEuMjMxLS4zMzc4LS4yODUxaC00Ljk2MjZsLS4zMjQ4LjI4NTEuMDI2IDEuMjMxLTQuMTU3Mi0xLjk2OTYgMS40NTUxIDEuMTkyMSAyLjk0ODkgMi4wMzQ0aDUuMDUzNmwyLjk2Mi0yLjAzNDQgMS40NDItMS4xOTIxeiIgZmlsbD0iI2MwYWM5ZCIgc3Ryb2tlPSIjYzBhYzlkIi8+PHBhdGggZD0ibTIwLjI2NTkgMjYuNzA4Mi0uNjIzNi0uNDQwNmgtMy42NjM1bC0uNjIzNi40NDA2LS4zNTA4IDIuOTAyNS4zMjQ4LS4yODUxaDQuOTYyNmwuMzM3OC4yODUxeiIgZmlsbD0iIzE2MTYxNiIgc3Ryb2tlPSIjMTYxNjE2Ii8+PHBhdGggZD0ibTMzLjUxNjggMTEuMzUzMiAxLjEwNDMtNS4zNjQ0Ny0xLjY2MjktNC45ODg3My0xMi42OTIzIDkuMzk0NCA0Ljg4NDYgNC4xMjA1IDYuODk4MyAyLjAwODUgMS41Mi0xLjc3NTItLjY2MjYtLjQ3OTUgMS4wNTIzLS45NTg4LS44MDU0LS42MjIgMS4wNTIzLS44MDM0eiIgZmlsbD0iIzc2M2UxYSIgc3Ryb2tlPSIjNzYzZTFhIi8+PHBhdGggZD0ibTEgNS45ODg3MyAxLjExNzI0IDUuMzY0NDctLjcxNDUxLjUzMTMgMS4wNjUyNy44MDM0LS44MDU0NS42MjIgMS4wNTIyOC45NTg4LS42NjI1NS40Nzk1IDEuNTE5OTcgMS43NzUyIDYuODk4MzUtMi4wMDg1IDQuODg0Ni00LjEyMDUtMTIuNjkyMzMtOS4zOTQ0eiIgZmlsbD0iIzc2M2UxYSIgc3Ryb2tlPSIjNzYzZTFhIi8+PHBhdGggZD0ibTMyLjA0ODkgMTYuNTIzNC02Ljg5ODMtMi4wMDg1IDIuMDc4NiAzLjEzNTgtMy4xMDQ5IDYuMDUxMyA0LjEwNTItLjA1MTloNi4xMzE4eiIgZmlsbD0iI2Y1ODQxZiIgc3Ryb2tlPSIjZjU4NDFmIi8+PHBhdGggZD0ibTEwLjQ3MDUgMTQuNTE0OS02Ljg5ODI4IDIuMDA4NS0yLjI5OTQ0IDcuMTI2N2g2LjExODgzbDQuMTA1MTkuMDUxOS0zLjEwNDg3LTYuMDUxM3oiIGZpbGw9IiNmNTg0MWYiIHN0cm9rZT0iI2Y1ODQxZiIvPjxwYXRoIGQ9Im0xOS44MjQxIDE3Ljk4NzYuNDQxNy03LjU5MzIgMi4wMDA3LTUuNDAzNGgtOC45MTE5bDIuMDAwNiA1LjQwMzQuNDQxNyA3LjU5MzIuMTY4OSAyLjM4NDIuMDEzIDUuODk1OGgzLjY2MzVsLjAxMy01Ljg5NTh6IiBmaWxsPSIjZjU4NDFmIiBzdHJva2U9IiNmNTg0MWYiLz48L2c+PC9zdmc+',
        rdns: widget.web3WalletConfig?.id ?? 'io.metamask',
      ),
      theme: widget.web3WalletConfig?.dialogTheme ?? WalletDialogTheme(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider.setContext(context);
  }

  ///Load provider initial web3 to inject web app
  Future<void> _loadWeb3() async {
    try {
      String? web3;
      String path = 'packages/web3_webview/assets/ethers.min.js';
      web3 = await DefaultAssetBundle.of(context).loadString(path);
      if (mounted) {
        setState(() {
          jsProviderScript = web3;
          isLoadJs = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error load web3: $e");
      }
      if (mounted) {
        setState(() {
          isLoadJs = false;
        });
      }
    }
  }

  /// Get function with newest config
  String _getFunctionInject() {
    return _provider.getProviderScript();
  }

  @override
  Widget build(BuildContext context) {
    return isLoadJs == false
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : InAppWebView(
            windowId: widget.windowId,
            initialUrlRequest: widget.initialUrlRequest,
            initialFile: widget.initialFile,
            initialData: widget.initialData,
            initialSettings: widget.initialSettings,
            initialUserScripts: widget.initialUserScripts ??
                (isLoadJs == true
                    ? UnmodifiableListView([
                        UserScript(
                          source: jsProviderScript ?? '',
                          injectionTime:
                              UserScriptInjectionTime.AT_DOCUMENT_START,
                        ),
                        UserScript(
                          source: _getFunctionInject(),
                          injectionTime:
                              UserScriptInjectionTime.AT_DOCUMENT_START,
                        ),
                      ])
                    : null),
            pullToRefreshController: widget.pullToRefreshController,
            contextMenu: widget.contextMenu,
            onWebViewCreated: (controller) async {
              _webViewController = controller;
              _provider.setWebViewController(controller);
              // Đăng ký handler để nhận message từ JavaScript
              controller.addJavaScriptHandler(
                handlerName: 'ethereumRequest',
                callback: (args) async {
                  final request = args[0] as Map<String, dynamic>;
                  final method = request['method'] as String;
                  final params = request['params'] as List<dynamic>?;
                  // final chainId = request['chainId'] as String?;
                  try {
                    return await _provider.handleRequest(
                      method,
                      params,
                      // chainId: chainId,
                    );
                  } catch (e) {
                    widget.web3WalletConfig?.onError?.call(
                        JsonRpcMethod.fromString(method), params, e.toString());
                    // throw PlatformException(
                    //   code: 'WALLET_ERROR',
                    //   message: e.toString(),
                    // );
                  }
                },
              );
              widget.onWebViewCreated?.call(controller);
            },
            onLoadStart: (controller, url) async {
              widget.onLoadStart?.call(controller, url);
              if (Platform.isAndroid) {
                await _webViewController?.evaluateJavascript(
                  source: jsProviderScript ?? '',
                );
                await _webViewController?.evaluateJavascript(
                  source: _getFunctionInject(),
                );
              }
            },
            onLoadStop: widget.onLoadStop,
            onReceivedError: widget.onReceivedError,
            onReceivedHttpError: widget.onReceivedHttpError,
            onConsoleMessage: widget.onConsoleMessage,
            onProgressChanged: widget.onProgressChanged,
            shouldOverrideUrlLoading: widget.shouldOverrideUrlLoading,
            onLoadResource: widget.onLoadResource,
            onScrollChanged: widget.onScrollChanged,
            onDownloadStartRequest: widget.onDownloadStartRequest,
            onLoadResourceWithCustomScheme:
                widget.onLoadResourceWithCustomScheme,
            onCreateWindow: widget.onCreateWindow,
            onCloseWindow: widget.onCloseWindow,
            onJsAlert: widget.onJsAlert,
            onJsConfirm: widget.onJsConfirm,
            onJsPrompt: widget.onJsPrompt,
            onReceivedHttpAuthRequest: widget.onReceivedHttpAuthRequest,
            onReceivedServerTrustAuthRequest:
                widget.onReceivedServerTrustAuthRequest,
            onReceivedClientCertRequest: widget.onReceivedClientCertRequest,
            onFindResultReceived: widget.onFindResultReceived,
            shouldInterceptAjaxRequest: widget.shouldInterceptAjaxRequest,
            onAjaxReadyStateChange: widget.onAjaxReadyStateChange,
            onAjaxProgress: widget.onAjaxProgress,
            shouldInterceptFetchRequest: widget.shouldInterceptFetchRequest,
            onUpdateVisitedHistory: widget.onUpdateVisitedHistory,
            onPrintRequest: widget.onPrintRequest,
            onLongPressHitTestResult: widget.onLongPressHitTestResult,
            onEnterFullscreen: widget.onEnterFullscreen,
            onExitFullscreen: widget.onExitFullscreen,
            onPageCommitVisible: widget.onPageCommitVisible,
            onTitleChanged: widget.onTitleChanged,
            onWindowFocus: widget.onWindowFocus,
            onWindowBlur: widget.onWindowBlur,
            onOverScrolled: widget.onOverScrolled,
            onZoomScaleChanged: widget.onZoomScaleChanged,
            onSafeBrowsingHit: widget.onSafeBrowsingHit,
            onPermissionRequest: widget.onPermissionRequest ??
                (controller, PermissionRequest permissionRequest) async {
                  return PermissionResponse(
                    resources: permissionRequest.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
            onGeolocationPermissionsShowPrompt:
                widget.onGeolocationPermissionsShowPrompt,
            onGeolocationPermissionsHidePrompt:
                widget.onGeolocationPermissionsHidePrompt,
            shouldInterceptRequest: widget.shouldInterceptRequest,
            onRenderProcessGone: widget.onRenderProcessGone,
            onRenderProcessResponsive: widget.onRenderProcessResponsive,
            onRenderProcessUnresponsive: widget.onRenderProcessUnresponsive,
            onFormResubmission: widget.onFormResubmission,
            onReceivedIcon: widget.onReceivedIcon,
            onReceivedTouchIconUrl: widget.onReceivedTouchIconUrl,
            onJsBeforeUnload: widget.onJsBeforeUnload,
            onReceivedLoginRequest: widget.onReceivedLoginRequest,
            onWebContentProcessDidTerminate:
                widget.onWebContentProcessDidTerminate,
            onDidReceiveServerRedirectForProvisionalNavigation:
                widget.onDidReceiveServerRedirectForProvisionalNavigation,
            onNavigationResponse: widget.onNavigationResponse,
            shouldAllowDeprecatedTLS: widget.shouldAllowDeprecatedTLS,
            gestureRecognizers: widget.gestureRecognizers,
          );
  }
}
