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
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = documentsDirectory?.stringByAppendingString("/Mocks.plist")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(filePath!)} catch{}
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
    
    func testMockResponseReturnNilIfNoHeadersFile() {
        
        let url = NSURL(string: "http://mike.kz/Daniele")!
        let realRequest = NSURLRequest(URL: url)
        
        XCTAssertNil(SuperMockResponseHelper.sharedHelper.mockResponse(realRequest), "The response should be nil because does not exist file")
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = documentsDirectory?.stringByAppendingString("/__mike.kz_Daniele")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(filePath!)} catch{}
    }
    
    func testMockResponseReturnedMockedHTTPResponse() {
        
        let url = NSURL(string: "http://mike.kz/")!
        let realRequest = NSMutableURLRequest(URL: url)
        
        XCTAssertNotNil(SuperMockResponseHelper.sharedHelper.mockResponse(realRequest), "The response should not be nil because the file exist")
    }
    
    func testRecordResponseHeadersForRequestRecordFile() {
        
        let url = NSURL(string: "http://mike.kz/RecordedResponseHeaders")!
        let realRequest = NSURLRequest(URL: url)
        let response = NSHTTPURLResponse(URL: url, statusCode: 200, HTTPVersion: nil, headerFields: realRequest.allHTTPHeaderFields)
        
        SuperMockResponseHelper.sharedHelper.recordResponseHeadersForRequest(["Connection":"Keep-Alive"], request: realRequest, response: response!)
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = documentsDirectory?.stringByAppendingString("/__mike.kz_RecordedResponseHeaders")
        
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(filePath!), "Headers file need to be created")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(filePath!)} catch{}
    }
    
}

// MARK: Test File Helper Class
extension Tests {
    
    func testMockedFilePathReturnFilePathForExistingFile() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = documentsDirectory?.stringByAppendingString("/__www.danieleforlani.net_c1d94.txt")
        let string = "Something to save as data"
        
        try! string.writeToFile(filePath!, atomically: true, encoding: NSUTF8StringEncoding)
        
        SuperMock.beginRecording(NSBundle(forClass: AppDelegate.self), policy: .Override)
        
        XCTAssertTrue(FileHelper.mockedResponseFilePath(NSURL(string: "http://www.danieleforlani.net/c1d94")!) == filePath!, "Expected the right path for existing file")
        SuperMock.endRecording()
        
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(filePath!), "Plist file need to be copied if does exist in bundle")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(filePath!)} catch{}
    }
    
    func testMockedFilePathReturnFilePathHeaderForExistingFile() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let filePath = documentsDirectory?.stringByAppendingString("/__www.danieleforlani.net_c1d94")
        let string = "Something to save as data"
        
        try! string.writeToFile(filePath!, atomically: true, encoding: NSUTF8StringEncoding)
        
        
        XCTAssertTrue(FileHelper.mockedResponseHeadersFilePath(NSURL(string: "http://www.danieleforlani.net/c1d94")!) == filePath!, "Expected the right path for existing file")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(filePath!)} catch{}
    }
    
    func testMockFileOutOfBundle_NoMockFile_CreateMockFile() {
        
        SuperMockResponseHelper.sharedHelper.mocksFile = "NewMock"
        let _ = FileHelper.mockFileOutOfBundle()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let mockPath =  documentsDirectory?.stringByAppendingString("/\(SuperMockResponseHelper.sharedHelper.mocksFile).plist")
        
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(mockPath!), "Plist file need to be created if does not exist")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(mockPath!)} catch{}
    }
    
    func testMockFileOutOfBundle_CopyMockFile() {
        
        SuperMockResponseHelper.sharedHelper.mocksFile = "Mock"
        let _ = FileHelper.mockFileOutOfBundle()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let mockPath =  documentsDirectory?.stringByAppendingString("/\(SuperMockResponseHelper.sharedHelper.mocksFile).plist")
        
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(mockPath!), "Plist file need to be copied if does exist in bundle")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(mockPath!)} catch{}
    }
    
    func testMockFileOutOfBundle_Exist_ReturnCorrectpath() {
        
        SuperMockResponseHelper.sharedHelper.mocksFile = "FakeMock"
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        let mockPath =  documentsDirectory?.stringByAppendingString("/\(SuperMockResponseHelper.sharedHelper.mocksFile).plist")
        
        let string = "Fake Mock File"
        
        try! string.writeToFile(mockPath!, atomically: true, encoding: NSUTF8StringEncoding)
        
        let filePath = FileHelper.mockFileOutOfBundle()
        
        XCTAssertTrue(filePath == mockPath, "Plist file need to be copied if does exist in bundle")
        
        do {try NSFileManager.defaultManager().removeItemAtPath(mockPath!)} catch{}
    }
    
    
}
