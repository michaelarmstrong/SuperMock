//
//  SuperMockURLProtocolTests.swift
//  SuperMock_Tests
//
//  Created by Scheggia on 23/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import SuperMock

class SuperMockURLProtocolTests: XCTestCase {
    var sut: SuperMockURLProtocol!
    var client: MockURLProtocolClient!
    var task: MockURLSessionTask!
    
    override func setUp() {
        super.setUp()
        client = MockURLProtocolClient()
        task = MockURLSessionTask()
        sut = SuperMockURLProtocol(task: task, cachedResponse: nil, client: client)
        SuperMock.beginMocking(Bundle(for: SuperMockURLProtocolTests.self))
    }
    
    override func tearDown() {
        SuperMock.endMocking()
        super.tearDown()
    }
    
    func test_canInit_returnTrue_whenHasMocks() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        XCTAssertEqual(SuperMockURLProtocol.canInit(with: request), true)
    }
    
    func test_canInit_returnFalse_whenHasNoMocks() {
        let request = URLRequest(url: URL(string: "http://apple.com/Daniele")!)
        XCTAssertEqual(SuperMockURLProtocol.canInit(with: request), false)
        
    }
    
    func test_canonicalRequest_shouldReturn_theSameRequest() {
        let request = URLRequest(url: URL(string: "http://apple.com/Daniele")!)
        XCTAssertEqual(SuperMockURLProtocol.canonicalRequest(for: request), request)
    }
    
    func test_startLoading_shouldCallDidReceive_withCorrectResponse() {
        sut.startLoading()
        XCTAssertEqual(client.didReceiveCounter, 1)
        XCTAssertNotNil(client.responseSpy)
        XCTAssertEqual(client.responseSpy?.url, sut.request.url)
    }
    
    func test_startLoading_shouldCallDidLoad_withCorrectResponse() {
        sut.startLoading()
        XCTAssertEqual(client.didLoadCounter, 1)
        XCTAssertNotNil(client.dataSpy)
    }
    
    func test_startLoading_shouldCallDidFinishLoading_withCorrectResponse() {
        sut.startLoading()
        XCTAssertEqual(client.didLoadCounter, 1)
    }
}

class SuperMockURecordingRLProtocolTests: XCTestCase {
    var sut: SuperMockRecordingURLProtocol!
    var client: MockURLProtocolClient!
    var task: MockURLSessionTask!
    
    override func setUp() {
        super.setUp()
        client = MockURLProtocolClient()
        task = MockURLSessionTask()
        sut = SuperMockRecordingURLProtocol(task: task, cachedResponse: nil, client: client)
        SuperMock.beginRecording(Bundle(for: SuperMockURLProtocolTests.self))
        sut.dataTask = URLSessionDataTask()
    }
    
    override func tearDown() {
        SuperMock.endMocking()
        super.tearDown()
    }
    
