//
//  MNAccessToken.swift
//  MNAccessToken
//
//  Created by Ido on 10/08/2022.
//

import Foundation
import Fluent
import JWT
import MNUtils
import DSLogger


fileprivate let dlog : DSLogger? = DLog.forClass("MNAccessToken")

// Fields will save this as a flat structure in the DB, with with keys joined by underscore ("_")
// final is needed so that we can maintain a required init()

public final class MNAccessToken : Fluent.Model {

    public static let schema = "access_tokens"
    
    // MARK: Static
    // MARK: Const
    typealias Consts = MNAccessTokenConsts
    
    public enum CodingKeys : String, CodingKey {
        case id = "id"
        case createdDate = "created_date"
        case expirationDate = "expiration_date"
        case lastUsedDate = "last_used_date"
        case user = "user"
        case userUIDString = "user_uid_str"
        public var fieldKey : FieldKey {
            switch self {
            case .user:
                return "user_id" // saved in db as id column pointing tor the other table
            default:
                return .string(self.rawValue)
            }
        }
    }
    
    // MARK: Properties / members
    
    // MARK: Identifiable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    public var id: UUID? //
    
    @OptionalField(key: CodingKeys.createdDate.fieldKey)
    private (set) public var createdDate: Date?
    
    @Field(key: CodingKeys.expirationDate.fieldKey)
    private (set) public var expirationDate: Date
    
    @Field(key: CodingKeys.lastUsedDate.fieldKey)
    public var lastUsedDate : Date
    
    @OptionalParent(key: CodingKeys.user.fieldKey)
    public var user: MNUser? {
        didSet {
            self.userUIDString = user?.id?.uuidString
        }
    }
    
    @Field(key: CodingKeys.userUIDString.fieldKey)
    private (set) public var userUIDString: String?
    
    // MARK: Private
    // MARK: Lifecycle
    public init() {
        // Required to conform with Fluent Fields protocol
        self.id = UUID(uuidString: UID_EMPTY_STRING)
    }
    
    public init(accessToken other: MNAccessToken) {
        // This is used if atoken support the extra props in the class beyond the proptocol MNAccessTokenable
        
        self.id = other.id
        self.createdDate = other.createdDate // Extra
        self.expirationDate = other.expirationDate
        self.lastUsedDate = other.lastUsedDate
        self.userUIDString = other.userUIDString
        self.user = other.user
    }
    
    // MARK: Public
    public var isExpired : Bool {
        return self.expirationDate.isInThePast(safetyMargin: 20) // 20 seconds +- margin of error.
    }
    
    public var isValid : Bool {
        return self.expirationDate.isInThePast(safetyMargin: 20) // 20 seconds +- margin of error.
    }
    
    public var isEmpty : Bool {
        return (self.user == nil || (userUIDString?.count ?? 0 < UUID.UUID_EMPTY_STRING.count)) || self.id?.isZeroUID ?? true || (self.expirationDate.timeIntervalSince1970 == 0)
    }
    
    /// Duration of a token for being velid: the duration from the creation date.
    /// if no creation date exists (unknown), will return nil
    var validDuration : TimeInterval? {
        guard let createdDate = self.createdDate else {
            return nil
        }
        return abs(createdDate.timeIntervalSince(self.expirationDate))
    }
    
    /// The Date componnts describing the whole duration in which the token is/was valid: from creationDate until the expiration date.
    /// If the access token has an unknown / nil creation date, will return nil
    var durationComponents : DateComponents? {
        guard self.createdDate != nil, let validDuration = self.validDuration else {
            return nil
        }
        
        // Should be expressed as a series: [the token has a duration of: 1 month, 15 days 1:59'56" remaining...]
        return Calendar.autoupdatingCurrent.componentsOf(duration:validDuration)
    }
    
    
    /// Remaining time interval until the token expires
    var remainingDuration : TimeInterval {
        return Date.now.timeIntervalSince(self.expirationDate)
    }
    
    /// The Date componnts describing the remaining time until the expiration date.
    /// If the access token is expired, will return nil
    var remainingDurationComponents : DateComponents? {
        
        guard !self.isExpired, let validDuration = self.validDuration else {
            return nil
        }
        
        // Should be expressed as a series: [the token has a duration of: 1 month, 15 days 1:59'56" remaining...]
        return Calendar.autoupdatingCurrent.componentsOf(duration:validDuration)
    }
    
