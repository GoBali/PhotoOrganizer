# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication
- **모든 답변은 한국어로 작성합니다.**

## Development Workflow (필수)

**기능 추가 또는 수정 후 반드시 다음 워크플로우를 따릅니다:**

### 1. 빌드 검증
코드 수정 후 빌드가 성공하는지 확인:
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -30
```

### 2. 테스트 실행
빌드 성공 후 테스트 실행:

**iOS Simulator (권장):**
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | tail -50
```

**macOS (My Mac):**
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=macOS' test 2>&1 | grep -E "(Test case|passed|failed|BUILD|TEST)" | tail -30
```

**단위 테스트만 실행 (UI 테스트 제외):**
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=macOS' test -only-testing:PhotoOrganizerTests 2>&1 | tail -30
```

> **참고:** macOS UI 테스트에서 "Failed to terminate" 오류가 발생할 수 있습니다. 이는 환경 문제로, 단위 테스트 통과 여부로 코드 검증이 가능합니다.

### 3. 결과 보고
- 빌드 실패 시: 오류 메시지 분석 후 즉시 수정
- 테스트 실패 시: 실패한 테스트 케이스 확인 및 수정
- 모든 테스트 통과 시: 완료 보고

### 워크플로우 체크리스트
- [ ] 코드 수정 완료
- [ ] 빌드 성공 (BUILD SUCCEEDED)
- [ ] 테스트 통과 (모든 테스트 passed)
- [ ] 결과 요약 보고

> **중요:** 사용자가 명시적으로 테스트 생략을 요청하지 않는 한, 모든 기능 구현은 테스트 통과까지 완료해야 합니다.

## Cross-Platform API 가이드라인 (필수)

이 프로젝트는 iOS와 macOS 모두 지원합니다. **플랫폼 전용 API 사용 시 반드시 조건부 컴파일을 적용해야 합니다.**

### iOS 전용 API (macOS에서 사용 불가)
| API | 대체 방법 (macOS) |
|-----|------------------|
| `fullScreenCover` | `sheet` |
| `UIScreen.main` | `NSScreen.main` |
| `UIImage` | `NSImage` (또는 `PlatformImage` 사용) |
| `PhotosPicker` | `fileImporter` 또는 조건부 컴파일 |

### 올바른 사용 예시
```swift
// ✅ 올바른 방법: 조건부 컴파일 사용
#if os(iOS)
.fullScreenCover(isPresented: $showImage) {
    ImageView()
}
#else
.sheet(isPresented: $showImage) {
    ImageView()
        .frame(minWidth: 600, minHeight: 500)
}
#endif

// ✅ 화면 크기 가져오기
private var screenHeight: CGFloat {
    #if os(iOS)
    return UIScreen.main.bounds.height
    #else
    return NSScreen.main?.frame.height ?? 800
    #endif
}
```

### 빌드 검증 체크리스트
코드 수정 후 **양쪽 플랫폼 모두 빌드 확인**:
```bash
# iOS 빌드
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|BUILD)" | tail -5

# macOS 빌드
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=macOS' build 2>&1 | grep -E "(error:|BUILD)" | tail -5
```

## Project Overview
PhotoOrganizer is a SwiftUI-based iOS/macOS photo organization app that uses Core ML for automatic image classification and Core Data for persistence. Users can import photos, which are automatically classified using a bundled `MyImageClassifier.mlmodel`, then organize them with tags, notes, and category filters.

## Build & Test Commands

### Build
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### Run Tests
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### Open in Xcode
```bash
open PhotoOrganizer.xcodeproj
```

### 시뮬레이터에서 앱 실행 및 스크린샷 캡처

**스킬 사용 (권장):**
- `/xcode-build run` - 빌드 → 시뮬레이터 실행 → 스크린샷 캡처

