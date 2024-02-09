//
//  MN+.swift
//  
//
//  Created by Ido on 15/06/2023.
//

import Foundation
import MNUtils
import Fluent
import DSLogger


fileprivate let dlog : DSLogger? = DLog.forClass("MNUser+Fluent")

extension MNUser : Fluent.Model {
    public static let schema = "mn_users"
}

extension MNUser : Migration {
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        return database.schema(MNUser.schema)
            // MNUUser
            .id() // primary key
        
            // Protocol MNUserable
            .field(CodingKeys.domain.fieldKey,     .string)
            .field(CodingKeys.username.fieldKey,   .string)
            .field(CodingKeys.useremail.fieldKey,  .string)
            .field(CodingKeys.avatar.fieldKey,     .string)
            .field(CodingKeys.status.fieldKey,     .string)
            .field(CodingKeys.info.fieldKey,     .string)
        
            // Relational
            .field(CodingKeys.accessToken.fieldKey,     .uuid, .required, .references(MNAccessToken.schema, MNAccessToken.CodingKeys.id.fieldKey))
            // NOTE: The one-to-one nature of the relatiCon should be enforced in the child model's schema using a .unique constraint on the column referencing the parent model.
        
            // Extra params
            .field(CodingKeys.createdDate.fieldKey,     .datetime)
            .field(CodingKeys.lastUsedDate.fieldKey,    .datetime)
        
            // MNUser
            .ignoreExisting().create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
}
