//
//  BookmarkStore.swift
//  BookmarkStorage
//
//  Created by Matias Piipari on 04/09/2016.
//  Copyright © 2016 Matias Piipari & Co. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#endif

public struct BookmarkStore {
    /** Return default bookmark store instance that uses user defaults for bookmark storage. */
    public static let defaultStore: BookmarkStore = BookmarkStore(delegate:UserDefaultsBookmarkStorageDelegate())
    
    private(set) public var delegate:BookmarkStorageDelegate
    
    /** Return dictionary with parent URL absolute strings as keys, and arrays of URLs as values. */
    private static func urlsGroupedByAbsoluteParentURLStrings(URLs: [URL]) -> [String: [URL]] {
        var groupedURLs = [String:[URL]]()
        
        for URL in URLs {
            var parentURL = URL
            parentURL.deleteLastPathComponent()
            let parentURLString = parentURL.absoluteString
            let siblingURLs = { () -> [URL] in
                if let existingValue = groupedURLs[parentURLString] {
                    return existingValue + [URL]
                }
                
                return [URL]
            }()
            
            groupedURLs[parentURLString] = siblingURLs
        }
        
        return groupedURLs
    }
    
    private static var knownAccessibleDirectoryURLs:[URL] = {
        do {
            let applicationSupportURL = try FileManager.default.applicationSupportDirectoryURL()
            
            let cachesURL = try FileManager.default.url(for: .cachesDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: true)
            
            return [applicationSupportURL, cachesURL]
        }
        catch {
            print("ERROR: Failed to query / initialize URL for application support or cache directory:\n\(error)")
            return []
        }
    }()
    
    private static func uniqueURLsRequiringSecurityScope(URLs:[URL],
                                                         allowGroupingByParentURL allowGrouping:Bool,
                                                         alwaysAskForParentURLAccess alwaysAccessParentURL:Bool)
        throws -> [URL]
    {
        let possiblyInaccessibleURLs = URLs.filter { url in
            return self.knownAccessibleDirectoryURLs.first(where: { accessibleURL in
                return url.path.hasPrefix(accessibleURL.path)
            }) == nil // Not contained by any known sandbox-accessible directory
        }
        
        if possiblyInaccessibleURLs.count == 0 {
            return []
        }
        
        if !allowGrouping {
            return possiblyInaccessibleURLs
        }
        
        let groupedURLs = urlsGroupedByAbsoluteParentURLStrings(URLs: possiblyInaccessibleURLs)
        
        let uniqueURLs: [URL] = groupedURLs.compactMap { (absoluteParentURLString, URLs) -> URL? in
            // If there are multiple URLs to access in a common parent folder,
            // we'll request access for that folder
            if (alwaysAccessParentURL || URLs.count > 1) {
                return URL(string: absoluteParentURLString)
            }
                // Otherwise, we'll request access for the sole URL
            else if (URLs.count == 1) {
                return URLs.first
            }
            
            return nil
        }
        
        // Filter out sub-URLs of URLs in the array
        let urls: [URL] = uniqueURLs.compactMap { url in
            if let _: URL = uniqueURLs.first(where: { ancestorCandidateURL in
                return url != ancestorCandidateURL && url.absoluteString.hasPrefix(ancestorCandidateURL.absoluteString)
            }) {
                return nil
            }
            return url
        }
        
        return urls
    }
    
    /** Determine which URLs aren't yet covered by a bookmark that we have stored by the storage delegate. */
    public func urlsRequiringSecurityScope(amongstURLs urls: [URL]) throws -> (withoutBookmark: [URL], securityScoped: [URL]) {
        let allBookmarks = try self.delegate.allBookmarkDataByAbsoluteURLString()
        
        var urlsWithoutBookmarks = [URL]()
        var securityScopedURLs = [URL]()
        
        for url in urls {
            var found = false
            
            for absoluteBookmarkedURLString in allBookmarks.keys {
                if (url.absoluteString.hasPrefix(absoluteBookmarkedURLString)) {
                    // Only way to know if the bookmark will actually work is to try resolving & starting access
#if os(iOS)
                    let options: URL.BookmarkResolutionOptions = []
#elseif os(macOS)
                    let options: URL.BookmarkResolutionOptions = [.withSecurityScope]
#endif
                    var isStale = false
                    let securityScopedURL = try URL(
                        resolvingBookmarkData: allBookmarks[absoluteBookmarkedURLString]!,
                        options: options,
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale)
                    
                    if !isStale && securityScopedURL.startAccessingSecurityScopedResource() {
                        securityScopedURLs.append(securityScopedURL)
                        found = true
                    }
                    else {
                        // TODO: ask storage delegate to remove failed bookmark data here!
                    }
                }
            }
            
            if !found {
                urlsWithoutBookmarks.append(url)
            }
        }
        
        return (withoutBookmark: urlsWithoutBookmarks, securityScoped: securityScopedURLs)
    }
    
