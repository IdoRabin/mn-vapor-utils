//
//  MNAccessTokenConsts.swift
//  
//
//  Created by Ido on 28/06/2023.
//

import Foundation
import JWT

open class MNAccessTokenConsts {
    // MARK: Consts
    public static let SEPARATOR = "|"
    static let DEFAULT_TOKEN_EXPIRATION_DURATION : TimeInterval = TimeInterval.SECONDS_IN_A_MONTH * 1 // 1 month
    static let ACCESS_TOKEN_UUID_STRING_LENGTH = 36
    static let ACCESS_TOKEN_SUFFIX = "_tk"
    static let ACCESS_TOKEN_EXPIRATION_DURATION : TimeInterval = 2 * TimeInterval.SECONDS_IN_A_WEEK
    static let ACCESS_TOKEN_RECENT_TIMEINTERVAL_THRESHOLD : TimeInterval = 20 * TimeInterval.SECONDS_IN_A_MINUTE
    
    // MARK: Consts ext
    static let ACCESS_TOKEN_JWT_KEY = "JWT_KEY_tk"
    static fileprivate let jwtSigner = JWTSigner.hs256(key: ACCESS_TOKEN_JWT_KEY)
    
    // MARK: Static
    static var emptyToken : MNAccessToken { return MNAccessToken() /* new instance each time */ }
    static let zerosToken = emptyToken
}