    func test_canInit_returnTrue_whenRecording() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        XCTAssertEqual(SuperMockRecordingURLProtocol.canInit(with: request), true)
    }
    
    func test_canInit_returnFalse_whenHasMockKeyInHeader() {
        let request = NSMutableURLRequest(url: URL(string: "http://apple.com/Daniele")!)
        URLProtocol.setProperty(request.url!, forKey: "SuperMockRecordingURLProtocol", in: request)
        XCTAssertEqual(SuperMockRecordingURLProtocol.canInit(with: request as URLRequest), false)
    }
    
    func test_canInit_returnFalse_whenIsNotrecording() {
        SuperMock.endRecording()
        let request = URLRequest(url: URL(string: "http://apple.com/Daniele")!)
        XCTAssertEqual(SuperMockRecordingURLProtocol.canInit(with: request), false)
    }
    
    func test_canonicalRequest_shouldReturn_theSameRequest() {
        let request = URLRequest(url: URL(string: "http://apple.com/Daniele")!)
        XCTAssertEqual(SuperMockRecordingURLProtocol.canonicalRequest(for: request), request)
    }
    
    func test_startLoading_shouldStartNewDataTask_withCopyrequest() {
        sut.startLoading()
        XCTAssertNotNil(sut.dataTask)
        XCTAssertNotEqual(sut.dataTask?.currentRequest, task.currentRequest)
        XCTAssertNotEqual(sut.dataTask, task)
        XCTAssertEqual(sut.dataTask?.currentRequest?.url, task.currentRequest?.url)
    }
    
    func test_stopLoading_shouldNilDataTask() {
        sut.startLoading()
        sut.stopLoading()
        XCTAssertNil(sut.dataTask)
    }
    
    func test_stopLoading_shouldNilResponse() {
        sut.startLoading()
        sut.response = URLResponse(url: URL(string: "http://aple.com/")!, mimeType: nil, expectedContentLength: 100, textEncodingName: nil)
        sut.stopLoading()
        XCTAssertNil(sut.response)
    }
    
    func test_stopLoading_shouldEmptyMutableData() {
        sut.startLoading()
        let mutableData = NSMutableData(base64Encoded: "someRandomString", options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
        sut.mutableData = mutableData
        sut.stopLoading()
        XCTAssertNotNil(sut.mutableData)
        XCTAssertEqual(sut.mutableData.length, 0)
        XCTAssertNotEqual(sut.mutableData, mutableData)
    }
    
    func test_didReceive_shouldCallDidLoadOnClient() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let data = "someDAta".data(using: .utf8)
        sut.startLoading()
        
        sut.urlSession(session, dataTask: sut.dataTask!, didReceive: data!)
        XCTAssertEqual(client.didLoadCounter, 1)
    }
    
    func test_didReceive_shouldAppendData() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let data = "someDAta".data(using: .utf8)
        sut.startLoading()
        
        sut.urlSession(session, dataTask: sut.dataTask!, didReceive: data!)
        XCTAssertEqual(sut.mutableData.length, data?.count)
    }
    
    func test_didReceiveResponse_shouldCallClient() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let response = URLResponse(url: URL(string: "http://aple.com/")!, mimeType: nil, expectedContentLength: 100, textEncodingName: nil)
        
        sut.urlSession(session, dataTask: sut.dataTask!, didReceive: response) { _ in }
        
        XCTAssertEqual(client.didReceiveCounter, 1)
    }
    
    func test_didReceiveResponse_shoulInitMutableData() {
        sut.mutableData = NSMutableData(base64Encoded: "someData".data(using: .utf8)!, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let response = URLResponse(url: URL(string: "http://aple.com/")!, mimeType: nil, expectedContentLength: 100, textEncodingName: nil)
        
        sut.urlSession(session, dataTask: sut.dataTask!, didReceive: response) { _ in }
        
        XCTAssertEqual(sut.mutableData.length, 0)
    }
    
    func test_didReceiveResponse_shoulCallCompletionHandler() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let response = URLResponse(url: URL(string: "http://aple.com/")!, mimeType: nil, expectedContentLength: 100, textEncodingName: nil)
        
        var completionCounter = 0
        sut.urlSession(session, dataTask: sut.dataTask!, didReceive: response) { _ in completionCounter += 1 }
        
        XCTAssertEqual(completionCounter, 1)
    }
    
    func test_didComplete_shouldCallFail_onError() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let error = NSError(domain: "Random error", code: 500, userInfo: nil)
        
        sut.urlSession(session, task: task, didCompleteWithError: error)
        XCTAssertEqual(client.failCounter, 1)
        XCTAssertEqual(client.didfinishingLoadingCounter, 0)
        
    }
    
    func test_didComplet_shouldCallFinish_OnSuccess() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        sut.urlSession(session, task: task, didCompleteWithError: nil)
        XCTAssertEqual(client.failCounter, 0)
        XCTAssertEqual(client.didfinishingLoadingCounter, 1)
        
    }
    
    func test_didComplet_shouldRecorDataForRequest_OnSuccess() {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        sut.mutableData = NSMutableData(base64Encoded: "someData".data(using: .utf8)!, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        SuperMockRecordingURLProtocol.canInit(with: request)
        
        let bundle = Bundle(for: SuperMockURLProtocolTests.self)
        
        SuperMock.beginRecording(bundle, mocksFile: "MocksRecording.plist")
        
        sut.urlSession(session, task: task, didCompleteWithError: nil)
        
        guard let recordedMocksFilePath = SuperMockResponseHelper.sharedHelper.mockFileOutOfBundle()
            else { return XCTFail("The recoded filePath need to exist to locate the file") }
        let definitions = NSDictionary(contentsOfFile: recordedMocksFilePath)
        XCTAssertNotNil(definitions)
        let getsMocks = definitions?.value(forKeyPath: "mocks.GET") as? [String:[[String: String]]]
        XCTAssertEqual(getsMocks?.count, 2)
        
        guard let dataFile = getsMocks?["http://apple.com/"]?.last?["data"]
            else { return XCTFail("The recoded dataPath need to be exist to locate the file") }
        var mockUrl = URL(fileURLWithPath: recordedMocksFilePath)
        mockUrl.deleteLastPathComponent()
        let dataUrl = mockUrl.appendingPathComponent(dataFile)
        let data = try? Data(contentsOf: dataUrl)
        XCTAssertNotNil(data)
        XCTAssertEqual(data, sut.mutableData as Data)
        
        guard let responseFile = getsMocks?["http://apple.com/"]?.last?["response"]
            else { return XCTFail("The recoded dataPath need to be exist to locate the file") }
        
        let responseUrl = mockUrl.appendingPathComponent(responseFile)
        let responseRecorded = try? Data(contentsOf: responseUrl)
        XCTAssertNotNil(responseRecorded)
        
        // Clean up
        try? FileManager.default.removeItem(atPath: recordedMocksFilePath)
        try? FileManager.default.removeItem(at: responseUrl)
        try? FileManager.default.removeItem(at: dataUrl)
        SuperMock.endRecording()
        
        XCTAssertEqual(client.didfinishingLoadingCounter, 1)
    }
}

class MockURLSessionTask: URLSessionTask {
    var requestSpy = URLRequest(url: URL(string: "http://apple.com/")!)
    override var currentRequest: URLRequest? {
        return requestSpy
    }
    
    var _response = HTTPURLResponse(url: URL(string: "http://aple.com/")!, statusCode: 200, httpVersion: nil, headerFields: [:])
    override var response: URLResponse? {
        return _response
    }
}

class MockURLProtocolClient:NSObject, URLProtocolClient {
    
    var responseSpy: URLResponse?
    var cachePolicySpy: URLCache.StoragePolicy?
    var didReceiveCounter = 0
    func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) {
        responseSpy = response
        cachePolicySpy = policy
        didReceiveCounter += 1
    }
    
    var didLoadCounter = 0
    var dataSpy: Data?
    func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
        dataSpy = data
        didLoadCounter += 1
    }
    
    
    func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) {}
    
    func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) {}
    
    var didfinishingLoadingCounter = 0
    func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
        didfinishingLoadingCounter += 1
    }
    var failCounter = 0
    func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error) {
        failCounter += 1
    }
    
    func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) { }
    
    
    func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) { }
    
}
