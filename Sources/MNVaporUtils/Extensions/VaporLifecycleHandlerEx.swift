//
//  VaporLifecycleHandlerEx.swift
//
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Vapor
import MNUtils

public protocol LifecycleBootableHandler : Vapor.LifecycleHandler {
    func boot(_ app: Vapor.Application) throws
    //deprecated: Use didBoot! (see LifecycleHandler)
    //    func afterBoot(_ app: Vapor.Application)
}

/*
public extension LifecycleBootableHandler /* default implementation */ {
    func boot(_ app: Vapor.Application) throws {}
    
    //deprecated: Use didBoot! (see LifecycleHandler)
    //     func afterBoot(_ app: Vapor.Application) { }
}

*/
