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
    
    let urlSession = URLSession.shared
    lazy var urlCustomSession : URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        
        // This is the key for custom configuration, add the protocols
        sessionConfiguration.addProtocols()
        return URLSession(configuration: sessionConfiguration)
    }()

    @IBOutlet weak var testableButtonOne: UIButton!    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateButtonTitles()
    }
    
    @IBAction func performRealRequest(_ sender: AnyObject) {
        
        let realURL = URL(string: "https://developer.apple.com")!
        let requestToMock = URLRequest(url: realURL)
        
        let task = urlSession.dataTask(with: requestToMock, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                print("Real Response : \(stringResponse)")
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(stringResponse, baseURL: nil)
                }
            }
        }) 
        task.resume()
    }
    
    @IBAction func performMockedRequest(_ sender: AnyObject) {
        
        let realURL = URL(string: "http://mike.kz/")!
        let requestToMock = URLRequest(url: realURL)
        
        let task = urlCustomSession.dataTask(with: requestToMock, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(stringResponse, baseURL: nil)
                }
            }
        }) 
        task.resume()
    }
    @IBAction func performRealCustomRequest(_ sender: AnyObject) {
        
        let realURL = URL(string: "http://apple.com/")!
        let requestToMock = URLRequest(url: realURL)
        
        let task = urlCustomSession.dataTask(with: requestToMock, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(stringResponse, baseURL: nil)
                }
            }
        }) 
        task.resume()
    }
    
    @IBAction func performMockedCustomRequest(_ sender: AnyObject) {
        
        let realURL = URL(string: "http://mike.kz/")!
        let requestToMock = URLRequest(url: realURL)
        
        let task = urlSession.dataTask(with: requestToMock, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(stringResponse, baseURL: nil)
                }
            }
        }) 
        task.resume()
    }
    
   func updateButtonTitles() {
        
        let realURL = URL(string: "http://mike.kz/api/layout/buttons/")!
        let requestToMock = URLRequest(url: realURL)
        
        let task = urlSession.dataTask(with: requestToMock, completionHandler: { (data, response, error) -> Void in
            if let data = data {
                let stringResponse = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
                
                DispatchQueue.main.async {
                    self.testableButtonOne.setTitle(stringResponse, for: UIControl.State())
                    self.testableButtonOne.accessibilityValue = stringResponse
                }
            }
        }) 
        task.resume()
    }
    // TODO: it is already working :)
    // TODO: The below (UIWebView Mocking)doesn't work in this version, but will in the next.
    func performSampleWebViewLoad() {
        
        let realURL = URL(string: "http://mike.kz/")!
        let realRequest = URLRequest(url: realURL)
        webView.loadRequest(realRequest)
        webView.delegate = self
    }
    
    // MARK: UIWebViewDelegate
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("Webview Error : \(error.localizedDescription)")
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("Webview Finished Loading")
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        print("Webview Started Loading")
    }
}

