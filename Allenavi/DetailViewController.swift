//
//  DetailViewController.swift
//  Allenavi
//
//  Created by ShimmenNobuyoshi on 2016/02/23.
//  Copyright © 2016年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import WebKit
import SVProgressHUD

class DetailViewController: UIViewController {

    var pageUrl: String? {
        didSet {
            if pageUrl != nil {
                let config = WKWebViewConfiguration()
                let jScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
                let wkUScript = WKUserScript(source: jScript, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                let wkUcontentController = WKUserContentController()
                wkUcontentController.addUserScript(wkUScript)
                config.userContentController = wkUcontentController
                self.webView = WKWebView(frame: self.view.frame, configuration: config)
                let url = NSURL(string: pageUrl!)
                self.webView!.loadRequest(NSURLRequest(URL: url!))
                webView!.center = self.view.center
                webView!.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
                self.view.addSubview(webView!)
            }
        }
    }
    var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.webView?.removeObserver(self, forKeyPath: "loading")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch keyPath! {
        case "loading":
            if !self.webView!.loading {
                if SVProgressHUD.isVisible() {
                    SVProgressHUD.dismiss()
                }
            }
        default:
            break
        }
    }

}
