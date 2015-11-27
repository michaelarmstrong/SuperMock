//
//  SuperMockURLProtocol.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class SuperMockURLProtocol: NSURLProtocol {
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        
        if request.hasMock() {
            print("Requesting MOCK for : \(request.URL)")
            return true
        }
        print("Passing Through WITHOUT MOCK : \(request.URL)")
        return false
    }
    
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return SuperMockResponseHelper.sharedHelper.mockRequest(request)
    }

    override func startLoading() {
                
        if let mockData = SuperMockResponseHelper.sharedHelper.responseForMockRequest(request) {
   
            //TODO: Fix up the below for use in UIWebView's.
            //      let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 302, HTTPVersion: "HTTP/1.1", headerFields: ["Location":request.URL!.absoluteString])!
            //  client?.URLProtocol(self, wasRedirectedToRequest: request, redirectResponse: response)

            let mimeType = SuperMockResponseHelper.sharedHelper.mimeType(request.URL!)
            let response = NSURLResponse(URL: request.URL!, MIMEType: mimeType, expectedContentLength: mockData.length, textEncodingName: "utf8")
            
            client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
            client?.URLProtocol(self, didLoadData: mockData)
            client?.URLProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
    }
    
}
