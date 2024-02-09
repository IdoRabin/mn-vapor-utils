//
//  MNRouteInfo.swift
//
//
//  Created by Ido on 03/02/2024.
//

import Foundation
import MNUtils
import Vapor
import Logging

fileprivate let dlog: Logger? = Logger(label: "MNRouteInfo")

let MN_ROUTE_INFO_KEY = "mnRouteInfo"
public struct MNRouteInfo : Sendable, JSONSerializable {
    
    public enum ProductType : String, Sendable, JSONSerializable {
        case apiResponse
        case webPage
        case stream
        case file
    }
    
    public struct RequiredAuth: OptionSet, JSONSerializable, Sendable {
        public let rawValue: Int
        
        public static let none         = RequiredAuth(rawValue: 1 << 0)
        public static let userToken    = RequiredAuth(rawValue: 1 << 1)
        public static let userPassword = RequiredAuth(rawValue: 1 << 2)
        
        public static let all: RequiredAuth = [/* .none, */ .userToken, .userPassword]
        
        // MARK: RawRepresentable
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public enum AuthType : String, Sendable, JSONSerializable {
        case apiResponse
        case webPage
        case stream
        case file
    }
    
    public let groupTag: String
    public let productType: ProductType
    public let title: String?
    public let description: String?
    public let requiredAuth: RequiredAuth
    public var canonicalRoute : MNCanonicalRoute?
    
    public init(groupTag: String, productType: ProductType, title: String?, description: String?, requiredAuth: RequiredAuth) {
        self.groupTag = groupTag
        self.productType = productType
        self.title = title
        self.description = description
        self.requiredAuth = requiredAuth
    }
    
    public mutating func update(withRoute route:Route) {
        self.canonicalRoute = MNCanonicalRoute(url: route.path.string, method: route.method)
    }
    
//    public mutating func mutateSelf(_ setup : (_ info:Self)->Void) {
//        _ = setup(self)
//    }
//    
//    public init(_ setup : (_ info:Self)->Void) {
//        self.init(groupTag: "",
//                  productType: .webPage,
//                  title: nil,
//                  description: nil,
//                  requiredAuth: .none)
//        mutateSelf(setup)
//    }
}
