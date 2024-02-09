//
//  VaporRouteEx.swift
//  
//
//  Created by Ido on 01/02/2023.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("VaporRouteEx")

// Convenience, Brevity
// MARK: Vapor.Route extension {
public extension Vapor.Route {
    
    // MARK: extending new computed Properties
    
    /// Full path for the Vapor route, formatted and normalized as path only
    var fullPath : String {
        return self.path.fullPath.asNormalizedPathOnly()
    }
    
    /// Returns an MNRoute instance for the Vapor.Route. (instances are unique and kept in the MNRoutes cache as implementor of MNRouteManager)
    var mnRoute  : MNRoute {
        get {
            return self.get(orMake:{ MNRoute(route: self, routeManager: mnRouteManager) })
        }
        // set {
            // ... registerRouteIfNeeded(route:MNRoute) {
        //    self.userInfo = newValue.asDict()
        // }
    }
    
    // MARK: MNRouteManager - Indirect access to AppServer.shared.routes
 
    static var mnRouteManager : MNRoutes!
//    {
//        return AppServer.shared.routes
//    }
    
    var mnRouteManager : MNRoutes {
        return Self.mnRouteManager
    }
    
    // MARK: Private
    func debugValidateMNRoute(context:String) {
        guard MNUtils.debug.IS_DEBUG else {
            return
        }
        
        let fpath = self.fullPath
        guard fpath.count > 0 else {
            dlog?.warning("debugValidateMNRoute [\(context)] has no path! (will set \(fpath)) context: \(context)")
            return
        }
        
        if let _ /*appRoute*/ = mnRouteManager.listMNRoutes(forPaths: [fpath]).first {
            // Found route...
        } else {
            dlog?.warning("debugValidateMNRoute [\(context)] failed finding MNRoute info for path: \(fpath)")
        }
    }
    
    fileprivate func get(orMake createBlock:()->MNRoute)->MNRoute {
        // Get
        //dlog?.info("get(orMake: \(self.fullPath))")
        
        var result : MNRoute? = mnRouteManager.listMNRoutes(forPaths: [self.fullPath]).first
        
        // Or make:
        if result == nil {
            result = createBlock()
            mnRouteManager.registerRouteIfNeeded(mnRoute: result!)
        }
        
        // In any case we setup the retrieved MNRoute in case it isn't fully set up:
        if let result = result {
            if result.route != self {
                dlog?.warning("")
            }
            
            var dbgFields : [String]? = MNUtils.debug.IS_DEBUG ? [] : nil
            
            if (result.fullPath.isNilOrEmpty) {
                result.fullPath = self.fullPath
                dbgFields?.append("fullPath:\(self.fullPath)")
            }
            
            if result.title.isNilOrEmpty {
                result.title = self.fullPath.lastPathComponents(count: 2)
                dbgFields?.append("title:\(result.title.descOrNil)")
            }
            
            if !result.httpMethods.contains(self.method) {
                result.httpMethods.update(with: self.method)
                dbgFields?.append("method:\(self.method.string)")
            }
            
            if MNUtils.debug.IS_DEBUG, let dbgFields = dbgFields, dbgFields.count > 0 {
                dlog?.note("get(orMake:\(self.fullPath) updated fieldsa: \(dbgFields.descriptionsJoined)")
            }
        }
        
        // Will crash
        return result!
    }
    
    // MARK: Public
    @discardableResult
    func setting(productType : RouteProductType = .apiResponse,
                 title:String,
                 description newDesc: String? = nil,
                 requiredAuth : MNRouteAuth = .bearerToken,
                 group:String? = nil)->Route {
       // dlog?.todo("Route[\(self.fullPath)].setting(productType:title:desc:reqAuth:group)")
        let appRoute = self.get(orMake:{MNRoute(route: self, routeManager: self.mnRouteManager)})
        appRoute.productType = productType
        appRoute.title = title
        appRoute.desc = newDesc ?? appRoute.desc
        appRoute.requiredAuth = requiredAuth
        appRoute.groupName = appRoute.groupName ?? group
        debugValidateMNRoute(context: ".setting (productType:title:desc:reqAuth:group)")
        return self
    }
    
    @discardableResult
    func setting(routeInfoable:any MNRouteInfoable)->Route {
        return self.setting(dictionary: routeInfoable.asDict() as? [MNRouteInfo.CodingKeys:AnyCodable] ?? [:])
    }
    
    @discardableResult
    func setting(dictionary : [MNRouteInfo.CodingKeys:AnyCodable])->Route {
        guard dictionary.count > 0 else {
            return self
        }
        
        let mnRoute = self.mnRoute
        mnRoute.update(with: dictionary)
        self.userInfo = mnRoute.asDict()
        mnRouteManager.registerRouteIfNeeded(mnRoute: mnRoute)
        debugValidateMNRoute(context: ".setting (dictionary:)")
        
        return self
    }
}

extension Vapor.Route : Equatable {
    public static func == (lhs: Vapor.Route, rhs: Vapor.Route) -> Bool {
        return lhs.method == rhs.method && lhs.fullPath == rhs.fullPath
    }
}

public extension Vapor.Route /* Rabac rules */ {
//    func setting(rules : [RabacRule]) {
//        let appRoute = self.get(orMake:{MNRoute(route: self)})
//        dlog?.todo("Route[\(self.fullPath)].setting(rules:) appRoute:\(appRoute)")
//
////        let info = self.appRouteInfo
////        if info.isSecure ? ?? ? info.rulesNames.count > rules.count {
////            dlog?.warning("setting(rules) will reduce rules.count to: \(info.rulesNames.count)")
////        }
////        info.rulesNames =  rules.rabacNames
////        dlog?.info("\(self.fullPath).info setting(rules: \(info.rulesNames.descriptionsJoined))")
////        self.setting(routeInfo: info)
////        appRouteManager.registerRouteIfNeeded(mnRoute: self)
////        self.debugValidateMNRoute(context: "Route.setting(rules:)")
////
////        if self.fullPath.contains("/login") {
////            dlog?.info(" setting(rules) - \(rules.rabacNames.descriptionsJoined)")
////        }
//    }
}

public extension Sequence where Element == Vapor.Route {
    var fullPaths : [String] {
        return self.compactMap { route in
            return route.fullPath
        }
    }
}
