//
//  SuperMockResponseHelper.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation


public enum RecordPolicy : String {
    case Override = "Override"
    case Record = "Record"
}

class SuperMockResponseHelper: NSObject {
    
    static let sharedHelper = SuperMockResponseHelper()
    var mocking = false
    private let dataKey = "data"
    private let responseKey = "response"
    
    class var bundleForMocks : NSBundle? {
        set {
        sharedHelper.bundle = newValue
        }
        get {
            return sharedHelper.bundle
        }
    }
    
    class var mocksFileName: String? {
        set {
        if let fileName = newValue, let url = NSURL(string: fileName) {
        sharedHelper.mocksFile = url.URLByDeletingPathExtension!.absoluteString
        return
        }
        sharedHelper.mocksFile = "Mocks"
        }
        get {
            return sharedHelper.mocksFile
        }
    }
    
    let fileManager = NSFileManager.defaultManager()
    var mocksFile: String = "Mocks"
    var bundle : NSBundle? {
        didSet {
            loadDefinitions()
        }
    }
    
    /**
     Automatically populated by Mocks.plist. A dictionary containing mocks loaded in from Mocks.plist, purposely not made private as can be modified at runtime to
     provide alternative mocks for URL's on subsequent requests. Better support for this feature is coming in the future.
     */
    var mocks = Dictionary<String,AnyObject>()
    /**
     Automatically populated by Mocks.plist. Dictionary containing all the associated and supported mime.types for mocks. Defaults to text/plain if none provided.
     */
    var mimes = Dictionary<String,String>()
    
    enum RequestMethod : String {
        case POST = "POST"
        case GET = "GET"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    var recordPolicy = RecordPolicy.Record
    var recording = false
    
    func loadDefinitions() {
        
        guard let bundle = bundle else {
            fatalError("You must provide a bundle via NSBundle(class:) or NSBundle.mainBundle() before continuing.")
        }
        
        if let definitionsPath = bundle.pathForResource(mocksFile, ofType: "plist"),
            let definitions = NSDictionary(contentsOfFile: definitionsPath) as? Dictionary<String,AnyObject>,
            let mocks = definitions["mocks"] as? Dictionary<String,AnyObject>,
            let mimes = definitions["mimes"] as? Dictionary<String,String> {
                self.mocks = mocks
                self.mimes = mimes
        }
    }
    
    /**
     Public method to construct and return (when needed) mock NSURLRequest objects.
     
     - parameter request: the original NSURLRequest to provide a mock for.
     
     - returns: NSURLRequest with manipulated resource identifier.
     */
    func mockRequest(request: NSURLRequest) -> NSURLRequest {
        guard let url = request.URL else {
            return request
        }
        let requestMethod = RequestMethod(rawValue: request.HTTPMethod!)!
        
        let mockURL = mockURLForRequestURL(url, requestMethod: requestMethod, mocks: mocks)
        if mockURL == request.URL {
            return request
        }
        
        let mocked = request.mutableCopy() as! NSMutableURLRequest
        mocked.URL = mockURL
        mocked.setValue("true", forHTTPHeaderField: "X-SUPERMOCK-MOCKREQUEST")
        let injectableRequest = mocked.copy() as! NSURLRequest
        
        return injectableRequest
        
    }
    
    private func mockURLForRequestURL(url: NSURL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>) -> NSURL? {
        
        return mockURLForRequestURL(url, requestMethod: requestMethod, mocks: mocks, isData: true)
    }
    
    private func mockURLForRequestRestponseURL(url: NSURL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>) -> NSURL? {
        
        return mockURLForRequestURL(url, requestMethod: requestMethod, mocks: mocks, isData: false)
    }
    
    private func mockURLForRequestURL(url: NSURL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>, isData: Bool) -> NSURL? {
        
        guard let definitionsForMethod = mocks[requestMethod.rawValue] as? Dictionary<String,AnyObject> else {
            fatalError("Couldn't find definitions for request: \(requestMethod) make sure to create a node for it in the plist and include your plist file in the correct target")
        }
        
        if let responseFiles = definitionsForMethod[url.absoluteString] as? [String:String] {
            
            if let responseFile = responseFiles[dataKey], let responsePath = bundle?.pathForResource(responseFile, ofType: "") where isData {
                return NSURL(fileURLWithPath: responsePath)
            }
            
            if let responseFile = responseFiles[responseKey], let responsePath = bundle?.pathForResource(responseFile, ofType: "") where !isData {
                return NSURL(fileURLWithPath: responsePath)
            }
            
        } else {
            
            if let responsePath = FileHelper.mockedResponseHeadersFilePath(url) where !isData && NSFileManager.defaultManager().fileExistsAtPath(responsePath) {
                return NSURL(fileURLWithPath: responsePath)
            }
            
            if let responsePath = FileHelper.mockedResponseFilePath(url) where isData && NSFileManager.defaultManager().fileExistsAtPath(responsePath){
                return NSURL(fileURLWithPath: responsePath)
            }
        }
        return url
    }
    
