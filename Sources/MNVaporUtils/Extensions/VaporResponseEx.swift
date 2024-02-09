//
//  VaporResponseEx.swift
//
//
//  Created by Ido on 20/01/2024.
//

import Foundation
import NIO // KeepAliveState and more..
import Vapor

public extension Vapor.Response {
    public static func NotImplemented(description:String? = "Not implemented.")->Response {
        let ax : String? = nil
        return Response(status: .notImplemented, // 501s
                        version: .http1_1,
                        headersNoUpdate: HTTPHeaders([]),
                        body: Body(stringLiteral: """
HTTP \(HTTPResponseStatus.notImplemented)\nNot implemented:
description: \(description)
"""))
    }
}
