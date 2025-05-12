## 0.4.1

- Reverted path library version from minimum of 1.9.1 to =1.9.0 to support flutter 3.27.+ versions.

## 0.4.0

- Added support for multiple storage types: Disk, FTP, and Google Cloud.
- Introduced `StorageType` enum and factory extensions for creating storage instances.
- Enhanced error handling for missing or invalid configuration parameters.
- Improved build command functionality with support for environment variable handlers.
- Updated dependencies to ensure compatibility with Dart SDK >=3.6.0.
- Added examples for environment variable usage in Flutter applications.
- Refactored `InfraBuildCommand` to streamline build and distribution processes.

## 0.3.0

- Added workarounds Cloud signing permission error when no development certificate found.
- Updated the bdlogging package to v1.0.0

## 0.2.1

- Added few workarounds to flutter tools issues
- https://github.com/flutter/flutter/issues/106612
- https://github.com/flutter/flutter/issues/113977

## 0.2.0

- Improve support of automatic signing for iOS apps.

## 0.1.1

- Add possibility to auto-create a certificate if there's no valid one when doing project setup.
- Fix bug were auto-select the first certificate of the profile and the profile has many certificates.

## 0.1.0

- Raise min. Dart SDK to v3.0
- Upgrade dependencies
- Add new extension: `FileExtensions` to zip/unzip files

## 0.0.2

- Added support for dotEnv file.
- Error description and logging improvement.

## 0.0.1

- Initial version.
- Build and sign ios application.
- Disk infrastructure manager.