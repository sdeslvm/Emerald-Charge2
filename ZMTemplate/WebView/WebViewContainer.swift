//
//  WebViewContainer.swift
//  ZMTemplate
//

import SwiftUI
import WebKit
#if os(iOS)
import UIKit
import UniformTypeIdentifiers

struct WebViewContainer: UIViewRepresentable {
    @EnvironmentObject private var coordinator: WebViewCoordinator
    let url: URL
    
    

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = CoordinatedWKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = coordinator.userAgent
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        if #available(iOS 13.0, *) {
            webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        context.coordinator.attach(webView: webView, appCoordinator: coordinator)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        coordinator.updateState(from: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
        private weak var webView: WKWebView?
        private weak var appCoordinator: WebViewCoordinator?
        private var pendingFileUploadCompletion: (([URL]?) -> Void)?

        func attach(webView: WKWebView, appCoordinator: WebViewCoordinator) {
            self.webView = webView
            self.appCoordinator = appCoordinator
            appCoordinator.hostWebView = webView
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            appCoordinator?.updateState(from: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            appCoordinator?.updateState(from: webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let scheme = (url.scheme ?? "").lowercased()
            let internalSchemes: Set<String> = ["http", "https", "about", "srcdoc", "blob", "data", "javascript", "file"]

            if internalSchemes.contains(scheme) {
                decisionHandler(.allow)
                return
            }

            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }

        // MARK: - WKUIDelegate

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Если ссылка открывается в новом окне (target="_blank" или window.open),
            // загружаем её в текущем WebView
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webViewDidClose(_ webView: WKWebView) {
            appCoordinator?.closeChild()
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            presentAlert(title: "Сообщение", message: message, completion: completionHandler)
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            presentConfirm(title: "Подтверждение", message: message, completion: completionHandler)
        }

        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            presentPrompt(title: prompt, defaultText: defaultText, completion: completionHandler)
        }

        

        // MARK: - Presentation Helpers

        private func presentCamera() {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                presentDocumentPicker()
                return
            }

            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.image", "public.movie"]
            picker.delegate = self
            presentController(picker)
        }

        private func presentDocumentPicker() {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .image, .movie], asCopy: true)
            picker.delegate = self
            presentController(picker)
        }

        private func presentAlert(title: String, message: String, completion: @escaping () -> Void) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completion() }))
            presentController(alert)
        }

        private func presentConfirm(title: String, message: String, completion: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { _ in completion(false) }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completion(true) }))
            presentController(alert)
        }

        private func presentPrompt(title: String, defaultText: String?, completion: @escaping (String?) -> Void) {
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { _ in completion(nil) }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
                completion(alert?.textFields?.first?.text)
            }))
            presentController(alert)
        }

        private func presentController(_ controller: UIViewController) {
            DispatchQueue.main.async {
                guard let root = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow })?.rootViewController else {
                        return
                    }
                root.present(controller, animated: true)
            }
        }

        // MARK: - UIDocumentPickerDelegate

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            pendingFileUploadCompletion?(nil)
            pendingFileUploadCompletion = nil
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            pendingFileUploadCompletion?(urls)
            pendingFileUploadCompletion = nil
        }

        // MARK: - UIImagePickerControllerDelegate

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            pendingFileUploadCompletion?(nil)
            pendingFileUploadCompletion = nil
            picker.dismiss(animated: true)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            var tempURL: URL?
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.9) {
                tempURL = saveTemporary(data: data, fileExtension: "jpg")
            } else if let videoURL = info[.mediaURL] as? URL {
                tempURL = videoURL
            }

            if let tempURL {
                pendingFileUploadCompletion?([tempURL])
            } else {
                pendingFileUploadCompletion?(nil)
            }
            pendingFileUploadCompletion = nil
            picker.dismiss(animated: true)
        }

        private func saveTemporary(data: Data, fileExtension: String) -> URL? {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
            do {
                try data.write(to: fileURL)
                return fileURL
            } catch {
                return nil
            }
        }
    }
}
#endif
