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
    var mocksFile = "Mocks.plist"
    fileprivate let dataKey = "data"
    fileprivate let responseKey = "response"
    fileprivate var fileslist: [String] = []
    
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
    var mocks: NSMutableDictionary = [:]
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
        
        if let definitionsPath = bundle.path(forResource: mocksFile, ofType: nil),
            let definitions = NSDictionary(contentsOfFile: definitionsPath),
        let mocks = definitions["mocks"] as? [String: Any],
            let mimes = definitions["mimes"] as? Dictionary<String,String> {
            self.mocks = NSMutableDictionary(dictionary: mocks)
            self.mimes = mimes
        }
    }
    
    /**
     Public method to construct and return (when needed) mock NSURLRequest objects.
     
     - parameter request: the original NSURLRequest to provide a mock for.
     
     - returns: NSURLRequest with manipulated resource identifier.
     */
    func mockRequest(_ request: URLRequest) -> URLRequest {
        
        let method = request.httpMethod ?? "GET"
        let requestMethod = RequestMethod(rawValue: method) ?? .GET

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
    
    fileprivate func mockURLForRequestURL(_ url: URL, requestMethod: RequestMethod, mocks: NSMutableDictionary) -> URL? {
        
        return mockURLForRequestURL(url, requestMethod: requestMethod, mocks: mocks, isData: true)
    }
    
    fileprivate func mockURLForRequestRestponseURL(_ url: URL, requestMethod: RequestMethod, mocks: NSMutableDictionary) -> URL? {
        
        return mockURLForRequestURL(url, requestMethod: requestMethod, mocks: mocks, isData: false)
    }
    
    fileprivate func mockURLForRequestURL(_ url: URL, requestMethod: RequestMethod, mocks: NSMutableDictionary, isData: Bool) -> URL? {
        
        guard let definitionsForMethod = mocks[requestMethod.rawValue] as? NSMutableDictionary else {
            fatalError("Couldn't find definitions for request: \(requestMethod) make sure to create a node for it in the plist")
        }

        if let responseFiles = definitionsForMethod[url.absoluteString] as? NSMutableArray,
            let responseFileDictionary = responseFiles.firstObject as? [String: String] {

            if let responseFile = responseFileDictionary[dataKey],
                let responsePath = bundle?.path(forResource: responseFile, ofType: ""),
                isData {
                return URL(fileURLWithPath: responsePath)
            }

            if let responseFile = responseFileDictionary[responseKey],
                let responsePath = bundle?.path(forResource: responseFile, ofType: ""),
                !isData {
                if responseFiles.count > 1 {

                    let reducedResponsesArray = NSMutableArray(array: responseFiles)
                    reducedResponsesArray.removeObject(at: 0)
                    let requestMocks = mocks["\(requestMethod)"] as? NSDictionary ?? [:]
                    let mutableMocks = NSMutableDictionary(dictionary: requestMocks)
                    mutableMocks["\(url)"] = reducedResponsesArray
                    self.mocks["\(requestMethod)"] = mutableMocks
                }

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
    func recordDataForRequest(_ data: Data?, httpHeaders: [AnyHashable: Any]?, request: URLRequest) {
        guard let headers = httpHeaders
            else { return }
        
        var headersData = try? JSONSerialization.data(withJSONObject: headers, options: .prettyPrinted)
        if headersData == nil {
            headersData = NSKeyedArchiver.archivedData(withRootObject: headers)
        }
        recordForRequest(data,
                         headers:headersData,
                         request: request)
    }
    
    
    fileprivate func recordForRequest(_ data: Data?, headers: Data?, request: URLRequest) {
        
        guard let definitionsPath = mockFileOutOfBundle(),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath),
            let httpMethod = request.httpMethod,
            let url = request.url,
            let responseFile = generateResponseFileName(url),
            let responsePath = mockedFilePath(responseFile),
            let headersFile = generateResponseHeadersFileName(url),
            let headersPath = mockedFilePath(headersFile),
            let data = data else {
                return
        }
        do { try data.write(to: URL(fileURLWithPath: responsePath), options: [.atomic])
            try headers?.write(to: URL(fileURLWithPath: headersPath), options: [.atomic]) }
        catch { print("SuperMock - error writing in file: \(error)")}
        let keyPath = "mocks.\(httpMethod).\(url)"
        if let mocks = definitions.value(forKeyPath: keyPath) as? NSMutableArray {
            mocks.add([dataKey:responseFile, responseKey:headersFile])
            if !definitions.write(toFile: definitionsPath, atomically: true) {
                print("Error writning the file, permission problems?")
            }
        } else if let mocks = definitions.value(forKeyPath: "mocks.\(httpMethod)") as? NSMutableDictionary {
            mocks["\(url)"] = [[dataKey:responseFile, responseKey:headersFile]]
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
        
        let method = request.httpMethod ?? "GET"
        let requestMethod = RequestMethod(rawValue: method) ?? .GET
        
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
    
    fileprivate func mockedHeaderFields(_ url: URL, requestMethod: RequestMethod, mocks: NSMutableDictionary) -> [String : String]? {
        
        guard let mockedHeaderFieldsURL = mockURLForRequestRestponseURL(url, requestMethod: requestMethod, mocks: mocks), mockedHeaderFieldsURL != url else {
            return nil
        }
        guard let mockedHeaderFieldData = try? Data(contentsOf: mockedHeaderFieldsURL) else {
            return nil
        }
        if let mockedHeaderFields = try? JSONSerialization.jsonObject(with: mockedHeaderFieldData, options: .allowFragments) as? [String : String] {
            return mockedHeaderFields
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
    
    fileprivate func generateResponseFileName(_ url: URL)->String? {
        
        return  generateResponseFileName(url, isData: true)
    }
    
    fileprivate func generateResponseHeadersFileName(_ url: URL)->String? {
        
        return  generateResponseFileName(url, isData: false)
    }
    
    fileprivate func generateResponseFileName(_ url: URL, isData:Bool)->String? {
        var urlString = url.absoluteString
        let urlStringLengh = urlString.count
        let fromIndex = (urlStringLengh > maxFileLegth) ? maxFileLegth : urlStringLengh
        urlString = urlString.suffix(fromIndex).debugDescription
        guard let fileName = urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            fatalError("You must provide a request with a valid URL")
        }
        var fileCounter = 0
        var composedFileName = ""
        repeat {
            composedFileName = fileName + "-\(fileCounter)"
            fileCounter += 1
        }
            while (fileslist.contains(composedFileName))
        fileslist.append(composedFileName)
        if isData && recording {
            return  composedFileName + "DATA." + fileType(mimeType(url))
        }
        return  composedFileName + "." + fileType(mimeType(url))
    }
    
    func mockFileOutOfBundle() -> String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        
        guard let bundle = bundle,
              let documentsDirectory = paths[0] as? String else {
            return nil
        }
        try? FileManager.default.createDirectory(atPath: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
        let mocksPath = (documentsDirectory) + "/" + mocksFile
        
        print("Recording mocks at: \(mocksPath)")
        if !FileManager.default.fileExists(atPath: mocksPath),
            let definitionsPath = bundle.path(forResource: mocksFile, ofType: nil),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath) {
            definitions.write(toFile: mocksPath, atomically: true)
        } else if !FileManager.default.fileExists(atPath: mocksPath) {
            let mockDictionary = NSDictionary(dictionary:["mimes":["htm":"text/html",
                                                                   "html":"text/html",
                                                                   "json":"application/json"],
                                                          "mocks":["DELETE":["http://":[["data":"", "response":""]]],
                                                                   "POST":["http://":[["data":"", "response":""]]],
                                                                   "PUT":["http://":[["data":"", "response":""]]],
                                                                   "GET":["http://":[["data":"", "response":""]]]]])
            if !mockDictionary.write(toFile: mocksPath, atomically: true) {
                print("There was an error creating the file")
            }
        }
        
        return mocksPath
    }
}

