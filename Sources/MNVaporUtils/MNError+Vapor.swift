//
//  MNError+Vapor.swift
//  
//
//  Created by Ido on 08/06/2023.
//

import Foundation
import MNUtils
import NIOHTTP1

/// Less verbose typealias for `HTTPResponseStatus`.
public typealias HTTPStatus = NIOHTTP1.HTTPResponseStatus

extension MNError {
    var httpStatus : HTTPStatus? {
        // Only when http status is involved
        if self.code >= 100 && self.code < 600 {
            return HTTPStatus(statusCode: self.code)
        }
        
        return nil
    }
}
