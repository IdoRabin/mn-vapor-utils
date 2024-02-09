//
//  VaporRequestEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

public enum RedirectEncoding : Int {
    case base64
    case protobuf
    case normal
}

import Foundation
import Vapor
import Logging
import MNUtils

fileprivate let dlog : Logger? = Logger(label: "VaporRequestEx")


public extension Vapor.Request /* App-specific components */ {
    // TODO: Update paramKeysToNeverRedirect on init from Some app settings / hard-coded
    static var paramKeysToNeverRedirect : [String] = []
    static var appHasSessionMiddleware : Bool = true
    
    var domain : String? {
        guard var host = url.host else {
            return self.application.http.server.configuration.hostname
        }
        
        return MNDomains.sanitizeDomain(host)
    }
    
    var refererURL : URL? {
        if self.headers[.referer].count > 0, let url = URL(string: self.headers[.referer].first!) {
            // Was redirected / referer
            return url
        }
        return nil
    }
    
    var refererRoute : Route? {
        guard let refererURL = refererURL else {
            return nil
        }
        return application.routes.all.first { route in
            route.mnRouteInfo?.canonicalRoute?.matches(url:refererURL) ?? false
        }
    }
    
    // MARK: Saving info to session store
    func saveToSessionStore(key:any ReqStorageKey.Type, value:(any JSONSerializable)?) {
        guard Self.appHasSessionMiddleware else {
            return
        }
        
        guard self.hasSession else {
            return
        }
        
        // Will also save nil (and remove that key)
        if let value = value {
            if let infoStr = value.serializeToJsonString(prettyPrint: false) {
                self.session.data[key.asString] = infoStr
            } else {
                dlog?.warning("saveToSessionStore failed encoding \(key.asString) : \(type(of: value)) using serializeToJsonString()..")
            }
        } else {
            self.session.data[key.asString] = nil
        }
    }
    
    func getFromSessionStore<Value:JSONSerializable>(key:any ReqStorageKey.Type, required:Bool = false)->Value? {
        guard Self.appHasSessionMiddleware else {
            return nil
        }
        
        if let infoStr = self.session.data[key.asString] {
            if let val : Value = Value.deserializeFromJsonString(string: infoStr) {
                return val
            } else {
                dlog?.warning("getFromSessionStore failed decoding \(key.asString) : \(Value.self) using deserializeFromJsonString().. raw string: \(infoStr)")
            }
        } else if required {
            let msg =  "getFromSessionStore failed fetching \(key.asString) : \(Value.self) value was not found in self.session.data"
            dlog?.warning("\( msg )")
            preconditionFailure(msg)
        }
        return nil
    }
    
    func saveToSessionStore(userId:String?) {
        guard Self.appHasSessionMiddleware else {
            return
        }
        
        self.saveToSessionStore(key: ReqStorageKeys.selfUserID, value: userId)
    }

    // MARK: Saving info to request store
    func saveToReqStore<RSK:ReqStorageKey>(key:RSK.Type, value:RSK.Value?, alsoSaveToSession:Bool = false) {
        // Will also save nil (and remove that key)
        self.storage[key] = value
        
        if alsoSaveToSession && Self.appHasSessionMiddleware {
            if let value = value {
                if let val = value as? JSONSerializable {
                    self.saveToSessionStore(key: key, value: val)
                } else {
                    dlog?.note("saveToReqStore key [\(key.asString)] failed to save. \(type(of: value)) is not JSONSerializable. Value was = \(value)")
                }
            } else if alsoSaveToSession && Self.appHasSessionMiddleware{
                self.saveToSessionStore(key: key, value: nil)
            }
        }
    }

