//
//  VaporRedirectEx.swift
//  
//
//  Created by Ido on 08/06/2023.
//

import Foundation
import Vapor

extension Redirect : Equatable {
    public static func == (lhs: Redirect, rhs: Redirect) -> Bool {
        lhs.status == rhs.status
    }
    
}
