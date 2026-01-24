## [2.1.0] - 2026-01-24

### Fixed
- **iOS**: Fixed critical memory leaks in AVPlayer observer lifecycle management
- **iOS**: Resolved KVO crashes when removing observers during deallocation
- **iOS**: Eliminated deadlock risk in observer cleanup on main thread
- **Android**: Fixed lifecycle crashes caused by Handler callbacks after disposal
- **Android**: Resolved null pointer exceptions through proper null handling
- **Android**: Fixed EGLSurfaceTexture cleanup sequence
- **Flutter**: Corrected method channel result handling (replaced undocumented fallback with proper error handling)
- **Flutter**: Fixed silent failures - all errors now propagate with logging

### Changed
- **Error Handling**: Standardized error propagation across all platforms with debug-mode logging
- **iOS**: Centralized observer lifecycle management with atomic disposal guards
- **Android**: Improved activity attachment safety and resource cleanup ordering
- **Android**: Enhanced Handler and Runnable cleanup to prevent memory leaks
- **Security**: Enforced HTTPS-only URL validation at API boundary
- **API**: Clarified return value contracts and error behavior in documentation
- **Documentation**: Updated platform-specific behavior notes for production use

### Removed
- **Download functionality**: Completely removed offline playback and download features
- **Unsafe code patterns**: Eliminated force unwraps and unchecked null assertions
- **Deprecated APIs**: Removed unused download-related interfaces and models

### Added
- **Testing**: Regression test suite covering URL validation, method channel contracts, and error propagation
- **Documentation**: Added comprehensive deployment and monitoring guidelines
- **Security**: Added test coverage for HTTPS enforcement and URL injection prevention

## 2.0.0

* Comprehensive dartdoc documentation added for all public APIs
* README updated with accurate usage examples and platform requirements
* Removed references to discontinued download features
* Added clear error documentation and platform-specific behavior notes
* Improved developer experience with detailed API documentation

## 1.0.4

* TODO: Describe initial release.

## 1.0.3

* TODO: Describe initial release.

## 1.0.2

* TODO: Describe initial release.

## 0.0.1

* TODO: Describe initial release.