    private static func fileURL(_ URL:URL, isEqualToFileURL otherURL:URL) throws -> Bool {
        
        //
        // Note: yes, we are aware that if either URL required security-scoped access, the following can only return YES if that access is already granted, as retrieving the properties of a file won't succeed otherwise. TODO: might need to rename this method to reflect that, so that it isn't copied to some other context where that matters.
        //
        let fileManager = FileManager.default
        
        let properties = try fileManager.attributesOfItem(atPath: URL.path)
        
        let otherProperties = try fileManager.attributesOfItem(atPath: otherURL.path)
        
        guard let firstInodeNumber = properties[FileAttributeKey.systemFileNumber] as? NSNumber else {
            throw BookmarkStorageError.fileURLHasNoSystemFileNumber(URL)
        }
        
        guard let otherInodeNumber = otherProperties[FileAttributeKey.systemFileNumber] as? NSNumber else {
            throw BookmarkStorageError.fileURLHasNoSystemFileNumber(URL)
        }
        
        return firstInodeNumber == otherInodeNumber
    }
    
#if os(macOS)
    public func promptUserForSecurityScopedAccess(
        toURL URL:URL,
        withTitle title: String,
        message: String,
        prompt: String = "Choose",
        options: URLAccessOptions) throws -> SecurityScopeAccessOutcome
    {
        var isProbablyADirectory:ObjCBool = false
        let path = URL.path
        let pathExtension = URL.pathExtension
        let uti = FileManager.fileType(forPathExtension: pathExtension)
        
        if !options.contains(.urlMayNotExistYet) && !FileManager.default.fileExists(atPath:path, isDirectory:&isProbablyADirectory) {
            return .failure
        }
        
        let panel = NSOpenPanel()
        panel.title = title
        panel.prompt = prompt
        
        panel.message =
            message
                .replacingOccurrences(of:"${filename}", with: URL.lastPathComponent)
                .replacingOccurrences(of:"${likelyFileKind}", with: isProbablyADirectory.boolValue ? "folder" : "file")
        
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowedFileTypes = {
            if let uti = uti { return [uti, kUTTypeFolder as String] }
            return [kUTTypeFolder as String]
        }()
        panel.allowsOtherFileTypes = true
        panel.delegate = nil
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        
        // Use (lack of) extension as best guess at pre-determining
        // whether URL points to a directory or a regular file
        
        var containingDirURL = URL; containingDirURL.deleteLastPathComponent()
        
        panel.directoryURL = isProbablyADirectory.boolValue ? URL : containingDirURL
        
        var chosenURL:URL? = nil
        
        repeat {
            let result = panel.runModal()
            
            if result != .OK {
                return .cancelled
            }
            
            if let panelURL = panel.url {
                var containingDirectoryURL = URL; containingDirectoryURL.deleteLastPathComponent()
                
                // We accept both if user chose the URL we asked for, or its containing directory
                let expectedURL = { () -> Bool in
                    do {
                        let matches = try type(of:self).fileURL(URL, isEqualToFileURL:panelURL)
                        if matches {
                            return true
                        }
                        return try type(of:self).fileURL(containingDirectoryURL, isEqualToFileURL:panelURL)
                    }
                    catch {
                        return false
                    }
                }()
                
                if expectedURL {
                    chosenURL = panelURL
                }
                
            }
            
        } while chosenURL == nil
        
        let data = try (chosenURL! as NSURL).bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope,
                                                          includingResourceValuesForKeys: nil,
                                                          relativeTo: nil)
        return .success(bookmarkData: data)
    }
#endif
    
    /** Read from, or write to, given URLs with security-scoped access. */
    public func accessURLs(_ urlAccessObjects: [URLAccess],
                           withUserPromptTitle openPanelTitle: String,
                           description openPanelDescription: String,
                           prompt: String,
                           options: URLAccessOptions,
                           accessHandler: URLAccessHandler) throws {
        
        // Gather all URLs that will be accessed
        let allURLsToAccess = urlAccessObjects.flatMap { $0.urls }
        
        let urlsNeedingSecurityScopedAccess = try type(of: self).uniqueURLsRequiringSecurityScope(
            URLs: allURLsToAccess,
            allowGroupingByParentURL: options.contains(URLAccessOptions.groupAccessByParentDirectoryURL),
            alwaysAskForParentURLAccess: options.contains(URLAccessOptions.askForAccessToParentDirectory)
        )
        
        let (urlsToBookmark, _)
            = try self.urlsRequiringSecurityScope(amongstURLs: urlsNeedingSecurityScopedAccess)
        
#if os(macOS)
        // Ask user to pick URLs we need access to
        for url in urlsToBookmark {
            let result = try promptUserForSecurityScopedAccess(
                toURL: url,
                withTitle: openPanelTitle,
                message: openPanelDescription,
                prompt: prompt,
                options: options)
            
            switch result {
            case .success(let bookmarkData):
                try self.delegate.saveBookmark(data: bookmarkData, forURL: url)
                
            case .cancelled:
                throw BookmarkStorageError.userCancelled
                
            case .failure:
                break
            }
        }
#endif
        
        for accessObject in urlAccessObjects {
            try accessHandler(accessObject)
            accessObject.urls.forEach { $0.stopAccessingSecurityScopedResource() }
        }
    }
}
