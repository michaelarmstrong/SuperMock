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
        
        if (SuperMockResponseHelper.sharedHelper.recording) {
            protocolClasses.append(SuperMockRecordingURLProtocol.self)
        }
        if (SuperMockResponseHelper.sharedHelper.mocking) {
            protocolClasses.append(SuperMockURLProtocol.self)
        }
        if let protocols = self.protocolClasses {
            protocolClasses.appendContentsOf(protocols)
        }
        self.protocolClasses = protocolClasses
    }
}