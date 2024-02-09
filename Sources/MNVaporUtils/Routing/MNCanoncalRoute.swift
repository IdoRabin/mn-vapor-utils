//
//  MNCanonicalRoute.swift
//
//
//  Created by Ido on 04/02/2024.
//

import Foundation
import MNUtils
import Vapor
import NIO
import NIOHTTP1
import Logging

fileprivate let dlog : Logger? = Logger(label:"MNCanonicalRoute")

public struct MNCanonicalRoute : Sendable, JSONSerializable, Hashable, CustomStringConvertible {
    public let url: String
    public let method: HTTPMethod
    
    // MARK: CustomStringConvertible
    public var description: String {
        return "\(method) \(url.asNormalizedPathOnly())"
    }
    
    private func matchMethods(method methodToTest:HTTPMethod? = nil)->Bool {
        guard let methodToTest = methodToTest else {
            return true
        }
        
        return (methodToTest == self.method)
    }
    
    public func matches(url urlToTest:URL?, method methodToTest:HTTPMethod? = nil)->Bool {
        guard let urlToTest = urlToTest else {
            return false
        }
        
        guard (urlToTest.relativePath == self.url) else {
            return false
        }
        
        guard self.matchMethods(method: methodToTest) else {
            return false
        }
        
        return false
    }
    
}
