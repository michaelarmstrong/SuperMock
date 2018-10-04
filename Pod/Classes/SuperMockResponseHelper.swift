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
    fileprivate let maxFileLegth = 30
    var mocking = false
    fileprivate let dataKey = "data"
    fileprivate let responseKey = "response"
    
    class var bundleForMocks : Bundle? {
        set {
            sharedHelper.bundle = newValue
        }
        get {
            return sharedHelper.bundle
        }
    }
    
    let fileManager = FileManager.default
    var bundle : Bundle? {
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
        
        if let definitionsPath = bundle.path(forResource: "Mocks", ofType: "plist"),
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
    func mockRequest(_ request: URLRequest) -> URLRequest {
        
        let requestMethod = RequestMethod(rawValue: request.httpMethod!)!
        
        let mockURL = mockURLForRequestURL(request.url!, requestMethod: requestMethod, mocks: mocks)
        if mockURL == request.url {
            return request
        }
        
        let mocked = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        mocked.url = mockURL
        mocked.setValue("true", forHTTPHeaderField: "X-SUPERMOCK-MOCKREQUEST")
        let injectableRequest = mocked.copy() as! URLRequest
        
        return injectableRequest

    }
    
    fileprivate func mockURLForRequestURL(_ url: URL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>) -> URL? {
        
        return mockURLForRequestURL(url, requestMethod: requestMethod, mocks: mocks, isData: true)
    }
    
    fileprivate func mockURLForRequestRestponseURL(_ url: URL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>) -> URL? {
        
        return mockURLForRequestURL(url, requestMethod: requestMethod, mocks: mocks, isData: false)
    }
    
    fileprivate func mockURLForRequestURL(_ url: URL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>, isData: Bool) -> URL? {
        
        guard let definitionsForMethod = mocks[requestMethod.rawValue] as? Dictionary<String,AnyObject> else {
            fatalError("Couldn't find definitions for request: \(requestMethod) make sure to create a node for it in the plist")
        }
        
        if let responseFiles = definitionsForMethod[url.absoluteString] as? [String:String] {
            
            if let responseFile = responseFiles[dataKey], let responsePath = bundle?.path(forResource: responseFile, ofType: ""), isData {
                return URL(fileURLWithPath: responsePath)
            }
            
            if let responseFile = responseFiles[responseKey], let responsePath = bundle?.path(forResource: responseFile, ofType: ""), !isData {
                return URL(fileURLWithPath: responsePath)
            }
            
        } else {
            
            if let responsePath = mockedResponseHeadersFilePath(url), !isData && FileManager.default.fileExists(atPath: responsePath) {
                return URL(fileURLWithPath: responsePath)
            }
            
            if let responsePath = mockedResponseFilePath(url), isData && FileManager.default.fileExists(atPath: responsePath){
                return URL(fileURLWithPath: responsePath)
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
    func responseForMockRequest(_ request: URLRequest!) -> Data? {

        if request.url?.isFileURL == false {
           return nil// fatalError("You should only call this on mocked URLs")
        }
        
        return mockedResponse(request.url!)
    }
    
    /**
     Public method to return associated mimeTypes from the Mocks.plist configuration.
  
     Always returns a value. Defaults to "text/plain"
     
     - parameter url: Any NSURL object for which a mime.type is to be obtained.
     
     - returns: String containing RFC 6838 compliant mime.type
     */
    func mimeType(_ url: URL!) -> String {
        let pathExtension = url.pathExtension
        if let mime = mimes[pathExtension] {
            return mime
        }
        return "text/plain"
    }

    fileprivate func mockedResponse(_ url: URL) -> Data? {
        if let data = try? Data(contentsOf: url) {
            return data
        }
        return nil
    }
    
    /**
     Record the data and save it in the mock file in the documents directory. The data is saved in a file with extension based on the mime of the request, the file name is unique dependent on the url of the request. The Mock file contains the request and the file name for the request data response.
     
     :param: data    data to save into the file
     :param: request Rapresent the request called for obtain the data
     */
    func recordDataForRequest(_ data: Data?, request: URLRequest) {
        
        guard let url = request.url else {
            return
        }
        recordResponseForRequest(data, request: request, responseFile: mockedResponseFileName(url), responsePath: mockedResponseFilePath(url), key: dataKey)
    }
    
    fileprivate func recordResponseHeadersDataForRequest(_ data: Data?, request: URLRequest) {
        
        guard let url = request.url else {
            return
        }
        recordResponseForRequest(data, request: request, responseFile: mockedResponseHeadersFileName(url), responsePath: mockedResponseHeadersFilePath(url), key: responseKey)
    }
    
    fileprivate func recordResponseForRequest(_ data: Data?, request: URLRequest, responseFile: String?, responsePath: String?, key: String) {
        
        guard let definitionsPath = mockFileOutOfBundle(),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath),
            let absoluteString = request.url?.absoluteString,
            let httpMethod = request.httpMethod,
            let responseFile = responseFile,
            let responsePath = responsePath,
            let data = data else {
                return
        }
        try? data.write(to: URL(fileURLWithPath: responsePath), options: [.atomic])
        let keyPath = "mocks.\(httpMethod)"
        if let mocks = definitions.value(forKeyPath: keyPath) as? NSMutableDictionary {
            
            if let _ = mocks["\(absoluteString)"], recordPolicy == .Record {
                return
            }
            
            if let mock = mocks["\(absoluteString)"] as? NSMutableDictionary {
                mock[key] = responseFile
            } else {
                mocks["\(absoluteString)"] = [key:responseFile]
            }
            
            if !definitions.write(toFile: definitionsPath, atomically: true) {
                print("Error writning the file, permission problems?")
            }
        }
    }
    
    /**
     Return the mock HTTP Response based on the saved HTTP Headers into the specific file, it create the response with the previous Response header
     
     - parameter request: Represent the request (orginal not mocked) callled for obtain the data
     
     - returns: Mocked response set with the HTTPHEaders of the response recorded
     */
    func mockResponse(_ request: URLRequest) -> URLResponse? {
        
        let requestMethod = RequestMethod(rawValue: request.httpMethod!)!
        
        guard let mockedHeaderFields = mockedHeaderFields(request.url!, requestMethod: requestMethod, mocks: mocks) else {
            return nil
        }
        var statusCode = 200
        if let statusString = mockedHeaderFields["status"], let responseStatus = Int(statusString) {
            statusCode = responseStatus
        }
        
        let mockedResponse = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: mockedHeaderFields )
        
        return mockedResponse
    }
    
    /**
     Record the headers Dictionary of a specific Response, in this way if the code that use the mock check the Response headers it can have them recorded as well. It save in the dictionary the Response status code as well
     
     - parameter headers:  Dictionary of the headers to save, obtained from the NSHTTPURLResponse.allHeaderFileds
     - parameter request:  Represent the request (orginal not mocked) callled for obtain the data
     - parameter response: The current response, it is used to store the status code
     */
    func recordResponseHeadersForRequest(_ headers:[AnyHashable: Any], request: URLRequest, response: HTTPURLResponse) {
        
        var headersModified : [AnyHashable: Any] = headers
        headersModified["status"] = "\(response.statusCode)"
        
        recordResponseHeadersDataForRequest(NSKeyedArchiver.archivedData(withRootObject: headersModified), request: request)
    }
    
    fileprivate func mockedHeaderFields(_ url: URL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>)->[String : String]? {
        
        guard let mockedHeaderFieldsURL = mockURLForRequestRestponseURL(url, requestMethod: requestMethod, mocks: mocks), mockedHeaderFieldsURL != url else {
            return nil
        }
        guard let mockedHeaderFieldData = try? Data(contentsOf: mockedHeaderFieldsURL) else {
            return nil
        }
        guard let mockedHeaderFields = NSKeyedUnarchiver.unarchiveObject(with: mockedHeaderFieldData) as? [String : String] else {
            return nil
        }
        return mockedHeaderFields
    }
}

// MARK: File extension
extension SuperMockResponseHelper {
    
    fileprivate func fileType(_ mimeType: String) -> String {
        
        switch (mimeType) {
        case "text/plain":
            return "txt"
        case "text/html":
            return "html"
        case "application/json":
            return "json"
        default:
            return "txt"
        }
    }
    
    fileprivate func mockedResponseFilePath(_ url: URL)->String? {
        
        return mockedFilePath(mockedResponseFileName(url))
    }
    
    fileprivate func mockedResponseHeadersFilePath(_ url: URL)->String? {
        
        return mockedFilePath(mockedResponseHeadersFileName(url))
    }
    
    fileprivate func mockedFilePath(_ fileName: String?)->String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        
        guard let fileName =  fileName else {
                return nil
        }
        let filePath = (documentsDirectory)! + "/\(fileName)"
        print("Mocked response recorded in: \(filePath)")
        return filePath
    }
    
    fileprivate func mockedResponseFileName(_ url: URL)->String? {
        
        return  mockedResponseFileName(url, isData: true)
    }
    
    fileprivate func mockedResponseHeadersFileName(_ url: URL)->String? {
        
        return  mockedResponseFileName(url, isData: false)
    }
    
    fileprivate func mockedResponseFileName(_ url: URL, isData:Bool)->String? {
        
        var urlString = url.absoluteString
        let urlStringLengh = urlString.count
        let fromIndex = (urlStringLengh > maxFileLegth) ?maxFileLegth : urlStringLengh
        urlString = urlString.suffix(fromIndex).debugDescription
        guard let fileName = urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            fatalError("You must provide a request with a valid URL")
        }
        if isData && recording {
            return  fileName + "DATA." + fileType(mimeType(url))
        }
        return  fileName + "." + fileType(mimeType(url))
    }
    
    fileprivate func mockFileOutOfBundle()->String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        guard let bundle = bundle else {
                return nil
        }
        let mockPath = (documentsDirectory)! + "/Mocks.plist"
        
        if !FileManager.default.fileExists(atPath: mockPath),
            let definitionsPath = bundle.path(forResource: "Mocks", ofType: "plist"),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath) {
                definitions.write(toFile: mockPath, atomically: true)
        } else {
            let mockDictionary = NSDictionary(dictionary:["mimes":[["htm":"text/html"],["html":"text/html"],["json":"application/json"]],["mocks"]:[["DELETE":[:]],["POST":[:]],["PUT":[:]],["GET":[:]]]])
            mockDictionary.write(toFile: mockPath, atomically: true)
        }
        
        return mockPath
    }
}

