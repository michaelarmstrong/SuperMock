//
//  SuperMock_ExampleUITests.swift
//  SuperMock_ExampleUITests
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import XCTest

class SuperMock_ExampleUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        app.terminate()
    }
    
    func testButtonSetOnViewControllerLoadFromJSON_SUPERMOCKEXAMPLE() {

        // Naive UI test to demonstrate how the mock is used here to validate. Should really be testing the button value.
        
        let buttonOne = app.buttons.matching(identifier: "testableButtonOne").element
        let existsPredicate = NSPredicate(format: "exists == 1")
        
        expectation(for: existsPredicate, evaluatedWith: buttonOne, handler: nil)
        waitForExpectations(timeout: 3.0, handler: nil)
        
        let buttonOneText = buttonOne.value as! String
        XCTAssert(buttonOneText == "MOCKTITLE1","Button doesn't match expected value from mock")
    }
    
}
