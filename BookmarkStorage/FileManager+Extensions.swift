//
//  FileManager+Extensions.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 22/04/2017.
//  Copyright © 2017 Matias Piipari & Co. All rights reserved.
//

import Foundation

public extension FileManager {
    
    public func applicationSupportDirectoryURL() throws -> URL {
        return try self.url(for: .applicationSupportDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true)
    }
    
    public func cachesDirectoryURL() throws -> URL {
        return try self.url(for: .cachesDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true)
    }
    
}
