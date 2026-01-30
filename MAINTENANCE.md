# Maintenance Policy

This document outlines the long-term maintenance and support policy for the video_player Flutter plugin.

## Supported Versions

### Current Stable Version

- **Version**: 3.0.0
- **Support Status**: ✅ Fully supported
- **Release Date**: TBD

### Platform Support

#### Flutter & Dart

- **Flutter**: >= 3.38.0
- **Dart**: >= 3.10.0 <4.0.0
- **Support Policy**: We support the latest stable Flutter version and maintain compatibility with the most recent stable release.

#### iOS

- **Minimum Version**: iOS 15.0+
- **Tested Versions**: iOS 15.0 - 17.x
- **Support Policy**: We support iOS versions released within the last 3 years
- **Native Frameworks**:
  - AVFoundation
  - AVKit  
  - UIKit
  - MediaPlayer

#### Android

- **Minimum SDK**: API 26 (Android 8.0)
- **Target SDK**: Latest stable
- **Tested Versions**: Android 8.0 - 14
- **Support Policy**: We support Android API levels released within the last 4 years
- **Video Engine**: ExoPlayer

## Version Support Timeline

### Major Versions (x.0.0)

- **Active support**: 12 months after release
- **Security fixes**: 18 months after release
- **Breaking changes**: Allowed in major versions
- **Migration guide**: Provided for all breaking changes

### Minor Versions (3.x.0)

- **Active support**: Until next minor or major version
- **Bug fixes**: Backported when critical
- **No breaking changes**: Guaranteed within same major version

### Patch Versions (3.0.x)

- **Support**: Until next patch, minor, or major version
- **Bug fixes and security patches only**
- **No new features or breaking changes**

## Deprecation Policy

### Deprecation Timeline

1. **Announcement**: Feature marked as `@Deprecated` with clear message
2. **Migration period**: Minimum 6 months (one major version)
3. **Removal**: In next major version only

### Example

```dart
// v3.0.0
@Deprecated('Use PlayerConfiguration.remote() instead. Will be removed in v4.0.0')
PlayerConfiguration({...});

// v3.x.x - Feature still works but shows deprecation warning
// v4.0.0 - Feature removed
```

## Bug Fix Priority

### Critical (Fix within 48 hours)

- Crashes affecting >10% of users
- Data loss or corruption
- Security vulnerabilities
- Complete feature failure

### High (Fix within 1 week)

- Crashes affecting <10% of users
- Memory leaks
- Incorrect behavior in core features
- Platform-specific crashes

### Medium (Fix within 1 month)

- UI glitches
- Performance degradation
- Edge case failures
- Documentation errors

### Low (Fix when possible)

- Minor UI inconsistencies
- Feature requests
- Optimization opportunities
- Nice-to-have improvements

## Security Policy

### Vulnerability Reporting

- **Contact**: Open a security advisory on GitHub (preferred) or email maintainer
- **Response time**: Within 48 hours
- **Fix timeline**: Critical vulnerabilities patched within 1 week
- **Disclosure**: Coordinated disclosure after fix is available

### Security Updates

- Security patches are backported to supported versions
- Security releases are tagged with `[SECURITY]` in CHANGELOG
- CVE identifiers assigned when appropriate

## Breaking Changes

### What Constitutes a Breaking Change

- Changing public API signatures
- Removing public APIs
- Changing behavior of existing APIs (without migration path)
- Changing data formats or contracts
- Raising minimum platform requirements

### Not Breaking Changes

- Adding new optional parameters
- Adding new methods
- Bug fixes that restore documented behavior
- Internal refactoring
- Documentation improvements
- Performance improvements

### Communication

All breaking changes are:
1. Documented in CHANGELOG with clear "BREAKING CHANGE" marker
2. Explained in migration guide
3. Include before/after examples
4. Provide estimated migration time

## Response Time Expectations

### Issues

- **Acknowledgment**: Within 3 business days
- **Triage**: Within 1 week
- **Resolution**: Based on priority (see Bug Fix Priority)

### Pull Requests

- **Initial review**: Within 1 week
- **Feedback iterations**: Within 3 business days per iteration
- **Merge decision**: Within 2 weeks of final review

### Security Issues

- **Acknowledgment**: Within 48 hours
- **Triage**: Within 3 days
- **Fix**: Within 1 week for critical issues

## Compatibility Promise

### What We Guarantee

- **Semantic versioning**: We follow semver strictly
- **No surprise breaking changes**: Breaking changes only in major versions
- **Migration guides**: Provided for all major version upgrades
- **Stable APIs**: Public APIs remain stable within major versions

### What We Don't Guarantee

- **Native platform bugs**: We can't fix bugs in iOS/Android frameworks
- **Undocumented behavior**: Internal implementation details may change
- **Beta features**: Features marked as experimental may change
- **Third-party compatibility**: Behavior with other plugins

## End-of-Life Policy

When a major version reaches end-of-life:

1. **6 months notice**: Announcement in CHANGELOG and README
2. **Security fixes only**: Until EOL date
3. **Migration resources**: Documentation and tools provided
4. **Community support**: Previous versions remain available

### EOL Schedule

- **v1.x**: EOL as of v3.0.0 release
- **v2.x**: EOL 6 months after v3.0.0 stable release
- **v3.x**: Active development

## Platform-Specific Support

### iOS-Only Features

- Screen protection (screenshot prevention, recording detection)
- Native iOS UI components (UIActivityIndicatorView, etc.)

### Android-Only Features

- FLAG_SECURE (always enabled for video content)

### Feature Parity

We strive for feature parity but acknowledge platform limitations:
- Features may be unavailable on one platform due to OS restrictions
- Platform-specific features are clearly documented
- Graceful degradation when features are unavailable

## Maintenance Team

### Current Maintainers

- Primary: [@SunnatilloShavkatov](https://github.com/SunnatilloShavkatov)

### Contribution Recognition

- Regular contributors may be invited as collaborators
- Significant contributions are acknowledged in releases
- Community maintainers are supported with guidance and review

## Review and Updates

This maintenance policy is reviewed:
- **Quarterly**: For minor adjustments
- **Annually**: For major policy changes
- **As needed**: For critical issues or community feedback

Last updated: 2026-01-30

---

## Questions?

- Open an issue for policy clarifications
- Check CONTRIBUTING.md for contribution guidelines
- Review CHANGELOG.md for release history