    /**
     Public method to return data for associated mock requests.
     
     Will fail with a fatalError if called for items that are not represented on the local filesystem.
     
     - parameter request: the mock NSURLRequest object.
     
     - returns: NSData containing the mock response.
     */
    func responseForMockRequest(request: NSURLRequest!) -> NSData? {
        
        if request.URL?.fileURL == false {
            fatalError("You should only call this on mocked URLs")
        }
        
        return mockedResponse(request.URL!)
    }
    
    /**
     Public method to return associated mimeTypes from the Mocks.plist configuration.
     
     Always returns a value. Defaults to "text/plain"
     
     - parameter url: Any NSURL object for which a mime.type is to be obtained.
     
     - returns: String containing RFC 6838 compliant mime.type
     */
    func mimeType(url: NSURL!) -> String {
        
        if let pathExtension = url.pathExtension where pathExtension.characters.count > 0 {
            if let mime = mimes[pathExtension] {
                return mime
            }
            return ""
        }
        return "text/plain"
    }
    
    private func mockedResponse(url: NSURL) -> NSData? {
        if let data = NSData(contentsOfURL: url) {
            return data
        }
        return nil
    }
    
    /**
     Record the data and save it in the mock file in the documents directory. The data is saved in a file with extension based on the mime of the request, the file name is unique dependent on the url of the request. The Mock file contains the request and the file name for the request data response.
     
     :param: data    data to save into the file
     :param: request Rapresent the request called for obtain the data
     */
    func recordDataForRequest(data: NSData?, request: NSURLRequest) {
        
        guard let url = request.URL else {
            return
        }
        recordResponseForRequest(data, request: request, responseFile: FileHelper.mockedResponseFileName(url), responsePath: FileHelper.mockedResponseFilePath(url), key: dataKey)
    }
    
    private func recordResponseHeadersDataForRequest(data: NSData?, request: NSURLRequest) {
        
        guard let url = request.URL else {
            return
        }
        recordResponseForRequest(data, request: request, responseFile: FileHelper.mockedResponseHeadersFileName(url), responsePath: FileHelper.mockedResponseHeadersFilePath(url), key: responseKey)
    }
    
    private func recordResponseForRequest(data: NSData?, request: NSURLRequest, responseFile: String?, responsePath: String?, key: String) {
        
        guard let definitionsPath = FileHelper.mockFileOutOfBundle(),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath),
            let absoluteString = request.URL?.absoluteString,
            let httpMethod = request.HTTPMethod,
            let responseFile = responseFile,
            let responsePath = responsePath,
            let data = data else {
                return
        }
        data.writeToFile(responsePath, atomically: true)
        let keyPath = "mocks.\(httpMethod)"
        if let mocks = definitions.valueForKeyPath(keyPath) as? NSMutableDictionary {
            
            if let _ = mocks["\(absoluteString)"] where recordPolicy == .Record {
                return
            }
            
            if let mock = mocks["\(absoluteString)"] as? NSMutableDictionary {
                mock[key] = responseFile
            } else {
                mocks["\(absoluteString)"] = [key:responseFile]
            }
            
            if !definitions.writeToFile(definitionsPath, atomically: true) {
                print("Error writning the file, permission problems?")
            }
        }
    }
    
    /**
     Return the mock HTTP Response based on the saved HTTP Headers into the specific file, it create the response with the previous Response header
     
     - parameter request: Represent the request (orginal not mocked) callled for obtain the data
     
     - returns: Mocked response set with the HTTPHEaders of the response recorded
     */
    func mockResponse(request: NSURLRequest) -> NSURLResponse? {
        
        let requestMethod = RequestMethod(rawValue: request.HTTPMethod!)!
        
        guard let mockedHeaderFields = mockedHeaderFields(request.URL!, requestMethod: requestMethod, mocks: mocks) else {
            return nil
        }
        var statusCode = 200
        if let statusString = mockedHeaderFields["status"], let responseStatus = Int(statusString) {
            statusCode = responseStatus
        }
        
        let mockedResponse = NSHTTPURLResponse(URL: request.URL!, statusCode: statusCode, HTTPVersion: nil, headerFields: mockedHeaderFields )
        
        return mockedResponse
    }
    
