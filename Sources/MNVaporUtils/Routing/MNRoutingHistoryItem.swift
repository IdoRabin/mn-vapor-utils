//
//  MNRoutingHistoryItem.swift
//
//
//  Created by Ido on 06/02/2024.
//

import Foundation
import Vapor
import Logging
import MNUtils

fileprivate let dlog : Logger? = Logger(label: "RoutingHistoryItem")

public class MNRoutingHistoryFragment : JSONSerializable, Hashable, CustomStringConvertible {
    
    let route : MNCanonicalRoute
    let status : HTTPResponseStatus
    let mnError :MNError?
    
    // MARK: CustomStringConvertible
    public var description: String {
        return "\(reqId) \(route.method) \(route.url.asNormalizedPathOnly()) status:\(status) error:\(mnError.descOrNil)"
    }
    
    // MARK: HasHable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(status)
        hasher.combine(route)
        hasher.combine(mnError)
    }
    
    // MARK: Equatable
    public static func == (lhs: MNRoutingHistoryFragment, rhs: MNRoutingHistoryFragment) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public class MNRoutingHistoryItem : JSONSerializable, Hashable, CustomStringConvertible {
    
    // MARK: Types
    public enum Action : JSONSerializable {
        case visited(MNRoutingHistoryFragment)
        case redirectedTo(MNRoutingHistoryFragment)
        case error(MNRoutingHistoryFragment)
    }
    
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    let action : Action
    l
    
    // MARK: Private
    // MARK: Lifecycle
    // MARK: Public
    
    // MARK: CustomStringConvertible
    public var description: String {
        return "MNRoutingHistoryItem: \(action)"
    }
    
    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        
    }
    
    // MARK: Equatable
    public static func ==(lhs:MNRoutingHistoryItem, rhs:MNRoutingHistoryItem)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

/// A routeing history record / item.
/*
public class MNRoutingHistoryItem : JSONSerializable, Hashable, CustomStringConvertible {
    // MARK: Members
    let requestID : String
    let path : String
    let httpMethod : HTTPMethod
    var mnError : MNError? = nil // NOTE: settable var!
    
    enum CodingKeys : CodingKey {
        case requestID
        case path
        case httpMethod
        case completeCode
        case completeReason
    }
    
    // MARK: Lifecycle
    init(requestID: String, path: String, httpMethod: HTTPMethod) {
        self.requestID = requestID
        self.path = path.asNormalizedPathOnly()
        self.httpMethod = httpMethod
    }
    
    // MARK: public
    
    // mutating
    private func setMNError(intCode:Int, reason:String?) {
        let err = MNError(MNErrorCode(rawValue: intCode)!, reason: reason ?? "Unknown")
        self.setMNError(err)
    }
    
    private func setMNError(code:MNErrorCode, reason:String?) {
        let err = MNError(code, reason: reason ?? "Unknown")
        self.setMNError(err)
    }
    
    private func setMNError(code:MNErrorCode, reasons:[String]) {
        let err = MNError(code, reasons: reasons)
        self.setMNError(err)
    }
    
    private func setAppError(errorable:MNErrorable) {
        // domain:nsError.domain, intCode: errorable.code, reason: errorable.reason
        let adomain = errorable.domain // ?? AppError.DEFAULT_DOMAIN
        let err = MNError(domain: adomain,
                          errcode: MNErrorCode(rawValue: errorable.code)!,
                          description: "MNError from MNErrorable",
                          reasons: [errorable.reason],
                          underlyingError: nil)
        self.setMNError(err)
    }
    
    private func setAppError(nsError:NSError) {
        let err = MNError(fromNSError: nsError, defaultErrorCode: .misc_unknown, reason: nsError.reason)
        self.setMNError(err)
    }
    
    private func setMNError(_ newMNError : MNError) {
        // NOTE: VAPOR defines a public typealias HTTPStatus = HTTPResponseStatus
        let errToSet = newMNError
        if let _ = self.mnError, let newStatus = newMNError.httpStatusCode,
            Redirect.allHttpStatuses.codes.contains(elementEqualTo: newStatus) {
                // This is a redirect "error":
            // TODO: Should we wrap redirect "error" as underlying or to contain the other error as underlying error
            return
        }
        self.mnError = errToSet
    }
    
    func setAppError(abort : Abort) {
        var reasons = [abort.status.reasonPhrase]
        if abort.reason.count > 0 && abort.reason != abort.status.reasonPhrase {
            reasons.append(abort.reason)
        }
        self.setMNError(code:MNErrorCode(rawValue: Int(abort.status.code))!, reasons: reasons)
    }
    
    func setHttpStatus(_ stt : HTTPStatus) {
        let intCode = Int(stt.code)
        self.setMNError(code:MNErrorCode(rawValue: intCode)!, reason: stt.reasonPhrase)
    }
    
    func clearError() {
        self.mnError = nil
    }
    
    func setError(_ mnError : MNError) {
        self.setMNError(mnError)
    }
    
    func setError(_ mnError : MNErrorable) {
        self.setAppError(errorable: mnError)
    }
    
    func setError(_ nsError : NSError) {
        self.setAppError(nsError:nsError)
    }
    
    // MARK: Equatable
    public static func == (lhs: MNRoutingHistoryItem, rhs: MNRoutingHistoryItem) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(requestID)
        hasher.combine(path)
        hasher.combine(httpMethod)
        hasher.combine(mnError)
    }
    
    // MARK: CustomStringConvertible
    public var description: String {
        let mth = "\(httpMethod)".paddingLeft(toLength: 5, withPad: " ")
        var result = "\(mth) \(requestID) \(path)"
        var error = mnError
        while error != nil {
            if let err = error {
                let reasonses = err.reasons?.descriptions().joined(separator: ", ") ?? err.reason
                result += " [\(err.code) \(reasonses)]"
                error = err.underlyingError
            } else {
                break
            }
        }
        return result
    }
    
    // MARK: Encode
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.requestID = try container.decode(String.self, forKey:CodingKeys.requestID)
        self.path = try container.decode(String.self, forKey:CodingKeys.path)
        self.httpMethod = try container.decode(HTTPMethod.self, forKey:CodingKeys.httpMethod)
        if let code : Int = try container.decodeIfPresent(Int.self, forKey:CodingKeys.completeCode),
           let reason : String = try container.decodeIfPresent(String.self, forKey:CodingKeys.completeReason) {
            self.mnError = MNError(code:MNErrorCode(rawValue: code)!, reason:reason)
            // dlog?.success("init(from:decoder) w/ error: \(self.description) error: >> \(code) >> \(reason)")
        } else {
            // dlog?.fail("init(from:decoder) NO error: \(self.description)")
        }
    }
    
    // MARK: Decode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        do {
            try container.encode(requestID, forKey:CodingKeys.requestID)
            try container.encode(path, forKey:CodingKeys.path)
            try container.encode(httpMethod, forKey:CodingKeys.httpMethod)
        } catch let error {
            dlog?.warning("encode(to encoder:) failed with encoding props into \(self) ERROR: \(String(describing:error))")
        }
        if let mnError : MNError = mnError {
            do {
                try container.encode(mnError.code, forKey:CodingKeys.completeCode)
                try container.encode(mnError.reason, forKey:CodingKeys.completeReason)
                //dlog?.success("encode(to encoder:) w/ AppError: \(self)")
            } catch let error {
                dlog?.warning("encode(to encoder:) failed with encoding AppError: \(mnError.description) into \(self) ERROR: \(String(describing:error))")
            }
        } else {
            dlog?.fail("encode(to encoder:) NO AppError: \(self)")
        }
    }
}
*/
