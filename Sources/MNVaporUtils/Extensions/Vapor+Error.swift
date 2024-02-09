//
//  Vapor+Error.swift
//  
//
//  Created by Ido on 16/11/2022.
//

import Foundation
import Vapor
import MNUtils

public extension Abort {
    init(mnErrorCode mneCode:MNErrorCode, reason areason:String? = nil) {
        if mneCode.isHTTPStatus {
            self.init(HTTPResponseStatus(statusCode: mneCode.code, reasonPhrase: areason ?? mneCode.reason))
        } else {
            self.init(.custom(code: UInt(mneCode.code), reasonPhrase: areason ?? mneCode.reason))
        }
    }
}