    /**
     Record the headers Dictionary of a specific Response, in this way if the code that use the mock check the Response headers it can have them recorded as well. It save in the dictionary the Response status code as well
     
     - parameter headers:  Dictionary of the headers to save, obtained from the NSHTTPURLResponse.allHeaderFileds
     - parameter request:  Represent the request (orginal not mocked) callled for obtain the data
     - parameter response: The current response, it is used to store the status code
     */
    func recordResponseHeadersForRequest(headers:[NSObject:AnyObject], request: NSURLRequest, response: NSHTTPURLResponse) {
        
        var headersModified : [NSObject:AnyObject] = headers
        headersModified["status"] = "\(response.statusCode)"
        
        do { let data = try NSPropertyListSerialization.dataWithPropertyList(headersModified, format: NSPropertyListFormat.XMLFormat_v1_0, options: NSPropertyListWriteOptions.allZeros)
            recordResponseHeadersDataForRequest(data, request: request)
        } catch {
            return
        }
        
    }
    
    private func mockedHeaderFields(url: NSURL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>)->[String : String]? {
        
        guard let mockedHeaderFieldsURL = mockURLForRequestRestponseURL(url, requestMethod: requestMethod, mocks: mocks) where mockedHeaderFieldsURL != url else {
            return nil
        }
        guard let mockedHeaderFields = NSDictionary(contentsOfURL: mockedHeaderFieldsURL) as? [String : String] else {
            return nil
        }
        return mockedHeaderFields
    }
}

class FileHelper {
    
    private static let maxFileLegth = 70
}

//MARK: public methods
extension FileHelper {
    
    class func mockedResponseFilePath(url: NSURL)->String? {
        
        return FileHelper.mockedFilePath(FileHelper.mockedResponseFileName(url))
    }
    
    class func mockedResponseHeadersFilePath(url: NSURL)->String? {
        
        return FileHelper.mockedFilePath(mockedResponseHeadersFileName(url))
    }
    
    class func mockedResponseFileName(url: NSURL)->String {
        
        return  FileHelper.mockedResponseFileName(url, isData: true)
    }
    
    class func mockedResponseHeadersFileName(url: NSURL)->String {
        
        return  FileHelper.mockedResponseFileName(url, isData: false)
    }
    
    class func mockFileOutOfBundle()->String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        
        guard let mockPath =  documentsDirectory?.stringByAppendingString("/\(SuperMockResponseHelper.sharedHelper.mocksFile).plist"),
            let bundle = SuperMockResponseHelper.sharedHelper.bundle else {
                return nil
        }
        guard !NSFileManager.defaultManager().fileExistsAtPath(mockPath) else {
            return mockPath
        }
        
        var mockDictionary = NSDictionary(dictionary:["mimes":["htm":"text/html","html":"text/html","json":"application/json"],"mocks":["DELETE":["http://exampleUrl":["data":"","resonse":""]],"POST":["http://exampleUrl":["data":"","resonse":""]],"PUT":["http://exampleUrl":["data":"","resonse":""]],"GET":["http://exampleUrl":["data":"","resonse":""]]]])
        
        if let definitionsPath = bundle.pathForResource(SuperMockResponseHelper.sharedHelper.mocksFile, ofType: "plist"),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath) {
                mockDictionary = definitions
        }
        
        do {
            let data = try NSPropertyListSerialization.dataWithPropertyList(mockDictionary, format: NSPropertyListFormat.XMLFormat_v1_0, options: NSPropertyListWriteOptions.allZeros)
            
            if !data.writeToFile(mockPath, atomically: true) {
                return nil
            }
        } catch {
            return nil
        }
        
        return mockPath
    }
}

//MARK: private methods
extension FileHelper {
    
    private class func fileType(mimeType: String) -> String {
        
        switch (mimeType) {
        case "text/plain":
            return "txt"
        case "text/html":
            return "html"
        case "application/json":
            return "json"
        case "":
            return ""
        default:
            return "txt"
        }
    }
    
    private class func mockedFilePath(fileName: String)->String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        
        guard let filePath = documentsDirectory?.stringByAppendingString("/\(fileName)") else {
            return nil
        }
        
        print("Mocked response in: \(filePath)")
        return filePath
    }
    
    private class func mockedResponseFileName(url: NSURL, isData:Bool)->String {
        
        guard var urlString = url.absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) else {
            fatalError("You must provide a request with a valid URL")
        }
        
        urlString = urlString.stringByReplacingOccurrencesOfString("%2F", withString: "_")
        
        urlString = urlString.stringByReplacingOccurrencesOfString("http%3A", withString: "")
        
        
        let urlStringLengh = urlString.characters.count
        let fromIndex = (urlStringLengh > maxFileLegth) ?maxFileLegth : urlStringLengh
        let fileName = urlString.substringFromIndex(urlString.endIndex.advancedBy(-fromIndex))
        let fileExtension = FileHelper.fileType(SuperMockResponseHelper.sharedHelper.mimeType(url))
        
        if SuperMockResponseHelper.sharedHelper.recording {
            
            if isData {
                if fileExtension.characters.count > 0 {
                    return  fileName + "." + fileExtension
                } else {
                    return fileName
                }
            }
            return  fileName + ".headers"
        }
        return  fileName
    }
    
}

