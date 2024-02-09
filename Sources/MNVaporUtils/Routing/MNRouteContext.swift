//
//  MNRouteContext.swift
//  bserver
//
//  Created by Ido on 17/11/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppRouteContext")


// Context for a live request handled by the Vapor routing system. It contains info about the route, but also the specific info for this request's session and parameters, such as the current user, accesstoken, request id and more..

extension HTTPStatus {
    // Redictect codes: force redirect:
    //   case .permanent 301  A cacheable redirect.
    //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
    //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
    static let REDIRECT_HTTP_STATUSES : [HTTPStatus] = [.permanentRedirect, .seeOther, .temporaryRedirect]
}

struct MNRouteContextStorageKey : ReqStorageKey {
    typealias Value = MNRouteContext
}

// Ia the runtime / dynamic app route info and context userinfo
public class MNRouteContext  : MNRouteInfoable {

    
    // MARK: MNRouteInfoable properties
    public var title: String? = nil
    public var desc: String? = nil
    public var fullPath: String? = nil
    public var groupName: String? = nil
    public var bodyStreamStrategy: Vapor.HTTPBodyStreamStrategy = .collect
    public var productType: RouteProductType = .webPage
    public var requiredAuth: MNRouteAuth = .none
    public var httpMethods = Set<NIOHTTP1.HTTPMethod>()
    // publicvar rulesNames : [RabacName/* for Rule*/] = [] // Uncomment:
    
    // Mark: Non-MNRouteInfoable properties
    public var errorCode : String? = nil
    public var errorReason : String? = nil
    public var errorText : String? = nil
    public var errorRequestID : String? = nil
    public var errorOriginatingPath : String? = nil
    
    // MARK: Members / properties
    // private (set) public var selfUser : MNUser? = nil
//    private (set) public var selfAccessToken : MNAccessToken? = nil
    public var contextText : String? = nil
    public var isLoggedIn : Bool = false
    public var pageParams : [String:String] = [:]
    
    // MARK: Computed properties
    // Uncomment:
//    var rulesNamesOrNil : [RabacName /* for Rule */]? {
//        return self.rulesNames.count > 0 ? self.rulesNames : nil
//    }
    
    // MARK: Private
    // MARK: Public
    func updateInSession(with req:Request?) {
        guard let req = req else {
            dlog?.warning("updatedSession(with req:) req is nil!")
            return
        }
        
        // Update the MNRouteInfoable properties
        self.update(with: req.route?.mnRoute)
    }
    
    private func asSomeDict(isRouteInfoCodingKeys isck:Bool = true) -> [AnyHashable : Any] {
        var result : [AnyHashable : Any] = [:]
        typealias ck = RouteInfoCodingKeys
        
        
        // Route infoable part:
        
        // Static / the route has this info for any instance of the route:
        result[isck ? ck.ri_productType : "productType"]    = self.productType
        result[isck ? ck.ri_title : "title"]                = self.title
        result[isck ? ck.ri_desc : "desc"]                  = self.desc
        result[isck ? ck.ri_required_auth : "requiredAuth"] = self.requiredAuth
        result[isck ? ck.ri_fullPath : "fullPath"]          = self.fullPath
        result[isck ? ck.ri_group_name : "groupName"]       = self.groupName
        result[isck ? ck.ri_http_methods : "httpMethods"]   = self.httpMethods.strings
        result[isck ? ck.ri_body_stream_strategy : "bodyStreamStrategy"] = self.bodyStreamStrategy
        // result[isck ? ck.ri_permissions : "rulesNames"]     = self.rulesNames  // Uncomment:
        
        // Context part: (dynamic specific requests)
        // result["selfUser"] = self.selfUser
//        result["selfAccessToken"] = self.selfAccessToken
        result["contextText"] = self.contextText
        result["isLoggedIn"] = self.isLoggedIn
        
        // Error part: (dynamic for specific requests)
        result["errorCode"] = self.errorCode
        result["errorReason"] = self.errorReason
        result["errorText"] = self.errorText
        result["errorRequestID"] = self.errorRequestID
        result["errorOriginatingPath"] = self.errorOriginatingPath
        
        return result
    }
    
    // MARK: As various dictionaries:
    public func asDict() -> [AnyHashable : Any] {
        return self.asSomeDict(isRouteInfoCodingKeys: true)
    }
    
    public func asStrHashableDict()-> [String:any CodableHashable] {
        return self.asSomeDict(isRouteInfoCodingKeys: false) as! [String:any CodableHashable]
    }
    
