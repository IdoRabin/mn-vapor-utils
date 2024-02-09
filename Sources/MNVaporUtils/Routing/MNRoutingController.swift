//
//  MNRoutingController.swift
//  
//
//  Created by Ido on 28/05/2023.
//

import Foundation
import Vapor
import Fluent
import FluentKit
import Leaf
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("MNRoutingController")


//
public protocol MNRouterable {
    var allRoutePaths : [String] { get }
    
    func setPermissions(paths:[String])
    func pathComp(_ sub: String)-> RoutingKit.PathComponent
    
    // Same paradism as LifecycleHandler
//    func willBoot(_ application: Application)
//    func boot(_ application: Application, routes: Vapor.RoutesBuilder) throws // Alos required by: ...
//    func didBoot(_ application: Application)
//    func shutdown(_ application: Application)
}

public extension MNRouterable /* default implementations */  {
    func setPermissions(paths:[String]) {
        dlog?.note("\(Self.self) needs to override func setPermissions(paths:[String]) for its specific permissions")
    }
}

/// A subclassable route collection with app-specific util and convenience functions:
public class MNRoutingController : NSObject/* to allow override of base class funcs in extensions */, RouteCollection, MNRouterable {
    // MARK: Const
    
    // MARK: Static
    fileprivate static let STR_OPTL = "Optional("
    
    // MARK: properties
    private let appRoutes : MNRoutes /* app routes manager*/
    private var _prevRoutes : [String] = []
    private var _newRoutes : [String] = []
    
    // MARK: Properties / members
    
    // MARK: Computed Properties
    var application : Vapor.Application? {
        return appRoutes.vaporApp
    }
    
    public var allRoutePaths : [String] {
        return _newRoutes.removing(objects: _prevRoutes).uniqueElements()
    }
    
    public var allMNRoutes : [MNRoute] {
        return appRoutes.listMNRoutes(forPaths: self.allRoutePaths)
    }
    
    public var secureMNRoutes : [MNRoute] {
        return allMNRoutes.filter { route in
            route.isSecure
        }
    }
    
    /// Returns all the route paths that are NOT secured (route has no Rabac rules)
    public var unsecureMNRoutes : [MNRoute] {
        return allMNRoutes.filter { route in
            !route.isSecure
        }
    }
    
    public var allVaporRoutes : [Vapor.Route] {
        return appRoutes.listMNRoutes(forPaths: self.allRoutePaths).compactMap { appRoute in
            return appRoute.route
        }
    }
    
    public var secureVaporRoutes : [Vapor.Route] {
        return allMNRoutes.filter { route in
            route.isSecure
        }.compactMap { appRoute in
            return appRoute.route
        }
    }
    
    /// Returns all the route paths that are NOT secured (route has no Rabac rules)
    public var unsecureVaporRoutes :  [Vapor.Route] {
        return allMNRoutes.filter { route in
            !route.isSecure
        }.compactMap { appRoute in
            return appRoute.route
        }
    }
    
    /// Returns all the route paths that are secured (route has at least one Rabac rule)
    public var secureRoutePaths : [String] {
        return secureMNRoutes.fullPaths
    }
    
    /// Returns all the route paths that are NOT secured (route has no Rabac rules)
    public var unsecureRoutePaths : [String] {
        return unsecureMNRoutes.fullPaths
    }
    
    // MARK: Private
    
    
    // MARK: Lifecycle
    public init(app:Vapor.Application) {
        self.appRoutes = MNRoutes(app: app)
    }
    
    // MARK: MNRoutingControllable
    public func willBoot(_ application: Application) {
        guard self.application === application else {
            dlog?.warning("willBoot requires: Vapor.Application INSIDE self.appRoutes : MNRoutes")
            return
        }
        
        self._prevRoutes = application.routes.all.map { route in
            return route.path.fullPath
        }.uniqueElements()
    }
    
    public func didBoot(_ application: Application) {
        guard self.application === application else {
            dlog?.warning("didBoot requires: Vapor.Application INSIDE self.appRoutes : MNRoutes")
            return
        }
        self._newRoutes = application.routes.all.map { route in
            return route.path.fullPath
        }.uniqueElements()
    }

