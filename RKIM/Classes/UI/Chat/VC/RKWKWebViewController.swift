//
//  RKWKWebViewController.swift
//  RokidSDK
//
//  Created by 金志文 on 2021/10/2.
//

import UIKit
import WebKit
import RKIBaseView

class RKWKWebViewController: RKBaseViewController {

    var url: URL?
    
    private lazy var wkWebView = WKWebView().then {
        self.view.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.left.bottom.right.equalToSuperview()
        }
        
        $0.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        $0.addObserver(self, forKeyPath: "title", options: .new, context: nil)
    }
    
    private lazy var progress = UIProgressView().then {
        
        self.view.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
        $0.tintColor = .blue
        $0.backgroundColor = .lightGray
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.wkWebView.load(URLRequest(url: url!))
        guard let url = url else { return }
        
        let request = URLRequest(url: url)
        wkWebView.load(request)
        wkWebView.navigationDelegate = self
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
            self.title = self.wkWebView.title
        } else if keyPath == "estimatedProgress" {
            self.progress.alpha = 1.0
            self.progress.setProgress(Float(self.wkWebView.estimatedProgress), animated: true)
            
            if self.wkWebView.estimatedProgress >= 1.0 {
                
                UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseInOut) {
                    self.progress.alpha = 0.0
                } completion: { finished in
                    self.progress.setProgress(0.0, animated: false)
                } 
            }
        }
    }
}


extension RKWKWebViewController: WKNavigationDelegate {
    
    @nonobjc func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    @nonobjc func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
    }
    

}