    // MARK: Fetching info from session and req. stroage
    /// Returns the stored current self user for this request -
    /// meaning, the request had an access token and the user associaced wth that token was saved in request storage as the self user.
    func getFromReqStore<Value:JSONSerializable>(key:any ReqStorageKey.Type, getFromSessionIfNotFound:Bool = true)->Value? {
        if let anyInfo = self.storage.get(key) {
            if let info = anyInfo as? Value {
                return info
            } else {
                dlog?.note("getFromReqStore key [\(key.asString)] failed to cast as? \(Value.self). Value was: \(type(of: anyInfo)) = \(anyInfo)")
            }
        }
        
        if getFromSessionIfNotFound && Self.appHasSessionMiddleware {
            if let infoStr = self.session.data[key.asString] {
                return Value.deserializeFromJsonString(string: infoStr)
            }
        }
        
        return nil
    }

}

public extension Vapor.Request /* convenience methods and more info  */ {
    
    static let REQUEST_UUID_STRING_PREFIX = "REQ|"
    static let URL_ESCAPE_ENCODED_DETECTION_CHARACTERSET = CharacterSet(charactersIn: "%+&=")
    
    /// Returns the request's ID: each request gets its own uuid for logging purposes.
    /// Example: "2D1ED539-CACF-4DB1-A6E6-2F8343135B3F"
    var requestUUIDString: String {
        get {
            let result : Logger.MetadataValue? = self.logger[metadataKey: "request-id"]
            if let result = result {
                switch result {
                case .string(let str):
                    return Vapor.Request.REQUEST_UUID_STRING_PREFIX + str // UUID as a string
                default:
                    let msg = "Vapor.Request.requestUUIDString element was of an unexpected type."
                    preconditionFailure(msg)
                }
            }
            let msg = "Vapor.Request.requestUUIDString was undefined"
            preconditionFailure(msg)
        }
    }
}

/* xxx
public extension Vapor.Request /* redirects */ {
    
    /// redirects the request to a new url using 3xx redirect status codes. The function is wrapped to allow interception and modification of the redirect.
    /// - Parameters:
    ///   - location: location to redirect the request to
    ///   - type: type of redirection (http statused 301, 303, 307 and their implications)
    ///   - encoding: should the redirect converts all the params to Base64 or protobuf or no conversion. (mostly used in GET redirects, where the params are visible in the URL query..)
    ///   - params:params to definately pass
    ///   - isShoudlForwardAllParams: will pass all params that we can find from this request as the arams for the redirected request. Otherwise, will forward just the params parameter, errorToForward if it exists
    ///   - errorToForward:an error to forward to the redirect as a param / or in the session route history
    ///   - contextStr: textual context of the redirect.
    /// - Returns:a response of the redirect request.
    func wrappedRedirect(to location: String,
                         type: Redirect = .normal,
                         encoding:RedirectEncoding = .normal,
                         params:[String:String],
                         isShoudlForwardAllParams : Bool,
                         errorToForward:MNError? = nil,
                         contextStr:String) -> Response {
        // Redictect codes: force redirect to error page:
        //   case .permanent 301  A cacheable redirect.
        //   case .normal    303  "see other" Forces the redirect to come with a GET, regardless of req method.
        //   case .temporary 307  Maintains original request method, ie: PUT will call PUT on redirect.
        var fullUrl = location;
        
        var params = params
        if isShoudlForwardAllParams && params.count == 0, let urlParams = location.asQueryParams() {
            params.merge(dict: urlParams)
        }
        if !self.hasSession {
            _ = self.session // creates a session if needed
        }
        dlog?.info("PREPARING: wrappedRedirect to: \(location.split(separator: "?").first.descOrNil) params:\(params.descriptionLines) redirect context: [\"\(contextStr)\"]")
        
        switch type {
        case .normal:
            
            // Will force a GET redirect:
            // We need to make sure to collect all the params from other places (such as body or headers) if needed:
            // Add orig Request id and sessionId to params:
            fullUrl = self.prepStatus303RedirectURL(to: fullUrl,
                                                    encoding:encoding,
                                                    params:params,
                                                    isShoudlForwardAllParams:isShoudlForwardAllParams,
                                                    context: contextStr) ?? "unknown_redirect_url"
        case .permanent, .temporary, .permanentPost:
            break
        default:
            break
        }
        
        let response : Response = self.redirect(to: fullUrl, redirectType: type)
        self.routeHistory.update(req: self, response: response)
        if let error = errorToForward {
            self.routeContext.setError(req: self, err: error, errorOrigPath: self.url.string, errReqId: self.id)
        }
        return response
    }
    
