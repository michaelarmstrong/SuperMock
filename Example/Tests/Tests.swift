import UIKit
import XCTest
@testable import SuperMock

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        SuperMock.beginMocking(NSBundle(forClass: AppDelegate.self))
    }
    
    override func tearDown() {
        super.tearDown()
        
        SuperMock.endMocking()
    }
    
    func testValidGETRequestWithMockReturnsExpectedMockedData() {
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = NSURL(string: "http://mike.kz/")!
        let realRequest = NSMutableURLRequest(URL: url)
        realRequest.HTTPMethod = "GET"
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        let bundle = NSBundle(forClass: AppDelegate.self)
        let pathToExpectedData = bundle.pathForResource("sample", ofType: "html")!

        let expectedData = NSData(contentsOfFile: pathToExpectedData)
        let returnedData = responseHelper.responseForMockRequest(mockRequest)
        
        XCTAssert(expectedData == returnedData, "Expected data not received for mock.")

    }
    
    func testValidPOSTRequestWithMockReturnsExpectedMockedData() {
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = NSURL(string: "http://mike.kz/")!
        let realRequest = NSMutableURLRequest(URL: url)
        realRequest.HTTPMethod = "POST"
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        let bundle = NSBundle(forClass: AppDelegate.self)
        let pathToExpectedData = bundle.pathForResource("samplePOST", ofType: "html")!
        
        let expectedData = NSData(contentsOfFile: pathToExpectedData)
        let returnedData = responseHelper.responseForMockRequest(mockRequest)
        
        XCTAssert(expectedData == returnedData, "Expected data not received for mock.")
        
    }
    
    func testValidRequestWithNoMockReturnsOriginalRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = NSURL(string: "http://nomockavailable.com")!
        let realRequest = NSURLRequest(URL: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssert(realRequest == mockRequest, "Original request should be returned when no mock is available.")
    }
    
    func testValidRequestWithMockReturnsDifferentRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = NSURL(string: "http://mike.kz/")!
        let realRequest = NSURLRequest(URL: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssert(realRequest != mockRequest, "Different request should be returned when a mock is available.")
    }
    
    func testValidRequestWithMockReturnsFileURLRequest() {
        let responseHelper = SuperMockResponseHelper.sharedHelper
        
        let url = NSURL(string: "http://mike.kz/")!
        let realRequest = NSURLRequest(URL: url)
        let mockRequest = responseHelper.mockRequest(realRequest)
        
        XCTAssert(mockRequest.URL!.fileURL, "fileURL mocked request should be returned when a mock is available.")
    }
    
    func testRecordDataAsMock() {
        
        let url = NSURL(string: "http://mike.kz/Daniele")!
        let realRequest = NSURLRequest(URL: url)
        
        let responseString = "Something to put into the response field"
        
        let responseHelper = SuperMockResponseHelper.sharedHelper
        let expectedData = responseString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        responseHelper.recordDataForRequest(expectedData, request: realRequest)
        
        let mockRequest = responseHelper.mockRequest(realRequest)
        let returnedData = responseHelper.responseForMockRequest(mockRequest)
        
        XCTAssert(expectedData == returnedData, "Expected data not received for mock.")
        
    }

}
