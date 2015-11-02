//
//  SuperMockNSURLRequestExtension.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation

extension NSURLRequest {
    
    func hasMock() -> Bool {
        
        let mockRequest = SuperMockResponseHelper.sharedHelper.mockRequest(self)
        if mockRequest.URL == self.URL {
            return false
        }
        
        return true
    }
    
}