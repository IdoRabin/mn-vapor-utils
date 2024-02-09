//
//  MNUser+Vapor.swift
//  
//
//  Created by Ido on 15/06/2023.
//

import Foundation
import Vapor
import MNUtils
import JWT

// Extensions requiring no implementations

extension MNUser : Content {}
extension MNUser : AsyncResponseEncodable {}

/// Keys for data stored in Request.storage or Request.session.storage:
public struct MNUserStorageKey : ReqStorageKey {
    public typealias Value = MNUser
}

public struct SelfMNUserStorageKey : ReqStorageKey {
    public typealias Value = MNUser
}

extension MNUser : JWTPayload, Authenticatable {
    
    
    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    public var subject: SubjectClaim {
        return SubjectClaim(value: self.mnUID!.uuidString)
    }
    
    // The "expirationDate" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    public var expiration: ExpirationClaim {
        return ExpirationClaim(value: self.tokenExpirationDate ?? Date(timeIntervalSinceNow: Date.SECONDS_IN_A_DAY * 365))
    }
    
    public func verify(context:String) throws {
        if !self.isEmpty {
            throw Abort(.unauthorized, reason: "User is empty!")
        }
        
        if let username = username, !Self.Consts.USERNAME_MINMAX_LEN_RANGE.contains(UInt(username.count)) {
            throw Abort(.unauthorized, reason: "User username too big or too small! Accepted range:\(Self.Consts.USERNAME_MINMAX_LEN_RANGE)")
        }
        
        if let useremail = useremail, !Self.Consts.USEREMAIL_MINMAX_LEN_RANGE.contains(UInt(useremail.count)) {
            throw Abort(.unauthorized, reason: "User useremail too big or too small! Accepted range:\(Self.Consts.USEREMAIL_MINMAX_LEN_RANGE)")
        }
    }
    
    // MARK: JWTPayload
    public func verify(using signer: JWTSigner) throws {
        return try self.verify(context: "MNUser implementing JWTPayload.verify(using:JWTSigner) for an access token.")
    }
}
