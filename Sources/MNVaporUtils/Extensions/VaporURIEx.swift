//
//  VaporURIEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Vapor
import MNUtils

public extension URI {
    var url : URL {
        return URL(string: self.string)!
    }
    
    func asNormalizedPathOnly()->String {
        return self.string.asNormalizedPathOnly()
    }
    
}
