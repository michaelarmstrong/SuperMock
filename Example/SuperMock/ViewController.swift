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
    lazy var urlCustomSession : NSURLSession = {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        // This is the key for custom configuration, add the protocols
        sessionConfiguration.addProtocols()
        return NSURLSession(configuration: sessionConfiguration)
    }()

    @IBOutlet weak var testableButtonOne: UIButton!    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateButtonTitles()
    }
    
    @IBAction func performRealRequest(sender: AnyObject) {
        
        let realURL = NSURL(string: "https://developer.apple.com")!
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
        
        let task = urlCustomSession.dataTaskWithRequest(requestToMock) { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                print("Mock Response : \(stringResponse)")
                
                self.webView.loadHTMLString(stringResponse, baseURL: nil)
            }
        }
        task.resume()
    }
    @IBAction func performRealCustomRequest(sender: AnyObject) {
        
        let realURL = NSURL(string: "http://apple.com/")!
        let requestToMock = NSURLRequest(URL: realURL)
        
        let task = urlCustomSession.dataTaskWithRequest(requestToMock) { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                print("Real Response : \(stringResponse)")
                
                self.webView.loadHTMLString(stringResponse, baseURL: nil)
            }
        }
        task.resume()
    }
    
    @IBAction func performMockedCustomRequest(sender: AnyObject) {
        
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
    
   func updateButtonTitles() {
        
        let realURL = NSURL(string: "http://mike.kz/api/layout/buttons/")!
        let requestToMock = NSURLRequest(URL: realURL)
        
        let task = urlSession.dataTaskWithRequest(requestToMock) { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                print("Mock Response : \(stringResponse)")
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.testableButtonOne.setTitle(stringResponse, forState: .Normal)
                    self.testableButtonOne.accessibilityValue = stringResponse
                })
            }
        }
        task.resume()
    }
    // TODO: it is already working :)
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

