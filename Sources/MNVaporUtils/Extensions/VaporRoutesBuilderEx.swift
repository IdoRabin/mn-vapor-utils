//
//  VaporRoutesBuilderEx.swift
//
//
//  Created by Ido on 20/01/2024.
//

import Foundation
import MNUtils
import Vapor
import RoutingKit

public extension RoutesBuilder {
    
    /// Register a group of collections with a prefix path for each collection
    /// - Parameter collections: a dictionary of each RouteCollection keyed by the route prefix that will be given for all routes of that collection,
    func register(collections: [([RoutingKit.PathComponent], RouteCollection)]) throws {
        for (aprefix, collection) in collections {
            try self.grouped(aprefix).register(collection: collection)
        }
    }
    
    
    /// Register a group of collections with a prefix path for each collection
    /// - Parameter collections: a dictionary of each RouteCollection keyed by the route prefix that will be given for all routes of that collection,
    func register(collections: [(String, RouteCollection)]) throws {
        let arr = collections.map { elem in
            (elem.0.pathComponents, elem.1)
        }
        try self.register(collections: arr)
    }
    
    /// Create a group of routes using given middlewares and a given subpath
    /// (Convenience)
    func groupEx(_ middlewares: Middleware..., path:RoutingKit.PathComponent..., configure: (RoutesBuilder) throws -> ()) rethrows {
        try self.group(middlewares) { group in
            try configure(group.grouped(path))
        }
    }
    
    func groupEx(_ middlewares: [Middleware], path:[RoutingKit.PathComponent], configure: (RoutesBuilder) throws -> ()) rethrows {
        try self.group(middlewares) { group in
            try configure(group.grouped(path))
        }
    }
    
    func groupEx(_ middlewares: Middleware..., path:String..., configure: (RoutesBuilder) throws -> ()) rethrows {
        let comps = path.flatMap { str in
            str.pathComponents
        }
        try self.groupEx(middlewares, path: comps, configure: configure)
    }
}
