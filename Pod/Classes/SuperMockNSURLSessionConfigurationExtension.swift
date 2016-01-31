//
//  SuperMockNSURLSessionConfigurationExtension.swift
//  Pods
//
//  Created by Scheggia on 27/01/2016.
//
//

import Foundation

extension NSURLSessionConfiguration {
    
    public func addProtocols() {
        
        var protocolClasses = [AnyClass]()
        if let protocols = self.protocolClasses {
         protocolClasses.appendContentsOf(protocols)
        }
        if (SuperMockResponseHelper.sharedHelper.recording) {
            protocolClasses.append(SuperMockRecordingURLProtocol.self)
        }
        if (SuperMockResponseHelper.sharedHelper.mocking) {
            protocolClasses.append(SuperMockURLProtocol.self)
        }
    }
}