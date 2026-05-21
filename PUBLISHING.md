# Publishing Rich Text Editor Package

This guide explains how to publish the Rich Text Editor package to pub.dev for public use.

## Pre-Publishing Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md` with changes
- [ ] Update `README.md` if needed
- [ ] Test the example app: `cd example && flutter run`
- [ ] Run tests: `flutter test`
- [ ] Run analysis: `flutter analyze`
- [ ] Review code for quality issues
- [ ] Update GitHub links in `pubspec.yaml`

## Version Update

Update the version in `pubspec.yaml`:

```yaml
version: 1.0.1  # Increment appropriately
```

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH**: 1.0.0
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

## Update CHANGELOG.md

Add an entry for the new version:

```markdown
## [1.0.1] - 2026-05-22

### Added
- New feature description

### Fixed
- Bug fix description

### Changed
- Change description
```

## Testing

### Run Unit Tests

```bash
flutter test
```

### Run Example App

```bash
cd example
flutter run
```

### Check Code Quality

```bash
flutter analyze
```

### Check Formatting

```bash
dart format --set-exit-if-changed lib/
```

## Setup for Publishing

### 1. Create pub.dev Account

- Go to [pub.dev](https://pub.dev)
- Sign in with Google account
- Enable publishing

### 2. Update pubspec.yaml

Ensure these fields are correct:

```yaml
name: rich_text_editor
description: A customizable rich text editor widget for Flutter...
repository: https://github.com/your-username/rich_text_editor
homepage: https://github.com/your-username/rich_text_editor
version: 1.0.1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter
  html: ^0.15.4
  shared_preferences: ^2.3.0
  uuid: ^4.0.0

publish_to: https://pub.dev  # Remove 'none' for publishing
```

### 3. Update Repository Links

Replace `your-username` with your actual GitHub username in:
- `pubspec.yaml` (repository and homepage)
- `README.md` (if mentioned)

## Publishing Steps

### Step 1: Verify Package

Check for publishing issues:

```bash
flutter pub publish --dry-run
```

This will:
- Validate pubspec.yaml
- Check for common issues
- Verify all files are included

### Step 2: Publish

When ready to publish:

```bash
flutter pub publish
```

This will:
- Upload package to pub.dev
- Make it available to all Flutter developers
- Create a new version on pub.dev

### Step 3: Verify on pub.dev

- Visit [pub.dev/packages/rich_text_editor](https://pub.dev/packages/rich_text_editor)
- Check that your package appears
- Verify version and documentation

## After Publishing

### Update Installation Instructions

Users can now install with:

```yaml
dependencies:
  rich_text_editor: ^1.0.1
```

### Monitor Feedback

- Check pub.dev for issues and likes
- Monitor GitHub issues (if applicable)
- Respond to user feedback

### Plan Future Updates

- Track feature requests
- Plan bug fixes
- Plan new versions

## Publishing to Private Repository

If you want to keep the package private:

### Option 1: Private Git Repository

Update `pubspec.yaml`:

```yaml
dependencies:
  rich_text_editor:
    git:
      url: https://github.com/your-username/rich_text_editor.git
      ref: v1.0.1
```

### Option 2: File Path (Development)

Update `pubspec.yaml`:

```yaml
dependencies:
  rich_text_editor:
    path: ../rich_text_editor
```

## Semantic Versioning Guide

### Breaking Changes (Major Version)
- Change API signatures
- Remove public classes/methods
- Change behavior significantly

Example: `1.0.0` → `2.0.0`

### New Features (Minor Version)
- Add new configuration options
- Add new methods to public API
- Backward compatible

Example: `1.0.0` → `1.1.0`

### Bug Fixes (Patch Version)
- Fix bugs
- Internal improvements
- Documentation updates

Example: `1.0.0` → `1.0.1`

## Best Practices

1. **Documentation**: Keep README and examples updated
2. **Testing**: Test thoroughly before publishing
3. **Changelog**: Document all changes
4. **Backward Compatibility**: Avoid breaking changes in minor/patch releases
5. **Versioning**: Follow semantic versioning strictly
6. **Code Quality**: Maintain high code quality standards
7. **Community**: Be responsive to user feedback
8. **Examples**: Keep examples working and up-to-date

## Troubleshooting

### "Package name is reserved"
- The package name might already exist on pub.dev
- Choose a different name

### "Description too long"
- Keep description under 60 characters
- Use README.md for detailed description

### "Missing documentation"
- Ensure README.md exists and is comprehensive
- Document all public API

### "Links not working"
- Verify repository and homepage URLs
- Ensure GitHub repo exists and is public

## Support

For publishing help:
- Visit [pub.dev documentation](https://dart.dev/tools/pub/publishing)
- Check [Dart publish guide](https://dart.dev/guides/libraries/publishing)
- Review common issues on Stack Overflow

---

Happy publishing! 🚀
