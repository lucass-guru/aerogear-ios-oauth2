/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

import UIKit
import WebKit

/**
OAuth2WebViewController is a UIViewController to be used when the Oauth2 flow used an embedded view controller
rather than an external browser approach.
*/
open class OAuth2WebViewController: UIViewController {
    /// Login URL for OAuth.
    var targetURL: URL!
    /// WebView instance used to load login page.
    var webView: WKWebView?
    /// WebView back button
    var hasBackButton: Bool = false
    var backButton: UIBarButtonItem = {
        let customBackButton = UIBarButtonItem(image: UIImage(named: "baseline_keyboard_arrow_left_black") , style: .plain, target: self, action: #selector(buttonPressed(sender:)))
        customBackButton.imageInsets = UIEdgeInsets(top: 2, left: -8, bottom: 0, right: 0)
        return customBackButton
    }()

    /// Override of viewDidLoad to load the login page.
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        webView = buildWebView()
        webView?.navigationDelegate = self
        //self.view.addSubview(webView)
        
        if hasBackButton {
            webView?.frame = CGRect( x:0, y:44, width: view.frame.size.width, height: view.frame.size.height - 44 )
            
            let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
            view.addSubview(navBar)

            let navItem = UINavigationItem()
            navItem.hidesBackButton = true
            
            navItem.leftBarButtonItem = backButton

            navBar.setItems([navItem], animated: false)
        }
        
        loadAddressURL()
    }
    
    open override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func buttonPressed(sender: UIButton!) {
        guard let canGoBack = webView?.canGoBack else { return }
        
        if canGoBack {
            webView?.goBack()
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //self.webView.frame = self.view.bounds
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func loadAddressURL() {
        let req = URLRequest(url: targetURL)
        webView?.load(req)
    }
}

extension OAuth2WebViewController: WKNavigationDelegate {
    func buildWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let bodyStyle = "body { margin:0; }"
        let source = "var node = document.createElement(\"style\"); node.innerHTML = \"\(bodyStyle)\";document.body.appendChild(node);"

        let script = WKUserScript(
                    source: source,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: false
                )

        config.userContentController.addUserScript(script)
        
        var r = self.view.frame
        r.origin = CGPoint( x: 0, y: 0 )
        let webView: WKWebView = self.view.viewWithTag(-99) as? WKWebView ?? WKWebView( frame: r, configuration: config )
        
        webView.tag = -99
        webView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleWidth, .flexibleHeight ]
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.contentInset = .zero
        webView.scrollView.layer.masksToBounds = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        
        self.view.addSubview( webView )
        return webView
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.canGoBack {
            backButton.isEnabled = true
        }
        else {
            backButton.isEnabled = false
        }
    }
    
    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        let app = UIApplication.shared
        
        if !(url!.scheme!.starts( with: "http" )) {
            if app.canOpenURL(url!) {
                app.openURL(url!)
                decisionHandler( .cancel )
                return
            }
        }
        
        decisionHandler( .allow )
    }
}

