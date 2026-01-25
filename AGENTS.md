# Repository Guidelines

## Communication
- 답변은 한국어로 작성합니다.

## Project Structure & Module Organization
- `PhotoOrganizer/` holds the SwiftUI app code (views, Core Data setup, image classifier logic).
- `PhotoOrganizer/Assets.xcassets/` and `PhotoOrganizer/Preview Content/` store app and preview assets.
- `PhotoOrganizer/*.xcdatamodeld` define Core Data models used by the app.
- `PhotoOrganizer/Models/` plus `MyImageClassifier.mlmodel` and `MyImageClassifier.mlproj/` store Core ML artifacts.
- `PhotoOrganizerTests/` and `PhotoOrganizerUITests/` contain XCTest unit and UI tests.
- `PhotoOrganizer.xcodeproj/` is the Xcode project entry point.

## Build, Test, and Development Commands
- `open PhotoOrganizer.xcodeproj` opens the project in Xcode for local development and running.
- `xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 15' build` builds the app for a simulator.
- `xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 15' test` runs unit and UI tests.
- After any feature change or behavior fix, run at least one relevant test command (or a quick simulator run) and note it in your PR.

## Coding Style & Naming Conventions
- Use Swift defaults: 4-space indentation, braces on the same line, and SwiftUI-style formatting.
- Types and protocols use UpperCamelCase (e.g., `ImageClassifier`); variables and functions use lowerCamelCase (e.g., `classifyImage`).
- Keep view files named `*View.swift` and model/utility files descriptive (e.g., `Persistence.swift`).
- No formatter or linter is configured; rely on Xcode formatting and consistent Swift style.

## Testing Guidelines
- Use XCTest for both unit and UI tests.
- Place unit tests in `PhotoOrganizerTests/` and UI tests in `PhotoOrganizerUITests/`.
- Test methods should start with `test` (e.g., `testClassifyImage()`), and avoid relying on network access.
- There is no coverage threshold; prioritize critical paths like classification and Core Data persistence.

## Commit & Pull Request Guidelines
- The current Git history is minimal and does not establish a convention; use short, imperative commit messages (e.g., "Add image picker flow").
- PRs should include a summary, testing steps, and screenshots for UI changes.
- Link related issues or tasks when available and note any model asset updates explicitly.

## Configuration & Security Notes
- Update entitlements only in `PhotoOrganizer/PhotoOrganizer.entitlements` and keep changes minimal.
- Avoid committing large new model checkpoints; prefer exporting `.mlmodel` artifacts only.
