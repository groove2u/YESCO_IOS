//
//  ViewController.swift
//  HiHR
//
//  Created by skyblue on 2021/06/23.
//  Copyright © 2021 skyblue. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

let callBackName = "checkinnumber"

class ViewController: UIViewController {
    

    var webView: WKWebView = WKWebView()
    var interaction:UIDocumentInteractionController?

    var url: URL {
//        #if targetEnvironment(simulator)
//            return URL(string: "http://10.160.51.159:8080/checkin.do")!
//        #else
//            return URL(string: "http://iope.tosky.co.kr:8080/checkin.do")!
//        #endif
        //http://apne2-dspddev-a-ifa-front-alb-1709361931.ap-northeast-2.elb.amazonaws.com/checkin.do
        
        return URL(string: "https://zhressapp-g110bc197.dispatcher.jp1.hana.ondemand.com/indexMobile.html")!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearCache()
        let prefs = UserDefaults.standard
        if let token = prefs.value(forKey: "token") {
            print("@@@ This token : \(token)")
        }
        registerForPushNotifications()

        initWebView()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - 웹뷰 캐시 클리어
    func clearCache() {
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: {
            (records) -> Void in
            for record in records{
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("delete cache data")
            }
        })
    }
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    //MARK: - 웹뷰 초기화
    func initWebView() {
        
        let controller = WKUserContentController()
        controller.add(self, name: "openDocument")
        controller.add(self, name: "jsError")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        webView.uiDelegate = self
        webView.navigationDelegate = self

        let request = URLRequest(url: url)
        webView.load(request)
        
        view.addSubview(webView)
    }
/*
    //MARK: - Scanner VC 호출
    func showBarcodeVC(_ lang: String) {
        
        let storyboard = UIStoryboard.init(name: "Scanner", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(identifier: "ScannerVC") as! ScannerViewController
        
        vc.language = lang
        
        vc.callBack = {(barcode) in
            self.callScript(barcode)
        }
        
        self.present(vc, animated: true, completion: nil)
    }
  */
    //MARK: - JS 호출
    func callScript(_ barcode: String) {
        
        webView.evaluateJavaScript("\(callBackName)('\(barcode)')") { (any, error) in
            if error != nil {
                print("error = \(error!.localizedDescription)")
            }
        }
    }
    
    //MARK: - Present Alert View
    func showAlert(title: String?,
                   message: String?,
                   confirm: @escaping ((_ action: UIAlertAction) -> Void),
                   cancel: ((_ action: UIAlertAction) -> Void)?) {
        
        let alert = UIAlertController(title: title ?? "알림", message: message ?? "", preferredStyle: .alert)
        
        let done = UIAlertAction(title: "확인", style: .default, handler: confirm)
        alert.addAction(done)
        
        if cancel != nil {
            let cane = UIAlertAction(title: "취소", style: .cancel, handler: cancel)
            alert.addAction(cane)
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    //MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        self.showAlert(title: "Web Alert", message: message, confirm: {_ in
            completionHandler()
        }, cancel: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        self.showAlert(title: "Web Alert", message: message, confirm: { (_) in
            completionHandler(true)
        }) { (_) in
            completionHandler(false)
        }
    }

