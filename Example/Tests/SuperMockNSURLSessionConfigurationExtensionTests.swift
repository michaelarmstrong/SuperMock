//
//  SuperMockNSURLSessionConfigurationExtensionTests.swift
//  SuperMock_Tests
//
//  Created by Scheggia on 21/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import SuperMock

class SuperMockNSURLSessionConfigurationExtensionTests: XCTestCase {

    func test_addProtocols_appendRecordingProtocols_whenRecording() {
        SuperMock.beginRecording(Bundle(for: SuperMockNSURLSessionConfigurationExtensionTests.self))
        let sut = URLSessionConfiguration.background(withIdentifier: "")
        sut.addProtocols()
        
        XCTAssertTrue(sut.protocolClasses?.first === SuperMockRecordingURLProtocol.self)
        SuperMock.endRecording()
    }
    
    func test_addProtocols_appendMockingProtocols_whenRecording() {
        SuperMock.beginMocking(Bundle(for: SuperMockNSURLSessionConfigurationExtensionTests.self))
        let sut = URLSessionConfiguration.background(withIdentifier: "")
        sut.addProtocols()

        XCTAssertTrue(verify(protocols: sut.protocolClasses, contains: SuperMockURLProtocol.self), "SuperMockUrlProtocol is not the first protocol in \(String(describing: sut.protocolClasses))")
        SuperMock.endMocking()
    }

    private func verify(protocols:[AnyClass]?, contains aClass: AnyClass) -> Bool {
        return protocols?.contains(where: { classProtocol -> Bool in
           return classProtocol === aClass
        }) ?? false
    }
}
