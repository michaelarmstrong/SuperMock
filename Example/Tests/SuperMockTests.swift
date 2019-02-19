//
//  SuperMockTests.swift
//  SuperMock_Tests
//
//  Created by Scheggia on 09/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import SuperMock

class SuperMockTests: XCTestCase {

    let sut = SuperMock.self
    let bundle = Bundle(for: SuperMockTests.self)
    
    override func tearDown() {
        sut.endMocking()
        MockUrlProtocol.registerClassCounter = 0
        MockUrlProtocol.unregisterClassCounter = 0
        super.tearDown()
    }
    
    func test_beginMocking_registerProtocolsCorrectly() {
        let session = URLSession.shared
        let configuration = URLSessionConfiguration.default
            
        sut.beginMocking(bundle, urlProtocol: MockUrlProtocol.self, configuration: configuration, session: session)
        
        XCTAssertTrue(configuration.protocolClasses!.last === SuperMockURLProtocol.self)
        XCTAssertEqual(MockUrlProtocol.registerClassCounter, 1)
    }

    func test_beginMocking_shouldSetTheFileName() {
        let fileName = "MadeUpFile.name"
        sut.beginMocking(bundle, mocksFile: fileName)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.mocksFile, fileName)
    }
    
    func test_beginMocking_shouldSetDefaultFileName_whenNoFileNameIsSpecified() {
        sut.beginMocking(bundle)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.mocksFile, "Mocks.plist")
    }
    
    func test_beginMocking_setBundle() {
        sut.beginMocking(bundle)
        XCTAssertEqual(SuperMockResponseHelper.bundleForMocks, bundle)
    }
    
    func test_beginMocking_setFlag() {
        sut.beginMocking(bundle)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.mocking, true)
    }
    
    func test_beginRecording_registerProtocolsCorrectly() {
        let session = URLSession.shared
        let configuration = URLSessionConfiguration.default
        
        sut.beginRecording(bundle, policy: .Record, urlProtocol: MockUrlProtocol.self, configuration: configuration, session: session)
        
        XCTAssertTrue(configuration.protocolClasses!.last === SuperMockRecordingURLProtocol.self)
        XCTAssertEqual(MockUrlProtocol.registerClassCounter, 1)
    }
    
    func test_beginRecording_shouldSetTheFileName() {
        let fileName = "MadeUpFile.name"
        sut.beginRecording(bundle, mocksFile: fileName, policy: .Record)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.mocksFile, fileName)
    }
    
    func test_beginRecording_shouldSetDefaultFileName_whenNoFileNameIsSpecified() {
        sut.beginRecording(bundle)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.mocksFile, "Mocks.plist")
    }
    
    func test_beginRecording_setBundle() {
        sut.beginRecording(bundle)
        XCTAssertEqual(SuperMockResponseHelper.bundleForMocks, bundle)
    }
    
    func test_beginRecording_setFlag() {
        sut.beginRecording(bundle)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.recording, true)
    }
    
    func test_beginRecording_setCorrectPolicy() {
        sut.beginRecording(bundle, policy: .Override)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.recordPolicy, .Override)
    }
    
    func test_endRecording_shouldUnregisterProtocol() {
        sut.endRecording(urlProtocol: MockUrlProtocol.self)
        XCTAssertEqual(MockUrlProtocol.unregisterClassCounter, 1)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.recording, false)
    }
    
    func test_endmocking_shouldUnregisterProtocol() {
        sut.endMocking(urlProtocol: MockUrlProtocol.self)
        XCTAssertEqual(MockUrlProtocol.unregisterClassCounter, 1)
        XCTAssertEqual(SuperMockResponseHelper.sharedHelper.mocking, false)
    }
}

class MockUrlProtocol: URLProtocol {
    
    static var registerClassCounter = 0
    override class func registerClass(_ protocolClass: AnyClass) -> Bool {
        registerClassCounter += 1
        return true
    }
    
    static var unregisterClassCounter = 0
    override class func unregisterClass(_ protocolClass: AnyClass) {
        unregisterClassCounter += 1
    }
}
