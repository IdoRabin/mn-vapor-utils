//
//  MNRoute.swift
//  
//
//  Created by Ido on 16/01/2023.
//

import Foundation
import DSLogger
import MNUtils
import Vapor
import NIO

fileprivate let dlog : DSLogger? = DLog.forClass("AppRoute")

public class MNRoute : MNRouteInfo {
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    private static let MAX_FIND_VROUTE_RECURSIONS = 16
    private(set) public weak var route : Vapor.Route? = nil
    
    public weak var routeManager : MNRoutes? = nil
    public var vaporApp : Vapor.Application? {
        self.routeManager?.vaporApp
    }
    public var eventLoopGroup : Vapor.EventLoopGroup {
        self.routeManager!.vaporApp!.eventLoopGroup
    }
    
    // MARK: Private
    // MARK: Lifecycle
    init(empty:Any? = nil, routeManager : MNRoutes?) {
        super.init()
        self.routeManager = routeManager
    }
    
    public convenience init(route:Vapor.Route, routeManager : MNRoutes?) {
        self.init(empty:nil, routeManager :routeManager)
        self.fullPath = route.fullPath
        self.httpMethods.update(with: route.method)
        self.route = route
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    // MARK: Public
    func debugLogFindAndAssignVaporRoute (depth:Int) {
         
//        if MNUtils.debug.IS_DEBUG, let routeManager = routeManager, let vaporApp = self.vaporApp {
//            let msg = ".findAndAssignVaporRoute(\(depth)/\(Self.MAX_FIND_VROUTE_RECURSIONS)). Still loading for \(self.fullPath.descOrNil)!"
//            var flags : [String] = []
//            if routeManager.isInitialized { flags.append("AppRoutes.isInitializing") }
//            if !vaporApp.isBooted { flags.append("AppServer.isBooting") }
//            if !AppServer.isInitializing {
//                if AppServer.shared.isBooting { flags.append("AppServer.shared.isBooting") }
//                if AppServer.shared.vaporApplication == nil { flags.append("AppServer.shared.vaporApplication == nil") }
//            }
//            if flags.count > 0 {
//                dlog?.info(msg + "\n    failed test for \(self.fullPath.descOrNil): " + flags.descriptionsJoined)
//            } else {
//                dlog?.info(msg + " for \(self.fullPath.descOrNil) for unknown reasons!")
//            }
//
//        }
    }
    
    func isAllowedToFindAndAssign(depth:Int)->Bool {
        func retry() {
            //self.routeManager?.vaporApp.scheduledTimer(timeInterval: 0.2, target: self, selector: @Selector(isAllowedToFindAndAssign(depth:)), userInfo: depth + 1 , repeats: false)
        }
        
        guard depth < Self.MAX_FIND_VROUTE_RECURSIONS else {
            dlog?.info("MNRoute isAllowedToFindAndAssign recursion too deep!")
            return false
        }
        
        guard let routeMgr = self.routeManager else {
            dlog?.info("MNRoute isAllowedToFindAndAssign routeManager is nil!")
            return false
        }
        
        guard routeMgr.isInitialized else {
            dlog?.info("MNRoute isAllowedToFindAndAssign routeManager is not initialized!")
            return false
        }
        
        guard routeMgr.vaporApp != nil else {
            dlog?.info("MNRoute isAllowedToFindAndAssign routeManager vaporApp is nil!")
            return false
        }
        
        if MNUtils.debug.IS_DEBUG {
            debugLogFindAndAssignVaporRoute(depth: depth)
        }
        
        return true
    }
    
    func findAndAssignVaporRoute(depth:Int = 0) {
        
        guard depth < Self.MAX_FIND_VROUTE_RECURSIONS else {
            dlog?.info("MNRoute findAndAssignVaporRoute recursion too deep!")
            return
        }
        
        guard isAllowedToFindAndAssign(depth: depth) else {
            // TODO: Retry timed / scheduled // UNCOMMENT:
            self.eventLoopGroup.next().scheduleTask(deadline: NIODeadline.delayFromNow(0.05)) {
                self.findAndAssignVaporRoute(depth: depth + 1)
            }
            return
        }
        
        if let fpath = self.fullPath, fpath.count > 0 && self.route == nil {
            // Fill route from path
            if let route = vaporApp?.routes.all.first(where: { route in
                route.fullPath.asNormalizedPathOnly() == fpath
            }) {
                self.route = route
                dlog?.success("findAndAssignVaporRoute assigned vapor route for path \(fpath)")
            } else if (self.routeManager?.isBooting ?? true) { //}!AppServer.shared.isBooting {
                dlog?.note("findAndAssignVaporRoute failed to find vapor route for path \(fpath), routeManager is still booting...")
            }
        } else if let route = self.route, self.fullPath?.count ?? 0 == 0 {
            // Fill path from route
            self.fullPath = self.route?.path.fullPath.asNormalizedPathOnly()
            dlog?.note("findAndAssignVaporRoute assigned full path \(self.fullPath.descOrNil) frmo route: \(route.description)")
        }
    }
    
    @discardableResult
    func setting(routeInfo:MNRouteInfo)->MNRoute {
        dlog?.todo("AppRoute[\(self.fullPath.descOrNil)].setting(routeInfo:)")
        return self
    }
    
    @discardableResult
    func setting(dictionary : [MNRouteInfo.CodingKeys:AnyCodable])->MNRoute {
        dlog?.todo("AppRoute[\(self.fullPath.descOrNil)].setting(dictionary:)")
        return self
    }
}
