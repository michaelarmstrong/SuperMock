//
//  SuperMockResponseHelperTests.swift
//  SuperMock_Tests
//
//  Created by Scheggia on 10/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import SuperMock

class SuperMockResponseHelperTests: XCTestCase {

    var sut = SuperMockResponseHelper.sharedHelper
    let bundle = Bundle(for: SuperMockResponseHelperTests.self)
    
    override func setUp() {
        super.setUp()
        SuperMockResponseHelper.bundleForMocks = bundle
    }
    
    func test_bundleForMocks_returnCorrectBundle() {
        XCTAssertEqual(SuperMockResponseHelper.bundleForMocks, bundle)
    }
    
    func test_bundleForMocks_triggerSetsMocks() {
        XCTAssertEqual(sut.mocks.count, 4)
    }
    
    func test_bundleForMocks_triggerSetsMimes() {
        XCTAssertEqual(sut.mimes.count, 3)
    }
    
    func test_mockRequest_returnSameRequest_whenNoMocks() {
        let request = URLRequest(url: URL(string: "http://apple.com/Daniele")!)
        XCTAssertEqual(sut.mockRequest(request), request)
    }
    
    func test_mockRequest_returnMockedRequest_whenMockIsAvailable() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        XCTAssertNotEqual(sut.mockRequest(request), request)
    }
    
    func test_mockResponse_exaustResponses_whenMockIsAvailable() {
        guard let url = URL(string: "http://apple.com/")
            else { return XCTFail("the url need to exist, for this test to execute") }
        let request = URLRequest(url: url)
        
        var getMocks = sut.mocks["GET"] as? [String:Any]
        var mocks = getMocks?[url.absoluteString] as? [[String:String]]
        XCTAssertEqual(mocks?.count, 3)
        let _ = sut.mockResponse(request)
        getMocks = sut.mocks["GET"] as? [String:Any]
        mocks = getMocks?[url.absoluteString] as? [[String:String]]
        XCTAssertEqual(mocks?.count, 2)
        let _ = sut.mockResponse(request)
        let _ = sut.mockResponse(request)
        let _ = sut.mockResponse(request)
        getMocks = sut.mocks["GET"] as? [String:Any]
        mocks = getMocks?[url.absoluteString] as? [[String:String]]
        XCTAssertEqual(mocks?.count, 1)
    }
    
    func test_mockRequest_returnMockedRequest_withSuperMockHTTPHeader() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        let newRequest = sut.mockRequest(request)
        
        XCTAssertEqual(newRequest.allHTTPHeaderFields?["X-SUPERMOCK-MOCKREQUEST"], "true")
    }
    
    func test_responseForMockRequest_returnNil_whenItIsNotAFile() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        let data = sut.responseForMockRequest(request)
        XCTAssertNil(data)
    }
    
    func test_responseForMockRequest_returnNil_whenCannotReadFile() {
        let request = URLRequest(url: URL(fileURLWithPath: "file.plist"))
        let data = sut.responseForMockRequest(request)
        XCTAssertNil(data)
    }
    
    func test_responseForMockRequest_returnData() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        let newRequest = sut.mockRequest(request)
        
        let data = sut.responseForMockRequest(newRequest)
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 28241)
        
    }
    
    func test_mimeType_shouldReturnPlainText_whenNoUrlFound() {
        let url = URL(string: "http://apple.com/unknown")!
        XCTAssertEqual(sut.mimeType(url), "text/plain")
    }
    
    func test_mimeType_shouldReturnType_whenUrlFound() {
        let url = URL(string: "apple.json")!
        XCTAssertEqual(sut.mimeType(url), "application/json")
    }
    
    func test_recordDataForRequest_shouldRecordFiles() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        let mockedRequest = sut.mockRequest(request)
        let response = sut.mockResponse(request) as? HTTPURLResponse
        let responseData = sut.responseForMockRequest(mockedRequest)
        SuperMock.beginRecording(bundle, mocksFile: "MocksRecording.plist")
        
        sut.recordDataForRequest(responseData, httpHeaders: response?.allHeaderFields, request: request)
        
        guard let recordedMocksFilePath = sut.mockFileOutOfBundle()
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
    }
    
    func test_recordDataForRequest_shouldNotRecord_whenMissingHeaders() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        let mockedRequest = sut.mockRequest(request)
        let responseData = sut.responseForMockRequest(mockedRequest)
        SuperMock.beginRecording(bundle, mocksFile: "MocksRecording.plist")
        
        sut.recordDataForRequest(responseData, httpHeaders: nil, request: request)
        
        guard let recordedMocksFilePath = sut.mockFileOutOfBundle()
            else { return XCTFail("The recoded filePath need to exist to locate the file") }
        let definitions = NSDictionary(contentsOfFile: recordedMocksFilePath)
        XCTAssertNotNil(definitions)
        let getsMocks = definitions?.value(forKeyPath: "mocks.GET") as? [String:[[String: String]]]
        XCTAssertEqual(getsMocks?.count, 1)
        
        let dataFile = getsMocks?["http://apple.com/"]?.last?["data"]
        XCTAssertNil(dataFile)
        
        let responseFile = getsMocks?["http://apple.com/"]?.last?["response"]
        XCTAssertNil(responseFile)
        
        try? FileManager.default.removeItem(atPath: recordedMocksFilePath)
        SuperMock.endRecording()
    }
    
    func test_recordDataForRequest_shouldNotRecord_whenMissingData() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        let response = sut.mockResponse(request) as? HTTPURLResponse
        SuperMock.beginRecording(bundle, mocksFile: "MocksRecording.plist")
        
        sut.recordDataForRequest(nil, httpHeaders: response?.allHeaderFields, request: request)
        
        guard let recordedMocksFilePath = sut.mockFileOutOfBundle()
            else { return XCTFail("The recoded filePath need to exist to locate the file") }
        let definitions = NSDictionary(contentsOfFile: recordedMocksFilePath)
        XCTAssertNotNil(definitions)
        let getsMocks = definitions?.value(forKeyPath: "mocks.GET") as? [String:[[String: String]]]
        XCTAssertEqual(getsMocks?.count, 1)
        
        let dataFile = getsMocks?["http://apple.com/"]?.last?["data"]
        XCTAssertNil(dataFile)
        
        let responseFile = getsMocks?["http://apple.com/"]?.last?["response"]
        XCTAssertNil(responseFile)
        
        try? FileManager.default.removeItem(atPath: recordedMocksFilePath)
        SuperMock.endRecording()
        
    }
    
    func test_recordDataForRequest_shouldRecordMultipleFiles_ForMultipleResponses() {
        let request = URLRequest(url: URL(string: "http://apple.com/")!)
        let mockedRequest = sut.mockRequest(request)
        let response = sut.mockResponse(request) as? HTTPURLResponse
        let responseData = sut.responseForMockRequest(mockedRequest)
        SuperMock.beginRecording(bundle, mocksFile: "MocksRecording.plist")
        
        sut.recordDataForRequest(responseData, httpHeaders: response?.allHeaderFields, request: request)
        sut.recordDataForRequest(responseData, httpHeaders: response?.allHeaderFields, request: request)
        
        guard let recordedMocksFilePath = sut.mockFileOutOfBundle()
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
        
        XCTAssertEqual(getsMocks?["http://apple.com/"]?.count, 2)
        
        guard let responseFile = getsMocks?["http://apple.com/"]?.last?["response"]
            else { return XCTFail("The recoded dataPath need to be exist to locate the file") }
        
        let responseUrl = mockUrl.appendingPathComponent(responseFile)
        let responseRecorded = try? Data(contentsOf: responseUrl)
        XCTAssertNotNil(responseRecorded)
        
        guard let firstDataFile = getsMocks?["http://apple.com/"]?.first?["data"]
            else { return XCTFail("The recoded dataPath need to be exist to locate the file") }
        let firstDataUrl = mockUrl.appendingPathComponent(firstDataFile)
        let firstData = try? Data(contentsOf: firstDataUrl)
        XCTAssertNotNil(firstData)
        
        guard let firstResponseFile = getsMocks?["http://apple.com/"]?.first?["response"]
            else { return XCTFail("The recoded dataPath need to be exist to locate the file") }
        
        let firstResponseUrl = mockUrl.appendingPathComponent(firstResponseFile)
        let firstResponseRecorded = try? Data(contentsOf: firstResponseUrl)
        XCTAssertNotNil(firstResponseRecorded)
        
        // Clean up
        try? FileManager.default.removeItem(atPath: recordedMocksFilePath)
        try? FileManager.default.removeItem(at: responseUrl)
        try? FileManager.default.removeItem(at: dataUrl)
        try? FileManager.default.removeItem(at: firstResponseUrl)
        try? FileManager.default.removeItem(at: firstDataUrl)
        SuperMock.endRecording()
    }
    
    

}
