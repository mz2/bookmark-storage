# BookmarkStorage [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A pure Swift API for dealing with security scoped bookmark data.

- Provides an API for persisting security scoped bookmark data, and for accessing URLs potentially requiring security scoped access.
- Bookmark data persistence is handled through a 'storage delegate' protocol.
- An `NSUserDefaults` backed implementation is provided for the storage delegate.

#### INSTALLATION

##### Swift Package Manager

Add BookmarkStorage to your Swift package as a dependency by adding the following to your Package.swift file in the dependencies array:

```swift
.package(url: "https://github.com/mz2/BookmarkStorage.git", from: "<version>")
```

If you are using Xcode 11 or newer, you can add BookmarkStorage by entering the URL to the repository via the File menu:

```
File > Swift Packages > Add Package Dependency...
```

#### USAGE

Adapting from a test included in the test suite for the framework, here's how you can use Carpaccio:

1. Construct a `BookmarkStore`:

```swift
let bookmarkStore = BookmarkStore(delegate:UserDefaultsBookmarkStorageDelegate())
```

2. Wrap the URL(s) you wish to access into an object conforming to `URLAccess`. A reference `SimpleURLAccess` struct is provided:

```swift
let URLAccess = SimpleURLAccess()
```

3. Access the URL:

```swift
// The `description` argument accepts template strings that are replaced automatically if encountered as a substring in the paramter value.
// ${likelyFileKind}: either 'file' or 'folder' based on whether the file is thought to be a folder or not.
// ${filename}: the filename (last path component of the URL being requested may be the containing folder or the file passed in as the URL to access)
// 

// if multiple URLs are passed in, you can optionally group accesses so only one Open dialog is shown per containing directory… and to always ask for the containing directory rather than the file itself (useful if you're going to soon need to otherwise ask the user again for other files in the same directory).
let options:URLAccessOptions = .groupAccessByParentDirectoryURL
							   .union(.alwaysAskForAccessToParentDirectory)

try bookmarkStore.accessURLs([ URLAccess ],
                             withUserPromptTitle:"Title for the open panel prompt, if own shown at all.",
                             description:"Description shown in the open dialog, if one is shown at all.",
                             options:options,
                             accessHandler:{ … block where you return either nil or an error if an error occurred …})
```

You can also call `promptUserForSecurityScopedAccess` on the bookmark store to directly prompt user for security scoped bookmark data.