    /// Preparing the url for a 303 redirect. All the params areto be passed through the url
    /// http status / redirect 303 "see other" Forces the redirect to come with a GET, regardless of req method.
    /// NOTE: There are some params that are NEVER alowed to be passed / forwarded in a redirect: see AppSettings ....paramKeysToNeverRedirect
    /// - Parameters:
    ///   - baseURL: the base url (path) for the redirect
    ///   - toBase64: should the parameters be counverted to base64?
    ///   - exParams: the params to definately foreard to the next request
    ///   - isShoudlForwardCurParams: should we collate all params from current request and forward them? (this will pull params from many areasof currect request and add them to the url to be requested in the 303 GET.
    ///   - context: context for the redirect - for debigging and logging purposes
    /// - Returns: the new url for a 303 GET request, including the
    func prepStatus303RedirectURL(to baseURL: String,
                                  encoding:RedirectEncoding = .normal,
                                  params exParams:[String:String],
                                  isShoudlForwardAllParams : Bool = false,
                                  context:String) -> String? {
        
        func cleanupParams() {
            params.remove(valuesForKeys: Self.paramKeysToNeverRedirect) // JIC
        }
        
        var result = baseURL
        
        var params : [String:String] = [:]
        params.merge(dict: exParams)
        if isShoudlForwardAllParams {
            // params.merge(dict: self.collatedAllParams())
        }
        cleanupParams()
        
        // Get also params from the baseURL if possible
        let baseURLComps = baseURL.components(separatedBy: "?")
        var path = baseURL.asNormalizedPathOnly()
        if baseURLComps.count > 1 {
            path = baseURLComps.first!
            let logPrefix = (dlog != nil) ? "prepStatus303RedirectURL [..\(path.lastPathComponents(count: 2))]" : "?"
            
            let query = baseURLComps[1..<baseURLComps.count].joined(separator: "?")
            var prevEncoding : RedirectEncoding? = nil
            if let paramsInURL = query.removingPercentEncodingEx?.asQueryParams() {
                for (k, v) in paramsInURL {
                    if (k == MNUtils.constants.BASE_64_PARAM_KEY) {
                        prevEncoding = .base64
                        
                        if let prms = v.explodeBase64IfPossible() {
                            params[MNUtils.constants.BASE_64_PARAM_KEY] = nil
                            params.merge(dict: prms)
                            cleanupParams()
                        } else {
                            dlog?.note("\(logPrefix) failed exploding a base64")
                        }
                    } else if (k == MNUtils.constants.PROTOBUF_PARAM_KEY) {
                        prevEncoding = .protobuf
                        if let prms = v.fromProtobuf()?.asQueryParams() {
                            params.merge(dict: prms)
                            cleanupParams()
                        } else {
                            dlog?.note("\(logPrefix) failed exploding a protobuf")
                        }
                        params[MNUtils.constants.PROTOBUF_PARAM_KEY] = nil
                    } else {
                        prevEncoding = .normal
                        params[k.removingPercentEncodingEx ?? ""] = v.removingPercentEncodingEx
                    }
                }
            }
            if (baseURLComps.count > 2) { dlog?.note("\(logPrefix) Query contained more than one question mark? found: \(baseURLComps.count) parts. prevEncoding found: \(prevEncoding.descOrNil)")}
            
            // Build the url query string from all found and mutated params
            var urlQuery = ""
            if params.count > 0 {
                
                // MUTATING: Prevent some params from being redirected:
                cleanupParams()
                params.remove(valuesForKeys: [MNUtils.constants.BASE_64_PARAM_KEY])
                
                // Create the redirection url params as a string:
                urlQuery = params.toURLQueryString(encoding:encoding)
            }

            if urlQuery.count > 0 {
                result = path + "?" + urlQuery
            }
        } else if params.count > 0 {
            params.remove(valuesForKeys: Self.paramKeysToNeverRedirect) // JIC
            result = path + "?" + params.toURLQueryString()
        } else {
            result = path // Same as in var init, but we want to be readable and clear that in any other case we direct to this path without params
        }
        
        return result
    }
}
 */