**수동 실행:**
```bash
# 1. 시뮬레이터 부팅
xcrun simctl boot "iPhone 17" 2>/dev/null || true

# 2. 빌드
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/PhotoOrganizerBuild build

# 3. 앱 설치 및 실행
xcrun simctl install "iPhone 17" /tmp/PhotoOrganizerBuild/Build/Products/Debug-iphonesimulator/PhotoOrganizer.app
xcrun simctl launch "iPhone 17" GoBali.PhotoOrganizer

# 4. 스크린샷 캡처 (3초 대기)
sleep 3 && xcrun simctl io "iPhone 17" screenshot /tmp/photoorganizer_screenshot.png
```

**스크린샷 확인:**
Read tool을 사용하여 `/tmp/photoorganizer_screenshot.png` 파일을 읽으면 Claude가 이미지를 분석합니다.

**사용 가능한 시뮬레이터 확인:**
```bash
xcrun simctl list devices available | grep -E "iPhone|iPad"
```

## Architecture

### Data Flow
1. **App Entry** (`PhotoOrganizerApp.swift`): Initializes `PersistenceController` (Core Data stack) and `PhotoLibraryStore` (business logic), injects both via environment
2. **UI Layer**: 기능별로 분리된 SwiftUI 뷰 구조
   - `ContentView.swift`: 진입점 (LibraryView 호출)
   - `Features/Library/LibraryView.swift`: 메인 라이브러리 뷰
   - `Features/Library/PhotoGridView.swift`: Masonry 그리드 레이아웃 (2 columns)
   - `Features/PhotoDetail/PhotoDetailView.swift`: 상세 뷰 (분류, 태그, 노트)
3. **Business Logic** (`Persistence.swift`):
   - `PhotoLibraryStore`: Manages all photo operations (import, classify, tag, search, delete)
   - `PhotoFileStore`: Handles file system I/O (saves JPEGs to Documents/PhotoLibrary)
   - `PhotoClassifier`: Wraps Core ML model in Vision framework
4. **UI Components** (`ImagePicker.swift`): Async image loading components (`PhotoThumbnailView`, `PhotoFullImageView`)

### 디자인 시스템 (DesignSystem/)
- `DesignTokens.swift`: 색상 팔레트, 간격(8pt 그리드), 코너 반경, 엘리베이션
- `Typography.swift`: Dynamic Type 지원 타이포그래피
- `ViewModifiers/CardModifier.swift`: 카드 스타일
- `ViewModifiers/ButtonStyles.swift`: 버튼 스타일 (Primary, Secondary, Icon, Tag)

### 공용 컴포넌트 (Components/)
- `Buttons/`: PrimaryButton, IconButton, TagChip
- `Cards/`: PhotoCard, SectionCard
- `Forms/`: InputField, SearchField
- `States/`: EmptyStateView, LoadingStateView, ErrorStateView

### Core Data Model
Defined in `PhotoOrganizer.xcdatamodeld/PhotoOrganizer.xcdatamodel/contents`:
- **PhotoAsset**: Stores photo metadata (fileName, classificationLabel, classificationConfidence, classificationState, tags, note, originalFilename, createdAt)
- **Tag**: Many-to-many relationship with PhotoAsset

Classification states: `pending` (0) → `processing` (1) → `completed` (2) or `failed` (3)

### Cross-Platform Support
- `PlatformImage.swift` provides unified `UIImage`/`NSImage` interface via typealias and extensions
- Conditional compilation for iOS (`#if os(iOS)`) vs macOS (`#elseif os(macOS)`)
- macOS-specific features: file drag-drop, `.fileImporter` for folder import

### ML Classification Pipeline
1. Photo imported → saved to file system as JPEG
2. `PhotoLibraryStore.classify()` called with `PlatformImage`
3. `PhotoClassifier` loads `MyImageClassifier.mlmodelc` dynamically from bundle (no generated Swift class)
4. Vision framework (`VNCoreMLRequest`) performs inference
5. Top classification result saved to Core Data

## Key Implementation Patterns

