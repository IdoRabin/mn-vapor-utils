//
//  Version.swift
//  
//
// Created by Ido Rabin for Bricks on 17/1/2024.

import Foundation
import MNUtils

typealias Semver = MNSemver

// See: Utils/SemVer.swift
enum PreRelease: String {
    case none = ""
    case alpha = "alpha"
    case beta = "beta"
    case RC = "RC"
}

// https://semver.org/spec/v2.0.0.html
// Swift package PackageDescription also has a Sever2 Version struct defined, but we will be using:

// Hard coded app version:
let MNVAPOR_UTILS_NAME_STR = Bundle.main.bundleName ?? "MNVaporUtils"

// String fields allow only alphanumerics and a hyphen (-)
let MNVAPOR_UTILS_BUILD_NR: Int = 626
let MNVAPOR_UTILS_BUILD_VERSION = Semver(
    major: 0,
    minor: 2,
    patch: 0,
    prerelease: "\(PreRelease.alpha.rawValue)",
    metadata: [String(format: "0x%04X", MNVAPOR_UTILS_BUILD_NR)]
)
