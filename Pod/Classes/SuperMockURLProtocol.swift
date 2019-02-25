//
//  SuperMockURLProtocol.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

@objc
public class SuperMockURLProtocol: URLProtocol {
    
    override public class func canInit(with request: URLRequest) -> Bool {
        
        if request.hasMock() {
            print("Requesting MOCK for : \(String(describing: request.url))")
            return true
        }
        print("Passing Through WITHOUT MOCK : \(String(describing: request.url))")
        return false
    }
    
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override public func startLoading() {
        
        let mockedRequest = SuperMockResponseHelper.sharedHelper.mockRequest(request)
        if let mockData = SuperMockResponseHelper.sharedHelper.responseForMockRequest(mockedRequest) {
            
            let mimeType = SuperMockResponseHelper.sharedHelper.mimeType(mockedRequest.url!)
            var response = URLResponse(url: mockedRequest.url!, mimeType: mimeType, expectedContentLength: mockData.count, textEncodingName: "utf8")
            if let mockResponse = SuperMockResponseHelper.sharedHelper.mockResponse(request) {
                response = mockResponse
            }
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mockData)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override public func stopLoading() {
        
    }
}

@objc
public class SuperMockRecordingURLProtocol: URLProtocol {
    
    var mutableData = NSMutableData()
    var dataTask: URLSessionDataTask?
    var response: URLResponse?
    
    override public class func canInit(with request: URLRequest) -> Bool {
        
        if let _ = URLProtocol.property(forKey: "SuperMockRecordingURLProtocol", in: request) {
            return false
        }
        if SuperMockResponseHelper.sharedHelper.recording  {
            return true
        }
        return false
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    } 
    
    override public func startLoading() {
        
        if let copyRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
            
            URLProtocol.setProperty(request.url!, forKey: "SuperMockRecordingURLProtocol", in: copyRequest)
            let configuration = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
            
            dataTask = session.dataTask(with: copyRequest as URLRequest)
            dataTask?.resume()
        }
    }
    
    override public func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
        response = nil
        mutableData = NSMutableData()
    }
}

extension SuperMockRecordingURLProtocol: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        mutableData.append(data)
    }
}

extension SuperMockRecordingURLProtocol: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        mutableData = NSMutableData()
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let httpResponse = task.response as? HTTPURLResponse {
            
            var headersModified = httpResponse.allHeaderFields
            headersModified["status"] = "\(httpResponse.statusCode)"
            SuperMockResponseHelper.sharedHelper.recordDataForRequest(mutableData as Data, httpHeaders: headersModified, request: request)
        }
        client?.urlProtocolDidFinishLoading(self)
        
    }
}