    func webView(_ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        if let mimeType = navigationResponse.response.mimeType {
            // do some thing with the MIME type
        } else {
            // response has no MIME type, do some special handling
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("### Custom Scheme test")

        if navigationAction.navigationType == WKNavigationType.linkActivated {
            print("link")
        }
        let urlStr = navigationAction.request.url?.absoluteString

        if let url = navigationAction.request.url ,url.scheme == "bizx" {
            
            print(UIApplication.shared.canOpenURL(url))
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let url = URL(string: "itms-apps://apple.com/app/id426562526") {
                    UIApplication.shared.open(url)
                }
            }
            
            decisionHandler(.cancel)
        } else if let url = navigationAction.request.url , (urlStr?.contains("blob"))!{
/*
            print(UIApplication.shared.canOpenURL(url))
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let url = URL(string: "itms-apps://apple.com/app/id426562526") {
                    UIApplication.shared.open(url)
                }
            }

            guard let url = URL(string: urlStr!) else { return }
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true, completion: nil)
  */
            executeDocumentDownloadScript(forAbsoluteUrl: url.absoluteString)

            decisionHandler(.cancel)
        }
        else {
            decisionHandler(.allow)
        }
    }
    //MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("start")


        
    }
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        print("test")
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("error \(error)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
    }
    //MARK: - 첨부파일 다운로드

    func handleDocument(messageBody: String) {
        
        // messageBody is in the format ;data:;base64,

        // split on the first ";", to reveal the filename
        let filenameSplits = messageBody.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)

        let filename = String(filenameSplits[0])

        // split the remaining part on the first ",", to reveal the base64 data
        let dataSplits = filenameSplits[1].split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)

        let data = Data(base64Encoded: String(dataSplits[1]))

        if (data == nil) {
            debugPrint("Could not construct data from base64")
            return
        }

        // store the file on disk (.removingPercentEncoding removes possible URL encoded characters like "%20" for blank)
        let localFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename.removingPercentEncoding ?? filename)
        
        print(localFileURL.absoluteString)

        do {
            try data!.write(to: localFileURL);
        } catch {
            debugPrint(error)
            return
        }

        // and display it in QL
        DispatchQueue.main.async {
            
            self.interaction = UIDocumentInteractionController(url: localFileURL)
            self.interaction?.delegate = self
            self.interaction?.presentPreview(animated: true) // IF SHOW DIRECT

            
            // localFileURL
            // now you have your file
            //let targetUrl = URL(string: "http://naver.com")
            
            //let safariViewController = SFSafariViewController(url: localFileURL)
            //self.present(safariViewController, animated: true, completion: nil)
            
            
            /*
            let importMenu = UIDocumentPickerViewController(documentTypes: ["com.microsoft.word.doc","org.openxmlformats.wordprocessingml.document", kUTTypePDF as String], in: UIDocumentPickerMode.import)
            importMenu.delegate = self
            self.present(importMenu, animated: true, completion: nil)
 */
/*
            if UIApplication.shared.canOpenURL(localFileURL) {
                UIApplication.shared.open(localFileURL, options: [:], completionHandler: nil)
            }
 */
        }
    }
    
    
    
    //MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.name == "openDocument") {
            handleDocument(messageBody: message.body as! String)
        } else if (message.name == "jsError") {
            debugPrint(message.body as! String)
        }

        /*
        print(message.name)
        
        if message.name == messageName {
            
            //전달받은 웹 언어 정보
            let lang = (message.body) as? String
            
            //바코드 뷰 호출
            //showBarcodeVC(lang!)
        }
 */
    }
    
    private func executeDocumentDownloadScript(forAbsoluteUrl absoluteUrl : String) {
        // TODO: Add more supported mime-types for missing content-disposition headers
        webView.evaluateJavaScript("""
            (async function download() {
                const url = '\(absoluteUrl)';
                try {
                    // we use a second try block here to have more detailed error information
                    // because of the nature of JS the outer try-catch doesn't know anything where the error happended
                    let res;
                    try {
                        res = await fetch(url, {
                            credentials: 'include'
                        });
                    } catch (err) {
                        window.webkit.messageHandlers.jsError.postMessage(`fetch threw, error: ${err}, url: ${url}`);
                        return;
                    }
                    if (!res.ok) {
                        window.webkit.messageHandlers.jsError.postMessage(`Response status was not ok, status: ${res.status}, url: ${url}`);
                        return;
                    }
            
                    const contentDisp = res.headers.get('content-disposition');

                    window.webkit.messageHandlers.jsError.postMessage(`ContentDisp: ${contentDisp}`);

                    if (contentDisp) {
                        const match = contentDisp.match(/(^;|)\\s*filename=\\s*(\"([^\"]*)\"|([^;\\s]*))\\s*(;|$)/i);
                        if (match) {
                            filename = match[3] || match[4];
                        } else {
                            // TODO: we could here guess the filename from the mime-type (e.g. unnamed.pdf for pdfs, or unnamed.tiff for tiffs)
                            window.webkit.messageHandlers.jsError.postMessage(`content-disposition header could not be matched against regex, content-disposition: ${contentDisp} url: ${url}`);
                        }
                    } else {
                        window.webkit.messageHandlers.jsError.postMessage(`content-disposition header missing, url: ${url}`);
                    }
                    window.webkit.messageHandlers.jsError.postMessage(`check========1111`);
                    const contentType = res.headers.get('content-type');
                    window.webkit.messageHandlers.jsError.postMessage(`Mime Type=${contentType}`);
                    if (contentType.indexOf('application/json') === 0) {
                        filename = 'unnamed.pdf';
                    } else if (contentType.indexOf('image/tiff') === 0) {
                        filename = 'unnamed.tiff';
                    }

                    window.webkit.messageHandlers.jsError.postMessage(`check========22222`);
                    filename = 'unnamed.pdf';
                    window.webkit.messageHandlers.jsError.postMessage(`filename========${filename}`);
                    if (!filename) {
                        window.webkit.messageHandlers.jsError.postMessage(`Could not determine filename from content-disposition nor content-type, content-dispositon: ${contentDispositon}, content-type: ${contentType}, url: ${url}`);
                    }
            window.webkit.messageHandlers.jsError.postMessage(`check========33333`);

                    let data;
                    try {
                        data = await res.blob();
                    } catch (err) {
                        window.webkit.messageHandlers.jsError.postMessage(`res.blob() threw, error: ${err}, url: ${url}`);
                        return;
                    }
            window.webkit.messageHandlers.jsError.postMessage(`check========`);

            const fr = new FileReader();
                    fr.onload = () => {
                        window.webkit.messageHandlers.openDocument.postMessage(`${filename};${fr.result}`)
                    };
                    fr.addEventListener('error', (err) => {
                        window.webkit.messageHandlers.jsError.postMessage(`FileReader threw, error: ${err}`)
                    })
                    fr.readAsDataURL(data);
                } catch (err) {
                    // TODO: better log the error, currently only TypeError: Type error
                    window.webkit.messageHandlers.jsError.postMessage(`JSError while downloading document, url: ${url}, err: ${err}`)
                }
            })();
            // null is needed here as this eval returns the last statement and we can't return a promise
            null;
        """) { (result, err) in
            if (err != nil) {
                debugPrint("JS ERR: \(String(describing: err))")
            }
        }
    }
}
extension ViewController : UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    public func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        interaction = nil
    }
}

