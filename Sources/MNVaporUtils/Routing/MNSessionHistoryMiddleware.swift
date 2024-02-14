//
//  MNSessionHistoryMiddleware.swift
//
//
//  Created by Ido on 06/02/2024.
//

import Foundation
import Vapor
import MNUtils
import Logging

fileprivate let dlog : Logger? = Logger(label:"MNSessionHistoryMiddleware")


/// Automatically adds to a user session am "MNSessionHistory" under the key MNRoutingHistoryStorageKey
/// The MNSessionHistory object aggregates all the recent visited urls, erros, and some extra info,
/// This allows the passing of errors on redirect, reading and checking info in past URLs etc.
/// NOTE: The session history is LIMITED to a maxItems anount of records per session, so that we do not flood memory.
/// This system does NOT Persist or LOG the routing history per session.
public class MNSessionHistoryMiddleware : Middleware {
    
    // MARK: Middleware
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        
        guard request.hasSession else {
            preconditionFailure("MNRoutingHistory / MNSessionHistoryMiddleware requires activating Vapor sessions:\n app.middleware.use(app.sessions.middleware) -")
        }
        
        // Add to history:
        let result : EventLoopFuture<Response> = next.respond(to: request).flatMapThrowing { response in
            
            let isFileRequest = request.url.url.pathExtension.count > 0
            let isShouldUpdate = (MNRoutingHistory.SAVES_FILE_REQUESTS || !isFileRequest)
            if isShouldUpdate {
                try request.routeHistory?.update(req: request, response: response)
            }
            
            return response
        }
        
        return result
    }
    
    public let maxItemsPerSession : Int
    
    // MARK: Lifecycle
    public init(maxItemsPerSession: Int = MNRoutingHistory.DEFAULT_MAX_ITEMS) {
        guard maxItemsPerSession > 1 else {
            preconditionFailure("MNSessionHistoryMiddleware maxItemsPerSession must be > 1!")
        }
        
        self.maxItemsPerSession = maxItemsPerSession
    }
}
