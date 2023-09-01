//
//  FileManager+Extensions.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 22/04/2017.
//  Copyright © 2017 Matias Piipari & Co. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#endif

public extension FileManager {
    enum Error: Swift.Error, LocalizedError, CustomNSError {
        case bundleNotIdentifiable(Bundle)

        public var errorCode: Int {
            switch self {
            case .bundleNotIdentifiable:
                return 1
            }
        }

        public var localizedDescription: String {
            switch self {
            case .bundleNotIdentifiable(let bundle):
                return "Bundle at URL \(bundle.bundleURL) is not identifiable"
            }
        }

        public var recoverySuggestion: String? {
            return "Please contact support if this problem persists."
        }
    }
    
    func applicationSupportDirectoryURL() throws -> URL {
        guard let identifier = Bundle.main.bundleIdentifier ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String else {
            throw Error.bundleNotIdentifiable(Bundle.main)
        }
        
        return try self.url(for: .applicationSupportDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true).appendingPathComponent(identifier)
    }
    
    func cachesDirectoryURL() throws -> URL {
        guard let identifier = Bundle.main.bundleIdentifier ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String else {
            throw Error.bundleNotIdentifiable(Bundle.main)
        }
        
        return try self.url(for: .cachesDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true).appendingPathComponent(identifier)
    }
    
#if os(macOS)
    /**
     Return UTI for a given path extension.
     */
    class func fileType(forPathExtension pathExtension: String) -> String? {
        if let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension.lowercased() as CFString, nil) {
            return String(UTI.takeUnretainedValue())
        }
        return nil
    }
#endif
}
