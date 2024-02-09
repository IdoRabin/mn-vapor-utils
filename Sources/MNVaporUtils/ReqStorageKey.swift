//
//  ReqStorageKey.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Vapor
import Logging
import MNUtils

fileprivate let dlog: Logger? = Logger(label: "ReqStorageKey")

// MARK: Protocol ReqStorageKey
public protocol ReqStorageKey : StorageKey {
    static var asString: String { get }
}

public extension ReqStorageKey /* default implementation */  {
    static var asString: String {
        return "\(Self.self)"
    }
}

// MARK: structs implementing ReqStorageKey
public struct RedirectedFromStorageKey : ReqStorageKey {
    public typealias Value = String
}

public struct RequestIdStorageKey : ReqStorageKey {
    public typealias Value = String
}

public struct ErrorCodeStorageKey : ReqStorageKey {
    public typealias Value = Int
}

public struct ErrorReasonStorageKey : ReqStorageKey {
    public typealias Value = String
}

public struct ContextTextStorageKey : ReqStorageKey {
    public typealias Value = String
}

public struct ErrorTextStorageKey : ReqStorageKey {
    public typealias Value = String
}

public struct ErrorRequestIDStorageKey : ReqStorageKey {
    public typealias Value = String
}

public struct ErrorOriginatingPathStorageKey : ReqStorageKey {
    public typealias Value = String
}
/// Keys for data stored in the User of Requests:
public struct UserTokenMakeIfMissingKey : /*Vapor.Utilities.*/ReqStorageKey {
    public typealias Value = Bool
}

public struct UserTokenCreateIfExpiredKey : /*Vapor.Utilities.*/ReqStorageKey  {
    public typealias Value = Bool
}

public struct SelfUserIDStorageKey : ReqStorageKey {
    public typealias Value = UUID
}


// MARK: class behaving similar to an enum of all ReqStorageKeys:
open class ReqStorageKeys {
    // Equivalents of RouteInfoCodingKeys:
    static public let requestId = RequestIdStorageKey.self
    static public let redirectedFrom = RedirectedFromStorageKey.self
    static public let contextText = ContextTextStorageKey.self
    static public let selfUserID = SelfUserIDStorageKey.self
    
    static public let errorCode = ErrorCodeStorageKey.self
    static public let errorReason = ErrorReasonStorageKey.self
    static public let errorText = ErrorTextStorageKey.self
    static public let errorRequestID = ErrorRequestIDStorageKey.self
    static public let errorOriginatingPath = ErrorOriginatingPathStorageKey.self
    
    // Instructions:
    static public let userTokenCreateIfExpired = UserTokenCreateIfExpiredKey.self
    static public let userTokenMakeIfMissing = UserTokenMakeIfMissingKey.self
    
    static public var all : [any ReqStorageKey.Type]  = [
        ReqStorageKeys.selfUserID,
        
        /*
        ReqStorageKeys.user,
        
        ReqStorageKeys.selfLoginInfo,
        ReqStorageKeys.selfUser,
        ReqStorageKeys.accessToken,
        ReqStorageKeys.selfAccessToken,
        ReqStorageKeys.appRouteContext,
        ReqStorageKeys.appRouteHistory,
        ReqStorageKeys.userPIIInfos,
        */
        
        ReqStorageKeys.requestId,
        ReqStorageKeys.redirectedFrom,
        ReqStorageKeys.errorCode,
        ReqStorageKeys.errorReason,
        ReqStorageKeys.contextText,
        
        ReqStorageKeys.userTokenCreateIfExpired,
        ReqStorageKeys.userTokenMakeIfMissing,
    ]
}
