//
//  PostgresCellEx.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation

#if NIO || VAPOR || FLUENT || POSTGRES

import Fluent
import FluentKit
import PostgresNIO
import NIOFoundationCompat

public extension PostgresCell {
    var stringValue : String? {
        switch self.dataType {
        case .text, .name:
            // Create String from ByteBuffer
            if let bytesCount = self.bytes?.readableBytes, let str = bytes?.getString(at: 0, length: bytesCount, encoding: .utf8) {
                return str
            }
        default: break
        }
        return nil
    }
    
    var dataValue : Data? {
        switch self.format {
        case .binary:
            // Create Data from ByteBuffer
            if let bytesCount = self.bytes?.readableBytes, let data = bytes?.getData(at: 0, length: bytesCount, byteTransferStrategy: .noCopy) {
                return data
            }
        default: break
        }
        return nil
    }
}

#endif
