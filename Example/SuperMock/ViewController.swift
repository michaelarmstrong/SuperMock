//
//  ViewController.swift
//  SuperMock
//
//  Created by Michael Armstrong on 11/02/2015.
//  Copyright (c) 2015 Michael Armstrong. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    let urlSession = NSURLSession.sharedSession()

    
    @IBAction func performRealRequest(sender: AnyObject) {
    
        let realURL = NSURL(string: "http://apple.com/")!
        let requestToMock = NSURLRequest(URL: realURL)
        
        let task = urlSession.dataTaskWithRequest(requestToMock) { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                print("Real Response : \(stringResponse)")
                
                self.webView.loadHTMLString(stringResponse, baseURL: nil)
            }
        }
        task.resume()
    }
    
    @IBAction func performMockedRequest(sender: AnyObject) {
        
        let realURL = NSURL(string: "http://mike.kz/")!
        let requestToMock = NSURLRequest(URL: realURL)
        
        let task = urlSession.dataTaskWithRequest(requestToMock) { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                print("Mock Response : \(stringResponse)")
                
                self.webView.loadHTMLString(stringResponse, baseURL: nil)
            }
        }
        task.resume()
    }
    
    
    
    
    
    
    
    
    
    
    // TODO: The below (UIWebView Mocking)doesn't work in this version, but will in the next.
    func performSampleWebViewLoad() {
        
        let realURL = NSURL(string: "http://mike.kz/")!
        let realRequest = NSURLRequest(URL: realURL)
        webView.loadRequest(realRequest)
        webView.delegate = self
    }
    
    // MARK: UIWebViewDelegate
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("Webview Error : \(error?.localizedDescription)")
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print("Webview Finished Loading")
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        print("Webview Started Loading")
    }
}