    // MARK: RouteCollection
    public func boot(_ application: Application, routes: Vapor.RoutesBuilder) throws {
        // TODO: dispatch once per instance
        dlog?.info("\(Self.self) should implement boot(routes: Vapor.RoutesBuilder), no need to call super!")
    }

    public func boot(routes: Vapor.RoutesBuilder) throws {
        guard let app = self.application else {
            let msg = "boot(routes:) failed: AppServer vaporApplication is nil."
            dlog?.warning(msg)
            throw MNError(code: .misc_failed_loading, reason: msg)
        }
        try boot(app ,routes: routes)
    }
    
    public func shutdown(_ application: Application) {
        dlog?.note("IMPLEMENT shutdown for AppRoutingController")
    }
    
    // MARK: Public
    func vaporRoutes(forPaths paths:[String])->[Vapor.Route] {
        let result : [Vapor.Route] = self.application?.routes.all.filter({ route in
            paths.contains(route.path.fullPath)
        }) ?? []
        return result
    }
    
    func vaporRoutes()->[Vapor.Route] {
        let result : [Vapor.Route] =  self.application?.routes.all ?? []
        return result
    }
    
    func appRouteInfos()->[String:[MNRouteInfo]] {
        let result = self.appRoutes.listMNRoutes(forPaths: self.allRoutePaths.uniqueElements()).groupBy { element in
            element.fullPath
        }
        return result
    }
    
    /// Convenience metod - returns a Vapor.PathComponent initilaized to the given string
    /// - Parameter string: string for the path component
    /// - Returns: a Vapor.PathComponents pointing to the given string
    public func pathComp(_ sub: String)->RoutingKit.PathComponent {
        return PathComponent(stringLiteral: sub)
    }
    
}

/*
    
    
 /// returns a dictionary of all rabacRules applicable for each route path
 /// - Returns: dictionary of route path as key, and array of ranacRules as value
 // * Uncomment
 // Uncomment:
 /*
 func appRouteRabacRules()->[String /* route path */ :[RabacRule]] {
     var result : [String:[RabacRule]] = [:]
     for appRoute in AppServer.shared.routes.listAppRoutes(forPaths: self.allRoutePaths.uniqueElements()) {
         // let fpath = appRoute.fullPath?.asNormalizedPathOnly()
         let rules = Rabac.shared.rules(byNames: appRoute.rulesNames)
         let resourcePrefix = RabacResource.className() + "."
         for rule in rules {
             if let paths = rule.resourcesWanted?.map({ str in
                 return str.replacingOccurrences(of: resourcePrefix, with: "")
             }) {
                 for path in paths {
                     var arr : [RabacRule] = result[path] ?? []
                     if !arr.contains(rule) {
                         arr.append(rule)
                         result[path] = arr
                     }
                 }
             }
         }
     }
     return result
 }
    */
    
    
    @objc
    open dynamic func setPermissions(paths:[String]) throws {
        let msg = "AppRoutingController \(Self.self) needs to implement setPermissions(paths:)"
        dlog?.note(msg)
        throw MNError(code:.misc_failed_crypto, reason: msg)
    }
    
    
    // TODO: Check and remove this func because it duplicates StringEx.asQueryParams() with less ability. mimics
    /*
    static /* protected */ func urlQueryToDict(quesryString queryStr:String)->[String:String] {
        var queryStrings : [String: String] = [:]
        let str = queryStr.removingPercentEncodingEx
        for pair in (str ?? queryStr).components(separatedBy: "&") {
            if pair.count >= 1 {
                let tuple = pair.components(separatedBy: "=")
                let key   = tuple[0]
                let value = tuple[1].replacingOccurrences(
                    // Un-Percent Esacpe:
                    ofFromTo: ["+" : " ",
                               "%20" : " ",
                               "%7c" : "|",
                               "%3d" : "=",
                               "%03d" : "="], caseSensitive: false)
                    .removingPercentEncodingEx ?? ""
                queryStrings[key] = value
            }
        }
        return queryStrings
    }
    */
}
*/
