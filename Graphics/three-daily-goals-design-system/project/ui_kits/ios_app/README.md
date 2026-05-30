# Three Daily Goals — iOS App UI Kit

High-fidelity clickable prototype of the iOS app.

## Screens

1. **Today / Priority View** — Left sidebar with streak widget + priority task list
2. **Open Tasks List** — Full task list with EEM indicators, swipe actions, tag filters
3. **Task Detail** — Task editing view with metadata, tags, due date, history
4. **Compass Check** — Multi-step daily review flow (full-screen cover)
5. **Graveyard** — Archived tasks list

## Components (components.jsx)

- `StatusBar` — iOS-style status bar (time, battery, signal)
- `NavBar` — Navigation bar with title + toolbar items
- `StreakWidget` — Streak counter + Compass Check CTA
- `TaskRow` — Task card with EEM 2×2 indicator, title, due date
- `ListContainer` — Colored list container with header
- `SidebarLinks` — Bottom sidebar navigation (Open, Pending, Closed, Graveyard)
- `CompassCheckDialog` — Full-screen cover for daily review
- `CompassCheckStep` — Individual step card
- `TaskDetailView` — Full task editing screen
- `EEMMatrix` — Full 2×2 Energy-Effort Matrix picker

## Design notes
- iPhone 14 Pro frame: 393×852pt
- System UI font stack, Dynamic Type sizes matched to SwiftUI `.body`, `.headline` etc.
- Colors exactly match `ColorRelated.swift` and `TaskItemState.swift`
- SF Symbols referenced as Unicode approximations in HTML (●, ★, ◷, ✓, ☰, ⚙, etc.)
- No custom fonts — system font stack throughout
