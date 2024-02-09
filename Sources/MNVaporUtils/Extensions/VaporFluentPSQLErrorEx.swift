//
//  VaporFluentPSQLErrorEx.swift
//
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import Fluent
import FluentKit
import FluentPostgresDriver
import Vapor

public extension PSQLError {

    /// PSQLError full description including the backing info.
    var fullDescription : String {
        var arr = [
            "<PSQLError",
            "code \(self.code)",
            "file: \(self.file.descOrNil)",
            "ln# \(self.line.descOrNil)",
            "query: \(self.query.descOrNil)",
            "serverInfo: \(self.serverInfo.descOrNil)",
            " >"
        ]
        arr.append("")
        return arr.joined(separator: " ")
    }
}
