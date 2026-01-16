# Contributing to Clipboard

Thank you for your interest in contributing! Here's how you can help.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/Jonathanthedeveloper/Clipboard.git`
3. Open `Clipboard.xcodeproj` in Xcode
4. Create a branch: `git checkout -b feature/your-feature`

## Development

### Requirements
- macOS 14.0+ (Sonoma)
- Xcode 15+
- Swift 5.9+

### Building
1. Open `Clipboard.xcodeproj`
2. Select the `Clipboard` scheme
3. Build and run (⌘R)

### Testing
- Grant Accessibility permissions when prompted
- Test global hotkey (⌘⇧V)
- Test clipboard monitoring with text and images

## Code Style

- Use Swift's standard naming conventions
- Keep functions small and focused
- Avoid force unwrapping (`!`) where possible
- Use `// MARK:` sparingly, code should be self-documenting

## Pull Requests

1. Update the README if you change functionality
2. Keep commits atomic and well-described
3. Ensure the app builds without warnings
4. Test on both light and dark mode

## Issues

- Check existing issues before creating a new one
- Include macOS version and steps to reproduce for bugs
- Feature requests are welcome!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
