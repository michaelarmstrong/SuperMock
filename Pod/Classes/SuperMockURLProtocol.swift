//
//  SuperMockURLProtocol.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class SuperMockURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        
        if request.hasMock() {
            print("Requesting MOCK for : \(String(describing: request.url))")
            return true
        }
        print("Passing Through WITHOUT MOCK : \(String(describing: request.url))")
        return false
    }
    
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        
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
    
    override func stopLoading() {
    }
}

class SuperMockRecordingURLProtocol: URLProtocol {
    
    var connection : NSURLConnection?
    var mutableData : NSMutableData?
    var dataTask: URLSessionDataTask?
    var response: URLResponse?
    
    override class func canInit(with request: URLRequest) -> Bool {
        
        if let _ = URLProtocol.property(forKey: "SuperMockRecordingURLProtocol", in: request) {
            return false
        }
        if SuperMockResponseHelper.sharedHelper.recording  {
            return true
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to:b)
    }
    
    override func startLoading() {
        
        if let copyRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
            
            URLProtocol.setProperty(request.url!, forKey: "SuperMockRecordingURLProtocol", in: copyRequest)
            let configuration = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
            
            dataTask = session.dataTask(with: copyRequest as URLRequest)
            dataTask?.resume()
            self.dataTask!.resume()
        }
    }
    
    override func stopLoading() {
        dataTask?.cancel()
        response = nil
        mutableData = nil
        
        connection?.cancel()
    }
}
extension SuperMockRecordingURLProtocol: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        mutableData?.append(data)
    }
}
extension SuperMockRecordingURLProtocol: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        mutableData = NSMutableData()
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        SuperMockResponseHelper.sharedHelper.recordDataForRequest(mutableData! as Data, request: request)
        client?.urlProtocolDidFinishLoading(self)
        
    }
}

extension SuperMockRecordingURLProtocol: NSURLConnectionDataDelegate {
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        if let httpResponse = response as? HTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            SuperMockResponseHelper.sharedHelper.recordResponseHeadersForRequest(headers, request: request, response: httpResponse)
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        mutableData?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        client?.urlProtocolDidFinishLoading(self)
        // TODO: fix the !
        SuperMockResponseHelper.sharedHelper.recordDataForRequest(mutableData! as Data, request: request)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        client?.urlProtocol(self, didFailWithError: error)
    }
}