/*
public extension Vapor.Request /* selfUser and access token */ {
    
    
    
    var selfUserUUIDString: String? {
        return self.selfUserUUID?.uuidString
    }
    
    var selfUserUUID: UUID? {
        return self.selfUser?.id
    }
    
    var selfUser : MNUser? {
        if let user : MNUser = self.getFromReqStore(key: ReqStorageKeys.selfUser, getFromSessionIfNotFound: true) {
            return user
        }
        
        return self.accessToken?.user
    }
    
    var accessToken : MNAccessToken? {
        return self.getFromReqStore(key: ReqStorageKeys.selfAccessToken)
    }
    
    func getSelfUser(context:String) async throws -> MNUser? {
        if let user : MNUser = self.getFromReqStore(key: ReqStorageKeys.selfUser, getFromSessionIfNotFound: true) {
            return user
        }
        
        var result : MNUser? = nil
        if let accessToken = try await self.getAccessToken(context: "VaporRequestEx.getSelfUser>\(context)") {
            result = accessToken.$user.wrappedValue
            // Save to req storage
            self.saveToReqStore(key: ReqStorageKeys.selfUser, value: result, alsoSaveToSession: false)
        }
        
        return result
    }
    
    /// Get access token from request, session caches or from the bearer token if it is in the request
    /// - Parameter context: string context of the function call
    /// - Returns: access token if found in any way
    func getAccessToken(context:String) async throws -> MNAccessToken? {
        var result : MNAccessToken? = self.getFromReqStore(key: ReqStorageKeys.accessToken, getFromSessionIfNotFound: true)
        if result == nil, let tokenStr = self.headers.bearerAuthorization?.token {
            result = try await MNAccessToken.find(bearerToken: tokenStr, for: self)
        } else if result == nil, let tokenStr = self.cookies[MNAccessToken.TOKEN_COOKIE_NAME]?.string {
            result = try await MNAccessToken.find(bearerToken: tokenStr, for: self)
        }
        
        return result
    }
}

/* xxx
// MARK: MNRouteManager - Indirect access to AppServer.shared.routes
public extension Vapor.Route  /* MNRoutes - route manager etc */ {
    
    static var mnRouteManager : MNRoutingMgr! {
        guard globalMNRouteMgr != nil else {
            let msg = "App init should set globalMNRouteMgr before calling Vapor.Route.mnRouteManager"
            preconditionFailure(msg)
        }
        return globalMNRouteMgr
    }
    
    var mnRouteManager : MNRoutingMgr {
        return Self.mnRouteManager
    }
    
}
 */

public extension Vapor.Parameters {
   /// Vapor.Parameters: Holds dynamic path components that were discovered while routing.
   ///
   /// After this struct has been filled with parameter values, you can fetch
   /// them out by name using `get(_:)`.
   func asDictionary(keys:[String])->[String:String] {
       var result : [String:String] = [:]
       for key in keys {
           if let val = self.get(key) {
               result[key] = val
           }
       }
       
       return result
   }
   
   func asDictionary(urlQuery:String)->[String:String] {
       return urlQuery.asQueryParamsDictionary(pairsDelimiter: "&", keyValDelimieter: "=", recursiveUnescape: false) ?? [:]
   }
   
   func asDictionary(url:URL)->[String:String] {
       if #available(macOS 13.0, *) {
           return self.asDictionary(urlQuery: url.query(percentEncoded: false) ?? "")
       } else {
           // Fallback on earlier versions
           return self.asDictionary(urlQuery: url.query?.removingPercentEncodingEx ?? "")
       }
   }

}

public extension Vapor.URI {
   
