//
//  SuperMockNSURLRequestExtension.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation

extension NSURLRequest {
    
    /**
     Call to determine whether or not a NSURLRequest has an applicable mock setup in Mocks.plist
     
     - returns: Bool determining outcome.
     */
    func hasMock() -> Bool {
        
        let mockRequest = SuperMockResponseHelper.sharedHelper.mockRequest(self)
        if mockRequest.URL == self.URL {
            return false
        }
        
        return true
    }
    
}