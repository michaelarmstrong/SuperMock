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
        return request
    }

    override func startLoading() {
        
        let mockedRequest = SuperMockResponseHelper.sharedHelper.mockRequest(request)
        if let mockData = SuperMockResponseHelper.sharedHelper.responseForMockRequest(mockedRequest) {
   
            //TODO: Fix up the below for use in UIWebView's.
            //      let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 302, HTTPVersion: "HTTP/1.1", headerFields: ["Location":request.URL!.absoluteString])!
            //  client?.URLProtocol(self, wasRedirectedToRequest: request, redirectResponse: response)

            let mimeType = SuperMockResponseHelper.sharedHelper.mimeType(mockedRequest.URL!)
            var response = NSURLResponse(URL: mockedRequest.URL!, MIMEType: mimeType, expectedContentLength: mockData.length, textEncodingName: "utf8")
            if let mockResponse = SuperMockResponseHelper.sharedHelper.mockResponse(request) {
                response = mockResponse
            }
            
            client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
            client?.URLProtocol(self, didLoadData: mockData)
            client?.URLProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
    }
}

class SuperMockRecordingURLProtocol: NSURLProtocol {
    
    var connection : NSURLConnection?
    var mutableData : NSMutableData?
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        
        if let _ = NSURLProtocol.propertyForKey("SuperMockRecordingURLProtocol", inRequest: request) {
            return false
        }
        if SuperMockResponseHelper.sharedHelper.recording  {
            return true
        }
        return false
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, toRequest:b)
    }
    
    override func startLoading() {
        
        if let copyRequest = request.mutableCopy() as? NSMutableURLRequest {
            
            NSURLProtocol.setProperty(request.URL!, forKey: "SuperMockRecordingURLProtocol", inRequest: copyRequest)
            connection = NSURLConnection(request: copyRequest, delegate: self)
            
            mutableData = NSMutableData()
        }
    }
    
    override func stopLoading() {
        connection?.cancel()
    }
}

extension SuperMockRecordingURLProtocol: NSURLConnectionDataDelegate {
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        if let httpResponse = response as? NSHTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            SuperMockResponseHelper.sharedHelper.recordResponseHeadersForRequest(headers, request: request, response: httpResponse)
        }
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: NSURLCacheStoragePolicy.NotAllowed)
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        client?.URLProtocol(self, didLoadData: data)
        mutableData?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        client?.URLProtocolDidFinishLoading(self)
        SuperMockResponseHelper.sharedHelper.recordDataForRequest(mutableData, request: request)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        client?.URLProtocol(self, didFailWithError: error)
    }
}
