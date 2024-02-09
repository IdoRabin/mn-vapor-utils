//
//  VaporURIEx.swift
//  
//
//  Created by Ido on 11/06/2023.
//

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
