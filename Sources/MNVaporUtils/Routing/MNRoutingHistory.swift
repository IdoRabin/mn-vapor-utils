//
//  MNRoutingHistory.swift
//  
//
//  Created by Ido on 20/11/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("RoutingHistory")

extension Redirect {
    static let all : [Redirect] = [.normal, .permanent, .temporary]
    static let allHttpStatuses : [HTTPStatus] = [Redirect.normal.status, Redirect.permanent.status, Redirect.temporary.status]
}

internal struct MNRoutingHistoryStorageKey : ReqStorageKey {
    typealias Value = MNRoutingHistory
}


public class MNRoutingHistoryItem : JSONSerializable, Hashable, CustomStringConvertible {
    // MARK: Members
    let requestID : String
    let path : String
    let httpMethod : HTTPMethod
    var mnError : MNError? = nil // settable
    
    enum CodingKeys : CodingKey {
        case requestID
        case path
        case httpMethod
        case completeCode
        case completeReason
    }
    
    var httpStatus : HTTPStatus? {
        guard let code = mnError?.code else {
            return nil
        }
        
        // Only when http status is involved
        if code >= 100 && code < 600 {
            return HTTPStatus(statusCode: code)
        }
        
        return nil
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
        let errToSet = newMNError
        if let _ = self.mnError, let newStatus = newMNError.httpStatus,
                Redirect.allHttpStatuses.contains(newStatus) {
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
        self.setMNError(code:MNErrorCode(rawValue: abort.code)!, reasons: reasons)
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

// This class should NOT save
public class MNRoutingHistory : JSONSerializable, Hashable, CustomStringConvertible {
    static let DEFAULT_MAX_ITEMS = 5
    
    // MARK: static
    static let UNKNOWN_REQ_ID = "UNKNOWN_REQ_ID"
    
    // MARK: members
    var items : [MNRoutingHistoryItem] = []
    private var _maxItems : Int = DEFAULT_MAX_ITEMS
    var maxItems : Int {
        get {
            return _maxItems
        }
        set {
            if newValue >= 3 && newValue <= 16384 {
                _maxItems = newValue
            } else {
                dlog?.warning("MNRoutingHistory set maxItems must be between 3 and 16384")
            }
        }
    }
    // TODO: Convert to AppSettable or add to the AppSettings...
    // @AppSettable(name: "RoutingHistory.maxItems", default: RoutingHistory.DEFAULT_MAX_ITEMS) static var maxItems : Int
    
    // MARK: Getters / computed properties
    var first : MNRoutingHistoryItem? {
        return items.first
    }
    
    var last : MNRoutingHistoryItem? {
        return items.last
    }
    
    var oneBeforeLast : MNRoutingHistoryItem? {
        guard items.count > 1 else {
            return nil
        }
        return items[items.count - 2]
    }
    
    // MARK: private
    func save(to req:Request) {
        req.saveToSessionStore(key: ReqStorageKeys.appRouteHistory, value: self)
    }
    
    // MARK: public Add / update funcs
    @discardableResult
    func update(path:String, method:HTTPMethod, reqId:String, error:MNError?)->MNRoutingHistoryItem {
        var result : MNRoutingHistoryItem!
        if let historyItem = self.items.first(where: { item in
            item.requestID == reqId && item.httpMethod == method
        }) {
            // Item already existed
            result = historyItem
            // dlog?.successOrFail(condition: error != nil, "update EXs \(historyItem) with error:\(error?.reason ?? "<nil>")")
        } else {
            // New item required:
            let newHistoryItem = MNRoutingHistoryItem(requestID: reqId, path: path, httpMethod: method)
            // dlog?.successOrFail(condition: error != nil, "adding NEW \(newHistoryItem) with error:\(error?.reason ?? "<nil>")")
            self.items.append(newHistoryItem)
            if self.items.count > 0 && self.items.count > self.maxItems {
                // This class should NOT contain all the browsing history in a session, jut the recent calls to allow managing redirects etc..
                self.items.remove(at: 0)
            }
            result = newHistoryItem
        }
        
        // Udate error or clear it:
        if let err = error {
            result.setError(err)
        } else {
            result.clearError()
        }
        
        return result
    }
    
    @discardableResult
    func update(path:String, method:HTTPMethod, reqId:String, error:Abort?)->MNRoutingHistoryItem {
        var err : MNError? = nil
        if let error = error {
            err = MNError(code:MNErrorCode(rawValue: Int(error.code))!, reason: error.reason)
        }
        return self.update(path: path, method: method, reqId: reqId, error: err)
    }
    
    @discardableResult
    public func update(path:String, method:HTTPMethod, reqId:String, error:Error?)->MNRoutingHistoryItem {
        var err : MNError? = nil
        if let error = error as? NSError {
            err = MNError(code:MNErrorCode(rawValue: Int(error.code))!, reason: error.reason)
        }
        return self.update(path: path, method: method, reqId: reqId, error: err)
    }
    
    @discardableResult
    public func update<Succ>(req:Request, result resultT:Result<Succ, Error>)->MNRoutingHistoryItem {
        var result :  MNRoutingHistoryItem!
        switch resultT {
        case .success:
            result = self.update(path: req.url.path,
                                 method: req.method,
                                 reqId: req.requestUUIDString,
                                 error: MNError(.http_stt_ok, reason: HTTPStatus.ok.reasonPhrase))
        case .failure(let err):
            if let abort = err as? Abort {
                result =  self.update(path: req.url.path,
                                      method: req.method,
                                      reqId: req.requestUUIDString,
                                      error: MNError(MNErrorCode(rawValue: MNErrorInt(abort.status.code))!, reason: abort.reason))
            } else if let appErr = err as? MNError {
                result = self.update(path: req.url.path,
                                     method: req.method,
                                     reqId: req.requestUUIDString,
                                     error:appErr)
            } else {
                let nsErr = err as NSError
                result = self.update(path: req.url.path,
                                     method: req.method,
                                     reqId: req.requestUUIDString,
                                     error:MNError(MNErrorCode(rawValue: nsErr.code) ?? MNErrorCode.misc_unknown, reason: nsErr.reason))
            }
        }
        self.save(to: req)
        return result
    }
    
    @discardableResult
    public func update(req:Request, error:Error)->MNRoutingHistoryItem {
        let res : Result<Bool, Error> = .failure(error)
        return self.update(req: req, result: res)
    }
    
    @discardableResult
    public func update(req:Request, status:HTTPStatus?)->MNRoutingHistoryItem {
        var error : MNError? = nil
        if let status = status {
            error = MNError(MNErrorCode(rawValue: MNErrorInt(status.code))!, reason: status.reasonPhrase)
        }
        let result = self.update(path: req.url.path, method: req.method, reqId: req.requestUUIDString, error: error)
        self.save(to: req)
        return result
    }
    
    @discardableResult
    public func update(req:Request, response:Response? = nil)->MNRoutingHistoryItem {
        return self.update(req: req, status: response?.status)
    }
    
    // MARK: Equatable
    public static func == (lhs: MNRoutingHistory, rhs: MNRoutingHistory) -> Bool {
        return lhs.items == rhs.items
    }
    
    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(items)
    }
    
    // MARK: CustomStringConvertible
    public var description: String {
        return items.descriptionLines
    }
}
