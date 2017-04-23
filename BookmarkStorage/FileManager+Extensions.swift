//
//  FileManager+Extensions.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 22/04/2017.
//  Copyright © 2017 Matias Piipari & Co. All rights reserved.
//

import Foundation

public extension FileManager {
    
    enum Error: Swift.Error {
        case bundleNotIdentifiable(Bundle)
    }
    
    public func applicationSupportDirectoryURL() throws -> URL {
        guard let identifier = Bundle.main.bundleIdentifier ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String else {
            throw Error.bundleNotIdentifiable(Bundle.main)
        }
        
        return try self.url(for: .applicationSupportDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true).appendingPathComponent(identifier)
    }
    
    public func cachesDirectoryURL() throws -> URL {
        guard let identifier = Bundle.main.bundleIdentifier ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String else {
            throw Error.bundleNotIdentifiable(Bundle.main)
        }
        
        return try self.url(for: .cachesDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true).appendingPathComponent(identifier)
    }
    
}
