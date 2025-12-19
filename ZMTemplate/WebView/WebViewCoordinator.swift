//
//  WebViewCoordinator.swift
//  ZMTemplate
//

import Foundation
import Combine
import WebKit
#if canImport(UIKit)
import UIKit
#endif

final class WebViewCoordinator: NSObject, ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var currentURL: URL?
    @Published var childWebView: WKWebView?

    var userAgent: String = "Version/17.2 Mobile/15E148 Safari/604.1"
    weak var hostWebView: WKWebView?

    func updateState(from webView: WKWebView) {
        DispatchQueue.main.async { [weak self, weak webView] in
            guard let self, let webView else { return }
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            self.isLoading = webView.isLoading
            self.currentURL = webView.url
        }
    }

    func pushChild(with configuration: WKWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = userAgent
        childWebView = webView
        return webView
    }

    func closeChild() {
        childWebView = nil
    }

    func goBack() {
        if let child = childWebView, child.canGoBack {
            child.goBack()
        } else if let host = hostWebView, host.canGoBack {
            host.goBack()
        }
    }

    func goForward() {
        if let child = childWebView, child.canGoForward {
            child.goForward()
        } else if let host = hostWebView, host.canGoForward {
            host.goForward()
        }
    }
}