### 파일 구조
```
PhotoOrganizer/
├── DesignSystem/
│   ├── DesignTokens.swift      # 색상, 간격, 코너, 그림자
│   ├── Typography.swift        # Dynamic Type 스타일
│   └── ViewModifiers/
│       ├── CardModifier.swift
│       └── ButtonStyles.swift
├── Components/
│   ├── Buttons/                # PrimaryButton, IconButton, TagChip
│   ├── Cards/                  # PhotoCard, SectionCard
│   ├── Forms/                  # InputField
│   └── States/                 # EmptyStateView, LoadingStateView, ErrorStateView
├── Features/
│   ├── Library/                # LibraryView, PhotoGridView
│   └── PhotoDetail/            # PhotoDetailView
├── ContentView.swift           # 진입점
├── Persistence.swift           # 비즈니스 로직 + Core Data
└── ImagePicker.swift           # 이미지 로딩 컴포넌트
```

### 디자인 토큰 사용법
```swift
// 색상
Color.ds.primary         // 진한 네이비 (#1A1A2E)
Color.ds.secondary       // 인디고 (#6366F1)
Color.ds.background      // 앱 배경 (#FAFBFC)

// 간격 (8pt 그리드)
Spacing.space2           // 8pt
Spacing.space4           // 16pt

// 코너 반경
CornerRadius.medium      // 10pt
CornerRadius.large       // 14pt

// 그림자
.elevation(.low)
.elevation(.medium)
```

### Business Logic
- `Persistence.swift` merges platform abstraction, file I/O, Core Data, and ML classification logic

### Async Image Loading
`PhotoThumbnailView` and `PhotoFullImageView` use `.task(id: photo.fileName)` to asynchronously load images from `PhotoLibraryStore`, showing `ProgressView` placeholders during load.

### Category Filtering
`PhotoLibraryStore.categoryOptions()` dynamically generates filter list: `["All", "Unclassified"] + unique classification labels`. Selected category stored in `@Published var selectedCategory`.

### Core Data Access
- View context injected via `.environment(\.managedObjectContext, ...)`
- `@FetchRequest` used in `LibraryView` for reactive photo list
- `PhotoLibraryStore` manages context saves and orphaned tag cleanup

### Error Handling
`PhotoLibraryStore.lastError` (optional String) triggers alerts in `LibraryView`. Errors logged via OSLog (`Logger(subsystem: "PhotoOrganizer", ...)`).

## Development Notes

### Running Single Tests
To run a specific test class:
```bash
xcodebuild test -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PhotoOrganizerTests/PhotoOrganizerTests
```

To run a specific test method:
```bash
xcodebuild test -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PhotoOrganizerTests/PhotoOrganizerTests/testExample
```

### Core Data Schema Migrations
When modifying `.xcdatamodeld`:
1. Create new model version (Editor → Add Model Version in Xcode)
2. Set as current version
3. `NSPersistentContainer` handles lightweight migrations automatically via `shouldInferMappingModelAutomatically = true`

### Adding New ML Models
1. Replace `MyImageClassifier.mlmodel` in `PhotoOrganizer/Models/`
2. Ensure model outputs `VNClassificationObservation` results
3. `PhotoClassifier.defaultClassifier()` loads `.mlmodelc` from bundle dynamically—no code changes needed if model name stays the same

### Platform-Specific Features
- iOS: Uses `PhotosPicker` for photo library access
- macOS: Adds `.fileImporter` and `.onDrop` for file/folder import with security-scoped resource access

## Common Issues

### Model Loading Failures
If classification fails with "Model unavailable":
1. Check `MyImageClassifier.mlmodel` is in Xcode project target membership
2. Verify compiled model (`MyImageClassifier.mlmodelc`) exists in app bundle
3. Check console for print statements from `PhotoClassifier.defaultClassifier()`

### Core Data Migration Errors
If persistent store fails to load:
- `PersistenceController` automatically falls back to in-memory store
- Check Xcode console for migration errors
- Delete app and reinstall to reset schema (development only)
