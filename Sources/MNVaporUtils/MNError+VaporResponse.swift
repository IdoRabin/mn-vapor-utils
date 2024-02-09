//
//  MNError+VaporResponse.swift
//  
//
//  Created by Ido on 12/10/2022.
//

import Foundation
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("MNError+VaporResponse")

extension MNError /* headers */ {
    
    static func bestErrorCode(_ error:Error)-> Int {
        return (error as? Abort)?.code ?? (error as? MNError)?.code ?? (error as? MNErrorable)?.code ?? (error as NSError).code
    }
    static func bestErrorReason(_ error:Error)-> String {
        return (error as? Abort)?.reason ?? (error as? MNError)?.reason ?? (error as? MNErrorable)?.reason ?? (error as NSError).reason
    }
    
    /// See [RFC 7540 § 6.2](https://httpwg.org/specs/rfc7540.html#rfc.section.6.2).
    func headers(wasError:Error? = nil)-> (headers:HTTPHeaders, status:HTTPStatus, reason:String) {
        var resultHdrs : HTTPHeaders = HTTPHeaders();
        var resultStt : HTTPStatus =  self.httpStatus ?? .internalServerError
        var resultReason : String = ""
        
        // AppError reasons:
        if self.reasons?.count ?? 0 > 0 {
            resultReason = self.reasons?.descriptionsJoined ?? "[]"
        }
        
        // inspect the error type
        switch wasError {
        case let abortErr as AbortError:
            // this is an abort error, we should use its status, reason, and headers
            resultReason = abortErr.reason
            // resultHdrs = abortErr.headers
            resultStt = abortErr.status
        case let mnErr as MNError:
            resultReason = mnErr.reason
            // resultHdrs = wasErr.headers
            resultStt = HTTPStatus.custom(code: UInt(mnErr.code), reasonPhrase: mnErr.reason)
        case let nsErr as NSError:
            resultReason = nsErr.localizedDescription
            // resultHdrs = wasErr.headers
            resultStt = HTTPStatus.custom(code: UInt(nsErr.code), reasonPhrase: nsErr.reason)
            dlog?.warning("wasErr as \(type(of: nsErr)): \(String(describing:nsErr))")
        default: // also when AppError or Error:
            // if not release mode, and error is debuggable, provide debug info
            // otherwise, deliver a generic 500 to avoid exposing any sensitive error info
            resultReason = MNUtils.debug.IS_DEBUG && resultReason.count > 0 ? resultReason : "Something went wrong."
            dlog?.warning("wasErr as \(type(of: wasError)): \(self.description) code: \(self.code) \(self.httpStatus.descOrNil)")
            resultStt = self.httpStatus ?? .ok
            break
        }


        resultHdrs.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
        if (MNUtils.debug.IS_DEBUG) {
            // Add headers
        }
        
        // dlog?.info("HEADERS: " + resultHdrs.description);
        return (headers:resultHdrs, status:resultStt, reason:resultReason)
    }
    
}

extension Vapor.Abort : MNErrorable {
    
    // MARK: MNErrorable
    // var reason: String // already implemented for Vapor.Abort
    
    public var desc : String {
        switch self.code {
        case 100..<600: // HttpStatus
            return "TODO.Vapor.Abort.httpStatus.desc|\(self)"
        default:
            return "TODO.Vapor.Abort.desc|\(self)"
        }
    }
    
    public var domain : String {
        var result = "com.\(Bundle.main.bundleName ?? "?").Vapor"
        
        if let domain = "\(self)".components(separatedBy: "_").first {
            result = result + "." + domain
        }
        return result
    }
    
    public var code : MNErrorInt {
        // public var status: HTTPResponseStatus
        if MNUtils.debug.IS_DEBUG {
            if self.status.code > UInt.max {
                DLog.misc["vapor"]?.info("Vapor.Abort status out of bounds!")
            }
        }
        return MNErrorInt(self.status.code)
    }
    
    public var domainCodeDesc : String {
        return "\(self.domain).\(self.code)"
    }
}

public extension MNError {
    
    func asAbort(standInStatusMap map:[MNErrorCode:HTTPResponseStatus], fallback:HTTPResponseStatus = .internalServerError)->Abort {
        var res : HTTPResponseStatus = fallback // worst case, not in map
        if let aeCode = self.mnErrorCode(), let mapped = map[aeCode] {
            res = mapped
        }
        let result = Abort(self.httpStatus ?? res, reason: self.reasonsLines)
        return result
    }
    
    func asAbort(standInHttpStatus:HTTPResponseStatus = .internalServerError)->Abort {
        return self.asAbort(standInStatusMap: [:], fallback: standInHttpStatus)
    }
}
