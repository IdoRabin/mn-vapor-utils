//
//  MNRoutingHistory.swift
//
//
//  Created by Ido on 20/11/2022.
//

import Foundation
import Vapor
import Logging
import MNUtils

fileprivate let dlog : Logger? = Logger(label: "RoutingHistory")
fileprivate let dlogVerbose : Logger? = Logger(label: "RoutingHistoryVe")

// NOTE: VAPOR defines a public typealias HTTPStatus = NIOHTTP1.HTTPResponseStatus

extension Redirect {
    static let all : [Redirect] = [.normal, .permanent, .temporary]
    static let allHttpStatuses : [NIOHTTP1.HTTPResponseStatus] = [Redirect.normal.status, Redirect.permanent.status, Redirect.temporary.status]
}

internal struct MNRoutingHistoryStorageKey : ReqStorageKey {
    typealias Value = MNRoutingHistory
}

// This class should NOT save
public class MNRoutingHistory : JSONSerializable, Hashable, CustomStringConvertible {
    
    public static let DEFAULT_MAX_ITEMS = 15 // Maximum history items per session
    
    // MARK: static
    static let UNKNOWN_REQ_ID = "UNKNOWN_REQ_ID"
    
    // MARK: members
    var items : [MNRoutingHistoryItem] = []
    private var _maxItems : Int = DEFAULT_MAX_ITEMS
    // TODO: Convert to AppSettable or add to the AppSettings...
    // @AppSettable(name: "RoutingHistory.maxItems", default: RoutingHistory.DEFAULT_MAX_ITEMS) static var maxItems : Int
    
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
        req.saveToSessionStore(key: MNRoutingHistoryStorageKey.self, value: self)
    }
    
    /*
    // MARK: public Add / update funcs
    @discardableResult
    func update(path:String, method:HTTPMethod, reqId:String, error:MNError?)->MNRoutingHistoryItem {
        var result : MNRoutingHistoryItem!
        if let historyItem = self.items.first(where: { item in
            item.requestID == reqId && item.httpMethod == method
        }) {
            // Item already existed
            result = historyItem
            if historyItem.mnError == nil {
                historyItem.mnError = error
            } else {
                historyItem.mnError?.appendUnderlyingError(error)
            }
            dlogVerbose?.successOrFail(condition: error != nil, "update EXs \(historyItem) with error: \(error?.reason ?? "<nil>")")
            
        } else {
            
            // New item required:
            let newHistoryItem = MNRoutingHistoryItem(requestID: reqId, path: path, httpMethod: method)
            newHistoryItem.mnError = error
            dlogVerbose?.successOrFail(condition: error != nil, "adding NEW \(newHistoryItem) with error: \(error?.reason ?? "<nil>")")
            
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
            err = MNError(code:MNErrorCode(rawValue: Int(error.status.code))!, reason: error.reason)
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
    */
    
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

public extension Vapor.Request /* MNRoutingHistory / routing history */ {
    
    
    /// Route history for the session, accessible from the requst. Max recent history items can be specified and changed.
    /// NOTE: Requires vapor config of: app.middleware.use(app.sessions.middleware)
    var routeHistory : MNRoutingHistory? {
        return self.routeHistory(maxItems: MNRoutingHistory.DEFAULT_MAX_ITEMS)
    }
    
    /// Route history for the session, accessible from the requst. Max recent history items can be specified and changed.
    /// NOTE: Requires vapor config of: app.middleware.use(app.sessions.middleware)
    func routeHistory(maxItems newMaxItems:Int)->MNRoutingHistory? {
        guard self.hasSession else {
            let msg = "MNRoutingHistory / MNSessionHistoryMiddleware requires activating Vapor sessions:\n app.middleware.use(app.sessions.middleware) -"
            dlog?.note("\(msg)")
            // preconditionFailure()
            return nil
        }
        
        var result : MNRoutingHistory? = self.getFromSessionStore(key: MNRoutingHistoryStorageKey.self)
        
        //  if doesn't exist we Create and save the new history (session):
        if result == nil {
            result = MNRoutingHistory()
            self.saveToSessionStore(key: MNRoutingHistoryStorageKey.self, value: result)
            result
        }
        
        // We assume result was found or created!
        guard let result = result else {
            let msg = "MNRoutingHistory init / get failed for session id: \(self.session.id)"
            dlog?.note("\(msg)")
            return nil
        }
        
        if result.maxItems != newMaxItems {
            result.maxItems = newMaxItems
        }
        return result
    }
}