   var queryParams : [String:String] {
       let parts = self.query?.components(separatedBy: "&")
       var result : [String:String] = [:]
       parts?.forEach({ part in
           let comps = part.components(separatedBy: "=")
           result[comps.first!] = comps.last!
       })
       return result
   }
}

extension Vapor.Request.Body {
    func asWebformQueryParams(context:String) -> [String:String]? {
        let dataStr = (self.data != nil) ? "\(self.data!.readableBytes)" : "<no data>"
        
        guard let bodyString = self.string, bodyString.count > 0 else {
            // dlog?.note("webformBodyParams requested when no Request.body.string exists (context: \(context) readableBytes:\(dataStr)")
            return nil
        }
        
        guard let dict = bodyString.asQueryParams() else {
            dlog?.warning("webformBodyParams failed at comps.asDictionary (context: \(context) readableBytes:\(dataStr))")
            return nil
        }
        
        return dict
    }
    
    // as BodyJSON
    func asBodyJSON(context:String) -> [String:Any]? {
        return self.asJSONBody(context: context)
    }
    
    func asJSONBody(context:String) -> [String:Any]? {
        // let dataStr = (self.data != nil) ? "\(self.data!.readableBytes)" : "<no data>"
        
        guard let bodyString = self.string, bodyString.count > 2 else {
            // dlog?.note("webformBodyParams requested when no Request.body.string exists (context: \(context) readableBytes:\(dataStr)")
            return nil
        }
        
        do {
            let dict = try JSONSerialization.jsonObject(with: self.data!) as! [String:Any]
            dlog?.success("deserialized: \(dict)")
            return dict
        } catch let error {
            dlog?.warning("failed deserializing JSON! \(error.description)")
        }
        return nil
    }
}

public extension Vapor.Request /* params collection */ {
    /// Deserializes the body as a json into an expected Deserializable Type.
    /// - Returns: the expected type deserialized from the boy's JSON, or nil
    func deserializeBodyJson<AType:JSONSerializable>()->AType? {
        return AType.deserializeFromJsonString(string: self.body.string)
    }
    
    /// Get the url query params only in case this is a GET request and ?param=value; query params are available in the URL PATH, (ignores body)
    var urlQueryParams : [String:String]? {
        if self.method != .GET {
            dlog?.warning("urlQueryParams fetches url query params from a url that was called using http method [\(self.method)]. - Expected method: [GET] ?")
        }
        
        var result = self.url.queryParams
        if result.count > 0 && self.url.query?.contains("%") ?? false {
            for (k,v) in result {
                let newV = v.removingPercentEncodingEx
                if let newV = newV, newV != v {
                    result[k] = newV
                }
            }
        }
        
        guard result.count > 0 else {
            return nil
        }
        return result
    }

