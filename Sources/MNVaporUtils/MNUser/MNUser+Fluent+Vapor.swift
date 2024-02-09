//
//  MNUser+Fluent+Vapor.swift
//  
//
//  Created by Ido on 18/06/2023.
//

import Foundation
import MNUtils
import Fluent
import Vapor

extension MNUser /* force load */ {
    
    public func forceLoadAccessToken(db: any Database) async-> MNResult<MNAccessToken>  {
        return .failure(code: .db_failed_load, reason: "Failed loading MNAccessToken for user \(self.description)")
    }

    public func forceLoadAccessToken(vaporRequest:Request) async-> MNResult<MNAccessToken>  {
        return await self.forceLoadAccessToken(db: vaporRequest.db)
    }
}
