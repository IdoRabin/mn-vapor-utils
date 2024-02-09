//
//  MNUserConsts.swift
//  
//
//  Created by Ido on 15/06/2023.
//

import Foundation
import Fluent
import MNUtils
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("MNUser")?.setting(verbose: true)

/* MNUUser {
    id
    username
    useremail
    avatar
    status
} */

open class MNUserConsts {
    static var USERNAME_MINMAX_LEN_RANGE : Range<UInt> {
        return 5..<256
    }
    
    static var USEREMAIL_MINMAX_LEN_RANGE : Range<UInt> {
        return 5..<2048
    }
    
    static var usernameAllowedCharSet: CharacterSet {
        return CharacterSet.usernameAllowedSet
    }
    
    static var userDomainAllowedCharSet: CharacterSet {
        return CharacterSet.userDomainAllowedSet
    }
}

public final class MNUser : MNUIDable {
    
    // MARK: Const
    public typealias Consts = MNUserConsts
    
    public enum CodingKeys : String, CodingKey {
        case id = "id"
        case domain = "domain"
        case createdDate = "created_date"
        case lastUsedDate = "last_used_date"
        case username = "user_name"
        case useremail = "user_email"
        case avatar = "avatar"
        case status = "status"
        case info = "info"
        case accessToken = "access_token_child"
        
        public var fieldKey : FieldKey {
            switch self {
            case .accessToken:
                return "access_token_id" // saved in db as id column pointing tor the other table
            default:
                return .string(self.rawValue)
            }
        }
    }
    
    // MARK: MNUserable & MNIdeable & Identifiable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    public var id: UUID?
    
    @OptionalField(key: CodingKeys.domain.fieldKey)
    public var domain: String?
    
    // MARK: MNUserable Properties / members
    @OptionalField(key: CodingKeys.createdDate.fieldKey)
    public var createdDate: Date?
    
    @Field(key: CodingKeys.lastUsedDate.fieldKey)
    public var lastUsedDate: Date
    
    @OptionalField(key: CodingKeys.username.fieldKey)
    public var username: String?
    
    @OptionalField(key: CodingKeys.useremail.fieldKey)
    public var useremail: String?
    
    @OptionalField(key: CodingKeys.avatar.fieldKey)
    public var avatar: URL?
    
//    @Field(key: CodingKeys.status.fieldKey)
//    public var status: MNPersonStatus
    
    @OptionalChild(for: \.$user)
    public var accessToken: MNAccessToken?
    
    // @OptionalField(key: CodingKeys.info.fieldKey)
    // public var info: MNUserInfo?
    
    // MARK: Computed properties
    // MNUIDable
    public var mnUID: MNUID? {
        guard let id = self.id else {
            dlog?.verbose(log:.note, "mnUID for user: \(self.description) is nil. User has no UUID.")
            return nil
        }
        return MNUID(uuidString: id.uuidString, typeStr: "USR")
    }
    
    public var isEmpty: Bool {
        return (self.id?.isZeroUID ?? true) &&
        ((username?.count ?? 0) == 0) && ((useremail?.count ?? 0) == 0)
    }
    
    public var tokenExpirationDate: Date? {
        return nil // TODO: self.accessToken.ex ??
    }
    
    public var isExpiredToken: Bool {
        return (self.id?.isZeroUID ?? true) &&
        ((username?.count ?? 0) == 0) && ((useremail?.count ?? 0) == 0)
    }
    
    // Required to conform to Fluent Fields..
    public init() {
        createdDate = Date.now
        lastUsedDate = Date.now
//        status = MNPersonStatus.creating
    }
    
    // MARK: Equatable
    public static func == (lhs: MNUser, rhs: MNUser) -> Bool {
        return lhs.id == rhs.id // TODO: Check if equality should be more accurate, how to compare when two instances of same user are compared?
    }
}