    /// Get ALL params regardless of request method - i.e collect body params, POST params, GET params (url query params),  web form formatted body params, or a flat (depth of 1) JSON in the post body params, header params and more., Returns a dictionary of all the above found params and values.
    /// This is a function and not a var to indicate this entails some proccessing / CPU price to get the result.
    /// NOTE: in case of duplicate keys for params, the result is not defined / not trusted. (will log a warning)
    func collatedAllParams(isCollatesHeaders : Bool = false, isRecursivePercentDecode : Bool = true)->[String:Codable] {
        var result : [String:String] = [:]
        
        // |1| get paraams from URL query string (?key=val&key2=val2...)
        if self.url.query?.count ?? 0 > 0 {
            // Get key x val pairs from URL query params:
            // Usually in .GET method requests:
            if let queryParams = self.urlQueryParams, queryParams.count > 0 {
                result.merge(dict: queryParams)
            }
        }
        
        // |2| get paraams from "self.url.queryComponents()" using keys from the query string ?
        if self.url.path.count > 0, let url = URL(string: self.url.path)  {
            var foundKeys = url.queryComponents()?.keysArray ?? []
            foundKeys.append(contentsOf: result.keysArray)
            foundKeys = foundKeys.uniqueElements()
            let dict = self.parameters.asDictionary(keys: foundKeys)
            result.merge(dict: dict)
        } else {
            dlog?.warning("collatedAllParams failed initing URL with self.url.path: \(self.url.path.lastPathComponents(count: 3))")
        }
        
        // |3| get paraams from self body is it contains web form params
        if let prms = self.body.asWebformQueryParams(context:self.url.path) {
            result.merge(dict: prms)
        } else if let objexts = self.body.asBodyJSON(context:self.url.path) {
            var prms : [String:String] = [:]
            for (k, v) in objexts {
                if let v = v as? CustomStringConvertible {
                    let str = "\(v)"
                    prms[k] = str
                }
            }
            result.merge(dict: prms)
        }
        
        // |4| get params from "headers" (if specified)
        if isCollatesHeaders {
            let prms = self.headers.toDictionary(keyForItem: { element in
                element.name
            }, itemForItem: { key, element in
                element.value
            })
            if prms.count > 0 {
                result.merge(dict: prms)
            }
        }
        
        for key in ReqStorageKeys.all {
            if let val = self.storage.get(key) {
                let keyStr = key.asString
                if let val = val as? LosslessStringConvertible {
                    result[keyStr] = val.description
                } else if let val = val as? any MNModel, let idStr = val.id?.uuidString {
                    result[keyStr] = idStr
                } else {
                    dlog?.info("Found key: \(keyStr) .. = .. \(val)")
                }
                
            }
        }
        
        // Explode a base64 param if found
        if let base64 = result[MNUtils.constants.BASE_64_PARAM_KEY], let exploded = base64.explodeBase64IfPossible() {
            result[MNUtils.constants.BASE_64_PARAM_KEY] = nil
            result.merge(dict: exploded)
        }
        
        if (isRecursivePercentDecode) {
            
            // We reverse to allow mutations to the original:
            for key in result.keysArray {
                if let val = result[key] {
                    // dlog?.info("collatedAllParams decoding param tuple: \(key) = \(val)");
                    var newKeyDict : [String:String]? = nil
                    var newValDict : [String:String]? = nil
                    
                    // Optimization: We try to removingPercentEncoding only if we find at least one of a few "indicating" chars in the string:
                    if false && MNUtils.constants.IS_VAPOR_SERVER { // Allow trying to decode a key as an escaped dictionary?
                        if key.contains(anyIn: Self.URL_ESCAPE_ENCODED_DETECTION_CHARACTERSET), let newDict = key.removingPercentEncodingEx?.asQueryParams() {
                            // dlog?.info("collatedAllParams newKeyDict: \(newDict)")
                            newKeyDict = newDict
                        }
                    }
                    
                    if val.contains(anyIn: Self.URL_ESCAPE_ENCODED_DETECTION_CHARACTERSET), let newDict = val.removingPercentEncodingEx?.asQueryParams() {
                        // dlog?.info("collatedAllParams newValDict: \(newDict)")
                        newValDict = newDict
                    }
                    
                    if newKeyDict != nil || newValDict != nil {
                        result[key] = nil
                        result.merge(dict: newKeyDict ?? [:])
                        result.merge(dict: newValDict ?? [:])
                        // dlog?.info("collatedAllParams found an escaped sub param. Result dict is now: \(result.descriptionLines)")
                    }
                }
            }
        }
        
        return result
    }
    
    func anyParameters(fromAnAllParams allParams:[String:Codable] , forKeys keys:[String], isCaseSensitive:Bool = false, isSearchURLQueryParams : Bool = true, isStopOnFirstFound:Bool = false)->[String:Codable] {
        
        var result : [String:Codable] = [:]
        for key in keys {
            for kvariant in key.serializationIssuesVariants() {
                if let paramVal = allParams[kvariant] {
                    result[key] = paramVal
                    break; // we found a value for at least one variant of the iterated key:
                }
            }
            
            if isStopOnFirstFound && result.count > 0 {
                // One result is enough
                break; // we found a value for at least one variant of the iterated key:
            }
        }
        
        return result
    }
    
