---
name: new-component
description: SwiftUI 컴포넌트를 DesignSystem 패턴에 맞게 생성
---

# New Component 스킬

PhotoOrganizer의 디자인 시스템에 맞는 새 SwiftUI 컴포넌트를 생성합니다.

## 사용법

- `/new-component Button/SecondaryButton` - Buttons 폴더에 SecondaryButton 생성
- `/new-component Cards/InfoCard` - Cards 폴더에 InfoCard 생성
- `/new-component States/SuccessStateView` - States 폴더에 SuccessStateView 생성

## 컴포넌트 구조

```
PhotoOrganizer/Components/
├── Buttons/
│   ├── PrimaryButton.swift
│   ├── IconButton.swift
│   └── TagChip.swift
├── Cards/
│   ├── PhotoCard.swift
│   └── SectionCard.swift
├── Forms/
│   └── InputField.swift
└── States/
    ├── EmptyStateView.swift
    ├── LoadingStateView.swift
    └── ErrorStateView.swift
```

## 템플릿

새 컴포넌트는 다음 패턴을 따릅니다:

```swift
import SwiftUI

struct {ComponentName}: View {
    // MARK: - Properties

    // MARK: - Body
    var body: some View {
        // 구현
    }
}

// MARK: - Preview
#Preview {
    {ComponentName}()
}
```

## 규칙

1. **DesignTokens 사용**: 색상, 간격, 모서리 반경은 `DesignTokens`에서 가져옵니다
2. **Typography 적용**: 텍스트 스타일은 `Typography` 확장을 사용합니다
3. **접근성**: `accessibilityLabel` 및 `accessibilityHint` 필수 적용
4. **Preview 포함**: 모든 컴포넌트는 `#Preview` 매크로 포함

## 참고 파일

- `DesignSystem/DesignTokens.swift` - 색상, 간격, 반경 토큰
- `DesignSystem/Typography.swift` - 텍스트 스타일
- `DesignSystem/ViewModifiers/` - 재사용 가능한 뷰 모디파이어
