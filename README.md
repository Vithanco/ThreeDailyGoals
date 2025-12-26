# Three Daily Goals

> The task manager that helps you let go

A productivity app for iOS/macOS that automatically archives tasks you ignore (the "Graveyard" system), helping you focus on what actually matters.

**[Download on the App Store](https://apps.apple.com/us/app/three-daily-goals/id6474504409)** ($19.99 one-time purchase)

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2018%2B%20%7C%20macOS%2015%2B-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Why This Exists

I tried every task manager. Things 3, Remember the Milk, you name it. I'd start excited, then drown in 200+ tasks and abandon it.

The advice was always the same: organize better. Add tags. Create projects. Use the Eisenhower Matrix to identify what's truly important.

But here's the thing: **I couldn't mark anything as "not important."** Everything on my list felt like it mattered. The article I wanted to write, the feature I wanted to build, the book I wanted to read - they all felt urgent, important, both.

Then I saw someone tear out pages of unfinished tasks from their notebook. Those tasks weren't important - **proven by 30 days of ignoring them.**

So I built a task manager that does the tearing for you. It's called the **Graveyard**. 30% of my tasks end up there. I don't miss any of them.

## Key Features

### The Graveyard System
Automatically archives tasks you haven't touched in 30 consecutive days. No decisions required, no guilt - if you ignored it for a month, it wasn't actually important.

### Compass Check
A customizable 5-minute daily review ritual that helps you:
- Review current priorities
- Categorize tasks by energy and effort
- Check tasks waiting for responses
- Review due dates
- Archive stale tasks
- Plan your day with calendar integration

### Energy-Effort Matrix
Traditional prioritization (Eisenhower Matrix) asks "What's important?" But when you can't let go, everything feels important.

Instead, categorize tasks by:
- **Energy Required:** High/Low
- **Effort Required:** High/Low

Match tasks to your current capacity, not your ambition.

### CloudKit Sync
Seamless sync across iPhone, iPad, and Mac. Your tasks follow you everywhere.

### Widgets & Share Extensions
- See your 3 daily priorities at a glance
- Add tasks from anywhere via share extensions
- Quick add widget for fast task capture

## Open Source Philosophy

This app is about **letting go** - that includes letting go of code ownership. The entire codebase is MIT licensed and available for:

- Learning real-world SwiftUI/SwiftData patterns
- Understanding CloudKit sync implementation
- Studying schema migrations in production apps
- Building your own version if you want

### Support This Project

- **Buy it on the App Store** for convenience and automatic updates
- **Star this repo** if you find the code useful
- **Share it** with someone drowning in their task list

The code is free. The convenience of App Store distribution, automatic updates, and support is what you're paying for.

## Architecture Highlights

This is a production-quality iOS/macOS app showcasing modern Swift development:

- **Multi-module Swift Package** (`tdgCore`) for code sharing between app, widgets, and extensions
- **SwiftData** with versioned schema migrations (SchemaV3_6)
- **Manager pattern** using `@Observable` instead of ViewModels
- **Protocol-based Compass Check steps** for customizable workflows
- **Test-driven development** with Swift Testing framework
- **CloudKit integration** for seamless multi-device sync
- **EventKit integration** for calendar scheduling
- **Share extensions** for iOS and macOS

See [AGENTS.md](./AGENTS.md) for comprehensive architecture documentation, development workflows, and best practices.

## Building from Source

### Requirements

- **Xcode 15.0+**
- **macOS 14.0+** (for building)
- **iOS 18.0+ / macOS 15.0+** (deployment targets)

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/Vithanco/ThreeDailyGoals.git
cd ThreeDailyGoals

# Build the main app
xcodebuild -project "Three Daily Goals.xcodeproj" \
  -scheme "Three Daily Goals" \
  -configuration Debug build

# Run tests
xcodebuild test \
  -project "Three Daily Goals.xcodeproj" \
  -scheme "Three Daily Goals" \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=latest"

# Test the Swift package (tdgCore)
cd tdgCore
swift test
swift build
```

### Project Structure

```
Three Daily Goals/           # Main app target
├── App/                     # App entry point and setup
├── Controller/              # Managers (DataManager, UIStateManager, etc.)
├── Domain/                  # Business logic and Compass Check steps
├── Presentation/            # SwiftUI views
└── Three_Daily_Goals.entitlements

tdgCore/                     # Swift Package
├── Sources/
│   ├── tdgCoreWidget/       # Base utilities, shared types
│   ├── tdgCoreMain/         # Domain models, storage, presentation
│   ├── tdgCoreShare/        # Share extension logic
│   └── tdgCoreTest/         # Test utilities
└── Tests/

Three Daily Goals (Widget)   # Widget extension
iosShare/                    # iOS share extension
macosShare/                  # macOS share extension
```

## Contributing

This is a personal project, so there's no SLA on issues or PRs - but **contributions are welcome!**

Before contributing:
1. Read [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines
2. Read [AGENTS.md](./AGENTS.md) for architecture and development workflow
3. Follow the **test-driven development** approach (write failing test first)

## Documentation

- **[AGENTS.md](./AGENTS.md)** - Comprehensive development guide (architecture, testing, workflows)
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - How to contribute
- **[SHARE_EXTENSION_TESTING.md](./SHARE_EXTENSION_TESTING.md)** - Share extension testing guide

## Technology Stack

- **Language:** Swift 6.0 with strict concurrency checking
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData with CloudKit sync
- **Calendar Integration:** EventKit
- **Testing:** Swift Testing framework
- **Dependencies:** [SimpleCalendar](https://github.com/Vithanco/SimpleCalendar) (calendar view component)

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Links

- **App Store:** https://apps.apple.com/us/app/three-daily-goals/id6474504409
- **Website:** https://threedailygoals.com
- **Support:** [GitHub Issues](https://github.com/Vithanco/ThreeDailyGoals/issues)

---

*Built with SwiftUI, SwiftData, and the realization that 30% of your tasks don't actually matter.*