    // MARK: Equatable
    public static func == (lhs: MNAccessToken, rhs: MNAccessToken) -> Bool {
        return lhs.id == rhs.id
        // TODO: Consider && lhs.expirationDate == rhs.expirationDate
    }
    
    // MARK: Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastUsedDate, forKey: CodingKeys.lastUsedDate)
        try container.encode(expirationDate, forKey: CodingKeys.expirationDate)
        try container.encodeIfPresent(user?.id, forKey: CodingKeys.user)
        
        var uidStr = userUIDString
        if uidStr?.count ?? 0 == 0, let id = user?.id {
            uidStr = id.uuidString
        }
        try container.encode(uidStr , forKey: CodingKeys.user)
    }
    
    public init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try keyed.decode(UUID.self, forKey: CodingKeys.id)
        self.createdDate = try keyed.decode(Date.self, forKey: CodingKeys.createdDate)
        self.expirationDate = try keyed.decode(Date.self, forKey: CodingKeys.expirationDate)
        self.lastUsedDate = try keyed.decode(Date.self, forKey: CodingKeys.lastUsedDate)
        self.userUIDString = try keyed.decodeIfPresent(String.self, forKey: CodingKeys.userUIDString) ?? ""
    }
}

extension MNAccessToken /* bearer token */ {
    
    // MARK: Bearer token conversion (from / to base64 string in http request header)
    
    
    /// Converts the access token to a HTTP Requset bearer token in the headers
    /// - Parameter forClient: For use with the client-side app - may not send some of the props.
    /// - Returns: a base 64 encoded string of an array of the strings of the properties, sperated by AccessToken.Consts.SEPARATOR. The exact order of returned params is:
    /// [userUIDString, expirationDate, ] and when NOT for client also concating / appending: [lastUsedDate, createdDate] at the end.
    public func asBearerToken(forClient: Bool = true)->String {
        // Bearer token: see:
        var items : [String] = []
        
        // var token = (self.$user.$id.value?.uuidString ?? "")
        items.appendIfNotNil(self.userUIDString) // ?? self.$user.$id.value?.uuidString ??
        items.append(expirationDate.ISO8601Format(.iso8601))
        if (!forClient) {
            items.append(lastUsedDate.ISO8601Format(.iso8601))
            items.appendIfNotNil(createdDate?.ISO8601Format(.iso8601))
        }
        
        // to: Base 64
        return items.joined(separator: Self.Consts.SEPARATOR).toBase64()
    }
    
    /// Create an access token from a given bearer token string (expecting base64 string)
    /// - Parameters:
    ///   - bearerToken: bearer token string from the user to user as the basis for the token
    ///   - allowExpired: allows creating an expired token, or throw an exception if the bearerToken leads to an expired token
    public convenience init(bearerToken : String, allowExpired:Bool = false) throws {
        
        guard bearerToken.count > UUID.UUID_EMPTY_STRING.count else {
            throw MNError(.misc_failed_crypto, reason: "bad access token input")
        }
        
        guard let decoded = bearerToken.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).fromBase64()?.components(separatedBy: Self.Consts.SEPARATOR), decoded.count > 1 else {
            throw MNError(.misc_failed_crypto, reason: "bad access token")
        }
        guard let userId = MNUID(uuidString: decoded[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), typeStr: "USR") else {
            throw MNError(.misc_failed_crypto, reason: "bad access token format")
        }
        
        // Three years old token?
        guard let expiration = Double(decoded[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)), expiration > -TimeInterval.SECONDS_IN_A_MONTH * 36 else {
            throw MNError(.misc_failed_crypto, reason: "bad access token expiration / expired long ago!.")
        }
        
        self.init()
        let date = Date(timeIntervalSince1970: expiration)
        // TODO: self.$user.id = userId.uid // should load the whole user?
        self.userUIDString = nil // TODO: userId.uuidString
        self.expirationDate = date
        self.lastUsedDate = Date()
        
        if self.isExpired {
            if !allowExpired {
                throw MNError(.misc_failed_crypto, reason: "Access token expired at: \(self.expirationDate.ISO8601Format(.iso8601)) [AT]")
            } else {
                dlog?.note("Receieved an expired access token for userId: \(userId)")
            }
        }
    }
}
