//
//  MNRouteAuth.swift
//  
//
//  Created by Ido on 23/10/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("MNRouteAuth")

public struct MNRouteAuth: OptionSet, Equatable, Hashable, JSONSerializable {
    public let rawValue: Int
    
    public static let userPassword =       MNRouteAuth(rawValue: 1 << 0) // 1
    public static let bearerToken =        MNRouteAuth(rawValue: 1 << 1) // 2
    public static let endToEnd =           MNRouteAuth(rawValue: 1 << 2) // 4
    public static let backendAccess =      MNRouteAuth(rawValue: 1 << 3) // 8
    public static let oAuth =              MNRouteAuth(rawValue: 1 << 4) // 16
    public static let webPageAgent =       MNRouteAuth(rawValue: 1 << 5) // 32 - user agent must be a webpage
    
    // Generalizations:
    public static let empty: MNRouteAuth = []
    public static let none:  MNRouteAuth = []
    public static let all:       MNRouteAuth  = [.userPassword, .bearerToken, .endToEnd, .backendAccess, .oAuth, .webPageAgent]
    public static let allArray: [MNRouteAuth] = [.userPassword, .bearerToken, .endToEnd, .backendAccess, .oAuth, .webPageAgent]
    
    private static func descriptionForSingle(auth:MNRouteAuth)->String? {
        var result : String? = nil
        switch auth.rawValue {
        case MNRouteAuth.userPassword.rawValue:    result = "userPassword"
        case MNRouteAuth.bearerToken.rawValue:     result = "bearerToken"
        case MNRouteAuth.endToEnd.rawValue:        result = "endToEnd"
        case MNRouteAuth.backendAccess.rawValue:   result = "backendAccess"
        case MNRouteAuth.oAuth.rawValue:           result = "oAuth"
        case MNRouteAuth.webPageAgent.rawValue:    result = "webPageAgent"
        case MNRouteAuth.none.rawValue:            result = nil // no auth needed
        default:
            dlog?.note("MNRouteAuth.descriptionForSingle(auth:MNRouteAuth) failed for: \(auth.rawValue.description).")
            return nil
        }
        
        // NOTE: To snake case!!!
        return result?.camelCaseToSnakeCase()
    }
    
    public var descriptions : [String] {
        var result : [String] = []
        for element in self.elements {
            if let desc = MNRouteAuth.descriptionForSingle(auth: element) {
                result.append(desc)
            }
        }
        if result.count == 0 {
            result = ["none"]
        }
        return result
    }
    
    public var description : String {
        let descs = self.descriptions
        if descs.count == 1 {
            return descs.first!
        }
        return  "[" + descs.joined(separator: ", ") + "]"
    }
    
    public var isShouldFetchUser : Bool {
        return self.intersection([MNRouteAuth.bearerToken, .webPageAgent, .oAuth, .endToEnd]).isEmpty == false
    }
    
    public var isShouldFetchAccessToken : Bool {
        return self.intersection([MNRouteAuth.bearerToken, .webPageAgent, .oAuth, .endToEnd]).isEmpty == false
    }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

// MARK: Codable
extension MNRouteAuth : LosslessStrEnum {
    
    enum CodingKeys : String, CodingKey {
        case type_int = "type_int"
        case type_str = "type"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if encoder.isJSONEncoder {
            try container.encode(self.descriptions, forKey: .type_str);
        } else {
            try container.encode(self.rawValue, forKey: .type_int)
        }
    }
    
    public init?(parts: [String]) {
        var result : MNRouteAuth = []

        for part in parts.lowercased {
            var wasFound = false
            if ["none", "empty"].contains(part) {
                wasFound = true
            } else {
                for auth in Self.allArray {
                    let desc = Self.descriptionForSingle(auth: auth)
                    let unsnaked = desc?.snakeCaseToCamelCase()
                    if part == desc?.lowercased() || part == unsnaked?.lowercased() {
                        result.insert(auth)
                        wasFound = true
                        break
                    }
                }
            }
            
            if !wasFound && !["none", "empty"].contains(part) {
                dlog?.note("MNRouteAuth.init(_ description:String) failed for: \(parts.descriptionsJoined) in part: \"\(part)\"!")
            }
        }

        if result.isEmpty && parts.removing(objects: ["none", "empty"]).count > 0 {
            dlog?.note("MNRouteAuth.init(_ description:String) failed for: \(parts.descriptionsJoined) in all parts.")
            return nil
        }
        
        self.init(rawValue: result.rawValue)
    }
    
    public init?(_ description: String) {
        guard description.count > 0 else {
            return nil
        }
        
        var result : MNRouteAuth = []
        
        if description.trimmingCharacters(in: .decimalDigits).count == 0, let num = Int(description) {
            result = MNRouteAuth(rawValue: num)
        } else {
            let parts = description.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).components(separatedBy: ",")
            result = MNRouteAuth(parts:parts) ?? []
        }
        
        self.init(arrayLiteral: result)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var val : Int = 0
        
        for key in container.allKeys {
            switch key {
            case .type_int:
                val = try container.decodeIfPresent(Int.self, forKey: key) ?? 0
            case .type_str:
                do {
                    let strings = try container.decodeIfPresent([String].self, forKey: key) ?? []
                    if let res = MNRouteAuth(parts:strings) {
                        val = res.rawValue
                    } else {
                        throw MNError(.misc_failed_decoding, reason: "MNRouteAuth.init(from decoder...) failed from strings: \(strings.descriptionsJoined)") // rethrow!
                    }
                } catch let error {
                    dlog?.warning("init(from decoder...) failed parsing values for key: [\(key)] - expected is an array of strings.. \(String(describing:error))")
                    throw error // rethrow!
                }
            }
        }
        
        self.init(rawValue: val)
    }
}
