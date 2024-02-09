//
//  MNAccessToken+Vapor.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation
import Fluent
import Vapor
import JWT
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNAccessToken+Vapor")

import Vapor
import MNUtils

// Extensions requiring no implementations
extension MNAccessToken : Content {}
extension MNAccessToken : AsyncResponseEncodable {}

/// Keys for data stored in Request.storage or Request.session.storage:
public struct AccessTokenStorageKey : ReqStorageKey {
    public typealias Value = MNAccessToken
}

public struct SelfAccessTokenStorageKey : ReqStorageKey {
    public typealias Value = MNAccessToken
}

extension MNAccessToken : JWTPayload, Authenticatable {
    
    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    public var subject: SubjectClaim {
        // The authorization server can then use the "sub" claim to verify the validity of the JWT, and to determine which user or service is requesting access to the protected resources.
        //guard let uuidstr = self.$userUIDString // .$user.mnUID?.uuidString ?? self.userUIDString else {
            // throw MNError(.misc_failed_crypto, reason: "Failed creating JWT subject claim")
            preconditionFailure("MNAccessToken.Failed creating subject.")
        // }
        
        return SubjectClaim(value: "") // TODO: uuidstr
    }

    // The "expirationDate" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    public var expiration: ExpirationClaim {
        return ExpirationClaim(value: self.expirationDate)
    }

    public func forceLoadUser(vaporRequest:Request) async-> MNUser  {
        return await self.forceLoadUser(db: vaporRequest.db)
    }
    
    public func forceLoadUser(db:any Database) async-> MNUser {
        // TODO:
        preconditionFailure("IMPLMENT forceLoadUser:db")
    }
    
    public func verify(context:String) throws {
        if !self.isValid {
            throw Abort(.unauthorized, reason: "token is not valid!")
        }
        if self.isEmpty {
            throw Abort(.unauthorized, reason: "token has an empty UUID 00000000-0000-0000-0000-000000000000")
        }
        if self.isExpired {
            throw Abort(.unauthorized, reason: "token has expired")
        }
    }
    
    // MARK: JWTPayload
    public func verify(using signer: JWTSigner) throws {
        return try self.verify(context: "MNAccessToken implementing JWTPayload.verify(using:JWTSigner)")
    }
}
