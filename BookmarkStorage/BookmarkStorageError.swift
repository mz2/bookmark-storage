//
//  BookmarkStorageError.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 04/09/2016.
//  Copyright © 2016 Matias Piipari & Co. All rights reserved.
//

import Foundation

public enum BookmarkStorageError: Swift.Error, LocalizedError {
    case noBookmarkDataWhatsoeverStored
    case noBookmarkDataStored(URL)
    case failedToSave(reason:String)
    case fileURLHasNoSystemFileNumber(URL)
    case noAccessOrFileDoesNotExist(URL)
    case userCancelled
    
    public static var errorDomain: String {
        return "BookmarkStorageError"
    }
    
    public var errorCode: Int {
        switch self {
        case .noBookmarkDataWhatsoeverStored:
            return 1
        case .noBookmarkDataStored:
            return 2
        case .failedToSave:
            return 3
        case .fileURLHasNoSystemFileNumber:
            return 4
        case .noAccessOrFileDoesNotExist:
            return 5
        case .userCancelled:
            return 6
        }
    }

    public var localizedDescription: String {
        switch self {
        case .noBookmarkDataWhatsoeverStored:
            return "No URL data unexpectedly available"
        case .noBookmarkDataStored(let url):
            return "URL data unexpectedly unavailable at \"\(url)\""
        case .failedToSave(let reason):
            return "Failed to save URL data (\(reason))"
        case .fileURLHasNoSystemFileNumber(let url):
            return "Attributes for URL \"\(url)\" are missing the system file number"
        case .noAccessOrFileDoesNotExist(let url):
            return "File at \"\(url)\" does not exist or you do lack permissions to access it"
        case .userCancelled:
            return "User cancelled file access"
        }
    }

    public var helpAnchor: String? {
        return "In some situations, sandbox related file permission issues like this can be resolved by restarting the system or clearing the application container directory under ~/Library/Containers."
    }

    public var recoverySuggestion: String? {
        return "Please contact support if this issue persists."
    }
}