    /// Get params regardless of request method - i.e collect both body params, POST params, and GET params, and return a dictionary of params and values.
    /// NOTE: Uses collatedAllParams as the basis of the search (Not effiecient if used multiple times - seeusing  anyParameters(fromAnAllParams ...) in conjuction with collatedAllParams() for optimized use.
    /// - Parameters:
    ///   - keys: keys to search for, strings that are the expected keys for the request paramaeters.
    ///   - isCaseSensitive: ignore case sensitivity, default false
    ///   - isSearchURLQueryParams: will additionaly search the URL query params (.GET has params in the URL query after the https://my.site.com/?param1=val2&param2=val2), this lets one treat a POST and GET request qith the same parameter searching tool. default true.
    ///   - isStopOnFirstFound: will stop after finding one param ky/value for the given keys. This is good when searching for a single value result, with multiple possible keys. When false, will return all results found - for instance when searching multiple key-val pairs with multiple kays.
    /// - Returns: dictionary of key-value params and values, or empty dictionary if none found.
    func anyParameters(forKeys keys:[String], isCaseSensitive:Bool = false, isSearchURLQueryParams : Bool = true, isStopOnFirstFound:Bool = false)->[String:Codable] {
        
        let allParams = self.collatedAllParams()
        return self.anyParameters(fromAnAllParams: allParams, forKeys: keys)
    }
}

extension Vapor.Request : MNRouteReadOnlyInfoable {
    public var title: String? {
        return self.routeInfo.title
    }
    
    public var desc: String? {
        return self.routeInfo.desc
    }
    
    public var canonicalPath: String? {
        return self.routeInfo.canonicalPath
    }
    
    public var fullPath: String? {
        return self.url.path
    }
    
    public var groupName: String? {
        return self.routeInfo.groupName
    }
    
    public var bodyStreamStrategy: Vapor.HTTPBodyStreamStrategy {
        return self.routeInfo.bodyStreamStrategy
    }
    
    public var isSecure: Bool {
        return self.routeInfo.isSecure
    }
    
    public var productType : RouteProductType {
        self.routeInfo.productType
    }
    
    public var requiredAuth: MNRouteAuth {
        self.routeInfo.requiredAuth
    }
    
    public var httpMethods: Set<NIOHTTP1.HTTPMethod> {
        return [self.method]
    }
}

public extension Vapor.Request /* MNRoutes / route context and history */ {
    
    // MARK: hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.url.path)
        hasher.combine(self.method.rawValue)
        hasher.combine(self.id)
    }
    
    var routeInfo : (any MNRouteInfoable) {
        guard let route = self.route else {
            preconditionFailure("request: \(self.method) \(self.url.string) has no registered Vapor.Route!")
        }
        
        return route.routeInfo
    }
    
    func updateRouteContext(info:any MNRouteInfoable) {
        self.routeContext.update(withDict: info.asDict())
    }
    
    func updateRouteContext(infoDict:[RouteInfoCodingKeys : Any]) {
        self.routeContext.update(withDict: infoDict)
    }
    
    var routeContext : MNRouteContext {
        var result : MNRouteContext? = self.getFromReqStore(key: ReqStorageKeys.appRouteContext, getFromSessionIfNotFound: false)
        if result == nil {
            result = MNRouteContext(route: self.route!)
            result!.fullPath = self.url.path.asNormalizedPathOnly()
            result!.updateInSession(with: self, info: self.routeInfo)
            
            self.saveToReqStore(key: ReqStorageKeys.appRouteContext, value: result!)
        }

        return result!
    }
    
    var routeHistory : MNRoutingHistory {
        var result : MNRoutingHistory? = self.getFromSessionStore(key: ReqStorageKeys.appRouteHistory)
        
        // Crate and save if doesn't exist:
        if result == nil {
            result = MNRoutingHistory()
            self.saveToSessionStore(key: ReqStorageKeys.appRouteHistory, value: result!)
        }
        
        return result!
    }
}
*/
