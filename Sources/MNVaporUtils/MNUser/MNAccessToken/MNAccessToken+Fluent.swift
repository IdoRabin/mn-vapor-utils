//
//  MNAccessToken+Fluent.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("MNAccessToken+Fluent")

// MARK: Migration
extension MNAccessToken : Migration {
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
                  
        return database.schema(MNAccessToken.schema)
            .id() // primary key
        
            //
            .field(CodingKeys.createdDate.fieldKey,     .datetime)
            .field(CodingKeys.expirationDate.fieldKey,  .datetime, .required)
            .field(CodingKeys.lastUsedDate.fieldKey,    .datetime)
        
            // Relational
            .field(CodingKeys.user.fieldKey,   .uuid, .required, .references(MNUser.schema, MNUser.CodingKeys.id.fieldKey))
                        .unique(on: CodingKeys.user.fieldKey)
            // NOTE: The one-to-one nature of the relation should be enforced in the child model's schema using a .unique constraint on the column referencing the parent model.
        
            // MNAccessToken
            .ignoreExisting().create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
    
    // TODO:
//    public func forceLoadUser(db:Database) async->MNUser  {
//        do {
//            try await self.$user.load(on: db).get() // force-load user?
//        } catch let error {
//            dlog?.warning("accessToken - forced loading of user error: \(error.description)")
//        }
//        
//        return self.$user.wrappedValue
//    }
}
