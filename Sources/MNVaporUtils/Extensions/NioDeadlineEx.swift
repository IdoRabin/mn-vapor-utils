//
//  NIODeadlineEx.swift
//  
//
//  Created by Ido on 26/05/2023.
//

import Foundation
import DSLogger
import NIOCore
fileprivate let dlog : DSLogger? = DLog.forClass("NIODeadlineEx")

public extension NIODeadline /* delayFromNow : TimeInterval */ {
    static func delayFromNow(_ delay : TimeInterval)->NIODeadline {
        return NIODeadline.now() + .milliseconds(Int64(delay*1000))
    }
}
