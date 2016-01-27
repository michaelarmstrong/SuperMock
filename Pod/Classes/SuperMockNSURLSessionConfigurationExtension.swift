//
//  SuperMockNSURLSessionConfigurationExtension.swift
//  Pods
//
//  Created by Scheggia on 27/01/2016.
//
//

import Foundation

extension NSURLSessionConfiguration {
    
    func addProtocols() {
        
        self.protocolClasses = [SuperMockURLProtocol.self, SueprMockRecordingURLProtocol.self]
    }
}