//
//  SuperMockNSURLRequestExtensionTests.swift
//  SuperMock_Tests
//
//  Created by Scheggia on 21/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import SuperMock

class SuperMockNSURLRequestExtensionTests: XCTestCase {

    func test_hasMocks_returnTrue_whenMockExist() {
        SuperMockResponseHelper.bundleForMocks = Bundle(for: SuperMockNSURLRequestExtensionTests.self)
        let sut = URLRequest(url: URL(string: "http://apple.com/")!)
        
        XCTAssertTrue(sut.hasMock())
    }
    
    func test_hasMocks_returnFalse_whenMockDoesNotExist() {
        SuperMockResponseHelper.bundleForMocks = Bundle(for: SuperMockNSURLRequestExtensionTests.self)
        let sut = URLRequest(url: URL(string: "http://apple.com/Daniele")!)
        
        XCTAssertFalse(sut.hasMock())
    }

}
