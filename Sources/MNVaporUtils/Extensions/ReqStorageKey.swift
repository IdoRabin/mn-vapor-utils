//
//  ReqStorageKey.swift
//  
//
//  Created by Ido on 03/11/2022.
//

import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("ReqStorageKey")

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
/*
struct UserStorageKey : ReqStorageKey {
    typealias Value = MNUser
}

struct SelfUserStorageKey : ReqStorageKey {
    typealias Value = MNUser
}
*/
struct SelfUserIDStorageKey : ReqStorageKey {
    typealias Value = String
}

/// Keys for data stored in the User of Requests:
struct UserTokenMakeIfMissingKey : /*Vapor.Utilities.*/ReqStorageKey {
    typealias Value = Bool
}

struct UserTokenCreateIfExpiredKey : /*Vapor.Utilities.*/ReqStorageKey  {
    typealias Value = Bool
}

// MARK: class behaving similar to an enum of all ReqStorageKeys:
public class ReqStorageKeys {
    // Equivalents of RouteInfoCodingKeys:
    //static let user = UserStorageKey.self
    static let selfUserID = SelfUserIDStorageKey.self
    //static let selfUser = SelfUserStorageKey.self
//    static let accessToken = AccessTokenStorageKey.self
//    static let selfAccessToken = SelfAccessTokenStorageKey.self
    static let requestId = RequestIdStorageKey.self
    static let redirectedFrom = RedirectedFromStorageKey.self
    static let contextText = ContextTextStorageKey.self
    static let appRouteContext = MNRouteContextStorageKey.self
    static let appRouteHistory = MNRoutingHistoryStorageKey.self
    
    static let errorCode = ErrorCodeStorageKey.self
    static let errorReason = ErrorReasonStorageKey.self
    static let errorText = ErrorTextStorageKey.self
    static let errorRequestID = ErrorRequestIDStorageKey.self
    static let errorOriginatingPath = ErrorOriginatingPathStorageKey.self
    
    // Instructions:
    static let userTokenCreateIfExpired = UserTokenCreateIfExpiredKey.self
    static let userTokenMakeIfMissing = UserTokenMakeIfMissingKey.self
    
    static var all : [any ReqStorageKey.Type]  = [
        //ReqStorageKeys.user,
        ReqStorageKeys.selfUserID,
        //ReqStorageKeys.selfUser,
//        ReqStorageKeys.accessToken,
//        ReqStorageKeys.selfAccessToken,
        ReqStorageKeys.requestId,
        ReqStorageKeys.redirectedFrom,
        ReqStorageKeys.errorCode,
        ReqStorageKeys.errorReason,
        ReqStorageKeys.contextText,
        ReqStorageKeys.appRouteContext,
        ReqStorageKeys.appRouteHistory,
        ReqStorageKeys.userTokenCreateIfExpired,
        ReqStorageKeys.userTokenMakeIfMissing,
    ]
}
