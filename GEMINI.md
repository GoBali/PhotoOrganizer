# PhotoOrganizer

## Communication
- **Responses must be provided in Korean.**

## Project Overview
**PhotoOrganizer** is a Swift-based iOS/macOS application built with **SwiftUI** that helps users organize their photo libraries using machine learning. It leverages **Core ML** (specifically a `MyImageClassifier` model) to automatically classify imported photos and **Core Data** for persistent storage of photo metadata, tags, and classification results.

### Key Features
- **Photo Import:** Import photos via `PhotosPicker`.
- **Auto-Classification:** Automatically classifies images using a bundled Core ML model.
- **Organization:** Filter by category (classification label), search by tags/notes, and manually add tags/notes.
- **Persistence:** Stores image references and metadata using Core Data.

## Architecture & Structure
The project follows a standard SwiftUI app structure with Core Data integration:

- **Entry Point:** `PhotoOrganizer/PhotoOrganizerApp.swift` initializes the Core Data stack and the `PhotoLibraryStore`.
- **UI Layer:**
  - `ContentView.swift`: Main navigation and container for `LibraryView`.
  - `LibraryView`: Displays the grid of photos, filter/search controls, and import functionality.
  - `PhotoGridView` / `PhotoGridItemView`: Components for rendering the photo grid.
  - `PhotoDetailView`: Detailed view for a single photo, allowing reclassification, tagging, and note editing.
- **Data Layer:**
  - `Persistence.swift`: Manages the Core Data stack (`NSPersistentContainer`).
  - `PhotoAsset` (Core Data Entity): Represents a photo with attributes for classification, tags, notes, and file paths.
  - `Tag` (Core Data Entity): Represents user-defined tags associated with photos.
- **ML Layer:**
  - `MyImageClassifier.mlmodel`: The Core ML model used for image classification.
  - `ImageClassifier.swift`: Wrapper logic for interacting with the Core ML model.

## Building and Running
This project uses Xcode. You can build and run it using the Xcode IDE or the command line.

### Command Line
**Build for Simulator (iPhone 15):**
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 15' build
```

**Run Tests:**
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 15' test
```

### Xcode
1. Open the project: `open PhotoOrganizer.xcodeproj`
2. Select the `PhotoOrganizer` scheme.
3. Choose a destination (e.g., a Simulator or connected device).
4. Run (Cmd+R).

## Development Conventions
- **SwiftUI:** Use functional views and `@StateObject` / `@EnvironmentObject` for data flow.
- **Core Data:** Access the context via the environment `\.managedObjectContext`.
- **Styling:** Follow standard Apple Human Interface Guidelines.
- **Testing:**
    - Unit tests in `PhotoOrganizerTests/`.
    - UI tests in `PhotoOrganizerUITests/`.
    - **Always run relevant tests after making any code changes and report the results.**
- **Assets:** Manage images and colors in `Assets.xcassets`.
