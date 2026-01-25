---
name: xcode-build
description: iOS 시뮬레이터에서 PhotoOrganizer 빌드, 실행, 스크린샷 캡처
---

# Xcode Build & Preview 스킬

PhotoOrganizer 프로젝트의 빌드, 테스트, 시뮬레이터 실행, 스크린샷 캡처를 수행합니다.

## 사용법

- `/xcode-build` - 빌드만 실행
- `/xcode-build run` - 빌드 후 시뮬레이터에서 앱 실행 및 스크린샷 캡처
- `/xcode-build test` - 유닛 테스트 실행
- `/xcode-build screenshot` - 현재 시뮬레이터 스크린샷 캡처
- `/xcode-build clean` - 클린 빌드

## 실행 순서

### 1. 빌드만 (`/xcode-build`)
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "(error:|warning:|BUILD)"
```

### 2. 빌드 + 실행 + 스크린샷 (`/xcode-build run`)

**Step 1: 시뮬레이터 부팅**
```bash
xcrun simctl boot "iPhone 17" 2>/dev/null || true
```

**Step 2: 빌드**
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/PhotoOrganizerBuild build 2>&1 | tail -5
```

**Step 3: 앱 설치 및 실행**
```bash
xcrun simctl install "iPhone 17" /tmp/PhotoOrganizerBuild/Build/Products/Debug-iphonesimulator/PhotoOrganizer.app
xcrun simctl launch "iPhone 17" GoBali.PhotoOrganizer
```

**Step 4: 스크린샷 캡처 (3초 대기 후)**
```bash
sleep 3
xcrun simctl io "iPhone 17" screenshot /tmp/photoorganizer_screenshot.png
```

**Step 5: 스크린샷 확인**
Read tool을 사용하여 `/tmp/photoorganizer_screenshot.png` 파일을 읽어 이미지를 확인합니다.

### 3. 테스트 (`/xcode-build test`)
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | grep -E "(Test|error:|PASS|FAIL)"
```

### 4. 스크린샷만 (`/xcode-build screenshot`)
```bash
xcrun simctl io "iPhone 17" screenshot /tmp/photoorganizer_$(date +%Y%m%d_%H%M%S).png
```
그 후 Read tool로 이미지 파일을 확인합니다.

### 5. 클린 빌드 (`/xcode-build clean`)
```bash
xcodebuild -project PhotoOrganizer.xcodeproj -scheme PhotoOrganizer clean build -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -E "(error:|warning:|BUILD)"
```

## 사용 가능한 시뮬레이터 확인

```bash
xcrun simctl list devices available | grep -E "iPhone|iPad"
```

## 스크린샷 저장 위치

- 기본: `/tmp/photoorganizer_screenshot.png`
- 타임스탬프 포함: `/tmp/photoorganizer_YYYYMMDD_HHMMSS.png`

## 주의사항

1. 시뮬레이터 이름은 시스템에 따라 다를 수 있음 (iPhone 15, iPhone 17 등)
2. 빌드 실패 시 에러 메시지 확인
3. 스크린샷은 Read tool로 직접 확인 가능 (Claude가 이미지 분석)

## 작업 디렉토리

모든 명령어는 프로젝트 루트에서 실행:
`/Users/shinukyi/Gallary/swift/PhotoOrganizer`
