//
//  FluentModelEx.swift
//  
//
//  Created by Ido on 14/07/2022.
//

import Foundation
import Fluent
import MNUtils
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("FluentModelEx")?.setting(verbose: true)

// A string-based enumeration for an enum in the DB (postgres allows defining an enum)
public protocol AppModelStrEnum : JSONSerializable & Hashable & Equatable & RawRepresentable where RawValue == String {
    // db name is the name of this type/schema as a custom enum in the db..
    static var dbTypeName : String { get }
    static var all : [Self] { get }
}

public extension AppModelStrEnum {
    static var dbTypeName : String {
        // db name is the name of this type/schema as a custom enum in the db..
        return "\(Self.self)".camelCaseToSnakeCase()
    }
    
    var dbRawValue: String {
        if MNUtils.debug.IS_DEBUG {
            if self.rawValue != self.rawValue.camelCaseToSnakeCase() ||
                self.rawValue != "\(self)".camelCaseToSnakeCase() {
                dlog?.note("AppModelStrEnum: Expected convension: \(rawValue) should be rawValue of the types value: \(self)")
            }
        }
        return self.rawValue
    }
}


// Extension for model to allow a default schema name based on the classe's type name
// This approach should
// 1.decrease amount and spread of hard-coded static vars spread out for each model across the project
// 2. alow a central point where all schema names are proccessed through
// 3. allow an expected, dependable way to deduce class names from schema names and vice versa, expect
public extension Model {
    static var schema: String {
        // TODO: Pluralizer?
        var result = "\(Self.self)".camelCaseToSnakeCase().replacingOccurrences(ofFromTo: [
            // Enter hard-coded replacements here
            // to default snake case if needed
            // FromString : ToString
            
            // see // https://www.postgresql.org/docs/current/sql-keywords-appendix.html
            // From clann name -> to plural table name
            "MNuser" : "mn_users", // "USER" / "user" is a reserved word in Postgres
            "User"  : "users", // "USER" / "user" is a reserved word in Postgres
        ]).lowercased()
        if !result.hasSuffix("s") {
            result = result + "s"
        }
        
        dlog?.verbose(log:.info, "Model.schema for \(Self.self) is: [\(result)]")
        return result
    }
}
