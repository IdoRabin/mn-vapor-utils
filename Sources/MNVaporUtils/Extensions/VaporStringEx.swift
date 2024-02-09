//
//  VaporStringEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.



import Foundation
import Logging
import MNUtils

#if VAPOR
//import Vapor
//import RoutingKit
#endif


fileprivate let dlog : Logger? = Logger(label: "VaporStringEx")

public extension Dictionary where Key : Codable, Value : Codable {

    
    /// Will return a query params formatted string
    /// NOTE: This function does not prefix the resulting string with a question mark!
    /// Example result:
    ///     "myKey=my%20Val%20Escaped&myKey2=myVal2&..."
    ///
    /// - Returns: a url safe / suitable query-params string, escape encoded.
    func toURLQueryString(encoding:RedirectEncoding = .normal, pairsDelimiter pairDelim:String = "&", keyValDelimieter kvDelim:String = "=", isShouldPercentEscape:Bool = true)->String {
        
        var results : [String] = []
        var _encoder : JSONEncoder? = nil
        
        // Singletiny: encoder() acts like a mini-singleton for this function,
        //   this ensures that encoder will be allocated only when / if needed.
        func encoder()->JSONEncoder {
            guard _encoder == nil else {
                return _encoder!
            }
            _encoder = MNJSONEncoder();
            return _encoder!
        }
        
        for (key, val) in self {
            do {
                let encoder = MNJSONEncoder()
                let newKey : String? = try self.encodeValToString(value: key, encoder: encoder, isPercentEscape: isShouldPercentEscape);
                let newVal : String? = try self.encodeValToString(value: val, encoder: encoder, isPercentEscape: isShouldPercentEscape);
                
                if let newKey = newKey, let newVal = newVal, newKey.count > 0 {
                    // split if blocks to be better readable.
                    if isShouldPercentEscape && MNUtils.debug.IS_DEBUG {
                        if (newKey.contains(kvDelim) || newVal.contains(kvDelim)) ||
                           (newKey.contains(pairDelim) || newVal.contains(pairDelim)) {
                            dlog?.warning("toURLQueryString encoding: key:\(newKey) val:\(newVal) contain either pairDelim:\(pairDelim) pr kvDelim:\(kvDelim)")
                        }
                    }
                    
                    // Add to result as a kvDelim-delimited string:
                    // Example: "myKey=my%20Val%20Escaped"
                    results.append([newKey, newVal].joined(separator: kvDelim))
                } else {
                    dlog?.note("toURLQueryString: serializing [\(key),\(val)] failed for an unknown reason.")
                }
                
            } catch let error {
                dlog?.warning("toURLQueryString: serializing Dictionary[Codable:Codable] for key-val pair: [\(key),\(val)] encountered a thrown error: \(error.description)")
            }
        }
        
        // return result as a pairDelim delimited array of key-value tuples transformed already into string
        // Example: "myKey=my%20Val%20Escaped&myKey2=myVal2&..."
        return results.joined(separator: pairDelim);
    }
}

// Extension
public extension RedirectEncoding {
    
    func encode(urlQuery:String?)->String? {
        guard let urlQuery = urlQuery else {
            return nil
        }
        
        var result = urlQuery
        switch self {
        case .normal: return urlQuery
        case .base64:
            result = "\(MNUtils.constants.BASE_64_PARAM_KEY)=\(urlQuery.toBase64())"
        case .protobuf:
            dlog?.warning("IMPLEMENT PROTOBUF!")
            result = "\(MNUtils.constants.PROTOBUF_PARAM_KEY)=\(urlQuery.toProtobuf())"
        }
        
        return result;
        
//        let isShouldConv2Base64 = hadBase64 || toBase64
//        if (MNUtils.debug.IS_DEBUG) {
//            // dlog?.info("\(logPrefix) will be Base64: \(hadBase64 || toBase64) result: \(path)?\(urlQuery)")
//        }
//
//        // If we had a base64 hiding some params, we will encode all params in a base64 wrapper:
//        if isShouldConv2Base64 {
//            urlQuery = "\(AppConstants.BASE_64_PARAM_KEY)=\(urlQuery.toBase64())"
//            let len = min(urlQuery.count - 1, 12) // last 12 chars
//            urlQuery = urlQuery.replacingOccurrences(of: "=",
//                                                     with: "%3D",
//                                                     options: [.backwards, .anchored, .caseInsensitive],
//                                                     range: urlQuery.range(from: NSRange(location:urlQuery.count - len, length:len)))
//        }
    }
    
}

