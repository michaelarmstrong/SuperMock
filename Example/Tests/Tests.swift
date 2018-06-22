import UIKit
import XCTest
@testable import SuperMock

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
       // SuperMock.beginMocking(Bundle(for: AppDelegate.self))
    }
    
    override func tearDown() {
        super.tearDown()
        
       // SuperMock.endMocking()
    }
    
    func testValidGETRequestWithMockReturnsExpectedMockedData() {
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        var realRequest = URLRequest(url: url)
        realRequest.httpMethod = "GET"
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        let bundle = Bundle(for: AppDelegate.self)
        let pathToExpectedData = bundle.path(forResource: "sample", ofType: "html")!

        let expectedData = try! NSData(contentsOfFile: pathToExpectedData) as Data
        let returnedData = responseHelper.responseForMockRequest(mockRequest)
        
        XCTAssertEqual(expectedData, returnedData, "Expected data not received for mock.")

    }
    
    func testValidPOSTRequestWithMockReturnsExpectedMockedData() {
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        var realRequest = URLRequest(url: url)
        realRequest.httpMethod = "POST"
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        let bundle = Bundle(for: AppDelegate.self)
        let pathToExpectedData = bundle.path(forResource: "samplePOST", ofType: "html")!
        
        let expectedData = try! NSData(contentsOfFile: pathToExpectedData) as Data
        let returnedData = responseHelper.responseForMockRequest(mockRequest)
        
        XCTAssertEqual(expectedData, returnedData, "Expected data not received for mock.")
        
    }
    
    func testValidRequestWithNoMockReturnsOriginalRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://nomockavailable.com")!
        let realRequest = URLRequest(url: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssert(realRequest == mockRequest, "Original request should be returned when no mock is available.")
    }
    
    func testValidRequestWithMockReturnsDifferentRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        let realRequest = URLRequest(url: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssert(realRequest != mockRequest, "Different request should be returned when a mock is available.")
    }
    
    func testValidRequestWithMockReturnsFileURLRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = URL(string: "http://mike.kz/")!
        let realRequest = URLRequest(url: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssertNotNil(mockRequest.url?.isFileURL, "fileURL mocked request should be returned when a mock is available.")
    }
    
    func testRecordDataAsMock() {
        
        let url = URL(string: "http://mike.kz/Daniele")!
        let realRequest = URLRequest(url: url)
        
        let responseString = "Something to put into the response field"
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        let expectedData = responseString.data(using: .utf8)
        
        responseHelper.recordDataForRequest(expectedData, request: realRequest)
        
        let mockRequest = responseHelper.mockRequest(realRequest)
        let returnedData = responseHelper.responseForMockRequest(mockRequest)
        
        XCTAssertEqual(expectedData, returnedData, "Expected data not received for mock.")
        
    }
}
