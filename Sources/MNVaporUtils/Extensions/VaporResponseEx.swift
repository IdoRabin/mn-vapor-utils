//
//  VaporResponseEx.swift
//
//
//  Created by Ido on 20/01/2024.
//

import Foundation
import NIO // KeepAliveState and more..
import Vapor
import MNUtils

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
    
    public var asMNError : MNError? {
        guard self.status != .ok else {
            return nil
        }
        
        var reason = self.status.reasonPhrase ?? "Unknown error for response"
        return MNError(code: MNErrorCode(rawValue: Int(self.status.code))!, reason: reason)
    }
    
    public var asMNErrorStruct : MNErrorStruct? {
        guard let mnError = self.asMNError else {
            return nil
        }
        var errStruct = MNErrorStruct(mnError: mnError)
        // errStruct.update(originatingPath: )
        return errStruct
    }
}
