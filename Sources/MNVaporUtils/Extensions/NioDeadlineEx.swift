//
//  NIODeadlineEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Logging
import NIOCore
fileprivate let dlog: Logger? = Logger(label: "NIODeadlineEx")

public extension NIODeadline /* delayFromNow : TimeInterval */ {
    static func delayFromNow(_ delay : TimeInterval)->NIODeadline {
        return NIODeadline.now() + .milliseconds(Int64(delay*1000))
    }
}
