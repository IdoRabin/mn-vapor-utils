//
//  VaporLifecycleHandlerEx.swift
//  
//
//  Created by Ido on 27/05/2023.
//

import Foundation
import Vapor
import MNUtils

public protocol LifecycleBootableHandler : Vapor.LifecycleHandler {
    func boot(_ app: Vapor.Application) throws
    //deprecated: Use didBoot! (see LifecycleHandler)
    //    func afterBoot(_ app: Vapor.Application)
}

public extension LifecycleBootableHandler {
    func boot(_ app: Vapor.Application) throws {}
    
    //deprecated: Use didBoot! (see LifecycleHandler)
    //     func afterBoot(_ app: Vapor.Application) { }
}