    // Uncomment:
    /*
     public func asRabacDict()-> [RabacKey:Any] {
        var result : [RabacKey:Any] = [:]
        
        // Route infoable part:
        result[.action] = self.productType
        result[.requestedResource] = (self.fullPath != nil) ? AppRoutes.normalizedRoutePath(self.fullPath!) : nil
        
//        result["productType"] = self.productType
//        result["title"] = self.title
//        result["description"] = self.description
//        result["requiredAuth"] = self.requiredAuth
//        result["fullPath"] = self.fullPath
//        result["groupName"] = self.groupName
//        result["httpMethods"] = self.httpMethods.strings
//        result["bodyStreamStrategy"] = self.bodyStreamStrategy
//
//        // Context part:
//        result["selfUser"] = self.selfUser
//        result["selfAccessToken"] = self.selfAccessToken
//        result["contextText"] = self.contextText
//        result["isLoggedIn"] = self.isLoggedIn
//
//        // Error part:
//        result["errorCode"] = self.errorCode
//        result["errorReason"] = self.errorReason
//        result["errorText"] = self.errorText
//        result["errorRequestID"] = self.errorRequestID
//        result["errorOriginatingPath"] = self.errorOriginatingPath

        return result
    }*/
    

    // MARK: Lifecycle
    public init(request req:Request) {
        self.updateInSession(with: req)
    }
    

    // MARK: Equatable
    public static func ==(lhs:MNRouteContext, rhs:MNRouteContext)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    // MARK: Hahsable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(fullPath)
        hasher.combine(groupName)
        hasher.combine(bodyStreamStrategy)
        hasher.combine(productType)
        hasher.combine(requiredAuth.rawValue)
        hasher.combine(httpMethods)
        
        // hasher.combine(selfUser)
//        hasher.combine(selfAccessToken)
        hasher.combine(contextText)
        hasher.combine(isLoggedIn)
        
        hasher.combine(errorCode)
        hasher.combine(errorReason)
        hasher.combine(errorText)
        hasher.combine(errorRequestID)
        hasher.combine(errorOriginatingPath)
    }
    
    public func setError(req:Request, errorTruple:(err:MNError, path:String, requestId:String)) {
        self.setError(req:req, err: errorTruple.err, errorOrigPath: errorTruple.path, errReqId: errorTruple.requestId)
    }
    
    public func setError(req:Request, err:MNError, errorOrigPath:String, errReqId:String) {
        // Fetch best error:
        
        // Use the given error (the req. historys' last navigation's error)
        var foundError : MNError = err
        if Redirect.allHttpStatuses.contains(err.httpStatus ?? .ok), let underlying = err.underlyingError {
            // Error was a redirection, so we use the underlying error (i.e the reason for the redirection)
            foundError = underlying
        }
        
        self.errorOriginatingPath = errorOrigPath
        dlog?.info("context: setError >> \(foundError.code) >> \(foundError.reason)")
        var code = foundError.code
        if let sttCode = foundError.httpStatus?.code {
            code = MNErrorInt(sttCode)
        }
        self.errorCode = "\(code)"
        // NOTE: Make sure to use .reasonLines and not .reason!
        self.errorReason = foundError.httpStatus?.reasonPhrase ?? foundError.reasonsLines ?? foundError.desc
        
        self.errorRequestID = errReqId.replacingOccurrences(of: "REQ|", with: "✓") // ✓ checkmark
        if foundError.reason.count < 20 {
            self.title = (self.title ?? "") + " \(foundError.reason)"
        } else {
            self.title = (self.title ?? "") + " \(code)"
        }

        // Error Text
        self.errorText = foundError.reasonsLines ?? foundError.httpStatus?.reasonPhrase ?? foundError.desc
        if self.errorText != nil, self.errorText == self.errorReason && self.errorText != foundError.desc {
            self.errorText = self.errorText! + ". " + foundError.desc
        }
    }
    
}

public extension MNRouteContext {
    
    
    /// Will return a new AppRouteContext, but also save it into the requests strogate or session storage..)
    /// - Parameter req: request to create / update context for
    /// - Returns: The latest, updated AppRouteContext for the request
    static func setupRouteContext(for req: Request)->MNRouteContext {
        _ = req.session // Initializes session if needed
        if req.routeHistory == nil {
            // Init history
            req.saveToSessionStore(key: ReqStorageKeys.appRouteHistory, value: MNRoutingHistory())
        }
        
        var context : MNRouteContext? = nil
        context = req.getFromSessionStore(key: ReqStorageKeys.appRouteContext)
        if context == nil {
            context = MNRouteContext(request: req)
        } else {
            context?.updateInSession(with: req)
        }
        
        req.saveToSessionStore(key: ReqStorageKeys.appRouteContext, value: context)
        
        if MNUtils.debug.IS_DEBUG {
            if context == nil {
                dlog?.warning("prepContext resulting context is nil!")
            }
            if req.route == nil {
                dlog?.note("prepContext(_ req:Request) req.route is nil!")
            } else if req.route?.mnRoute.fullPath?.asNormalizedPathOnly() != req.url.path.asNormalizedPathOnly() {
                dlog?.note("prepContext(_ req:Request) urls normalized paths are not the equal!! \((req.route?.mnRoute.fullPath).descOrNil) \(req.url.path)")
            }
            
            if let history = req.routeHistory, history.items.count > 0 {
                dlog?.info("Routing history: \(history.items.descriptionLines)")
            }
        }
        
        return context!
    }
}
