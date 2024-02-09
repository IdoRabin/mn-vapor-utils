//
//  MNLifecycleHandler.swift
//
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Vapor

/// Same as Vapor.LifecycleHandler but does NOT require @Sendable
public protocol MNLifecycleHandler {
    func willBoot(_ application: Application) throws
    func didBoot(_ application: Application) throws
    func shutdown(_ application: Application)
}

