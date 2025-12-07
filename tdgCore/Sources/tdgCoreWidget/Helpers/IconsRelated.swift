//
//  IconsRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

// MARK: - List Icons
public let imgOpen = "circle"
public let imgClosed = "checkmark.circle.fill"
public let imgGraveyard = "archivebox"
public let imgPendingResponse = "clock"
public let imgDueSoon = "calendar"
public let imgDated = "clock.fill"
public let imgInformation = "info.square.fill"
public let imgCompassCheck = "safari"
public let imgStreak = "flame"
public let imgPriority = "star.fill"

// MARK: - Streak and Compass Check Icons
public let imgStreakActive = "flame.fill"
public let imgStreakBroken = "cloud.heavyrain.circle.fill"
public let imgCompassCheckDone = "checkmark.circle.fill"
public let imgCompassCheckPending = "clock.circle"

public let imgReopenTask = imgOpen  //arrow.uturn.forward.circle.fill
public let imgTouch = "hand.tap"

public let imgUndo = "arrow.uturn.backward.circle.fill"
public let imgRedo = "arrow.uturn.forward.circle.fill"
public let imgAttachment = "paperclip"
public let imgStateChange = "arrow.triangle.2.circlepath"

// MARK: - UI Icons
public let imgAddItem = "plus.app.fill"
public let imgPreferences = "gearshape"

public let imgExport = "square.and.arrow.up.fill"
public let imgImport = "square.and.arrow.down.fill"
public let imgStats = "chart.bar.fill"
//
//
//enum AppIconProvider {
//
//    // App icons can only be retrieved as named `UIImage`s
//    // https://stackoverflow.com/a/62064533/17421764
//    static func appIcon(in bundle: Bundle = .main) -> Image {
//        guard let icons = bundle.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
//              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
//              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
//              let iconFileName = iconFiles.last else {
//            fatalError("Could not find icons in bundle")
//        }
//        #if os(iOS)
//        if let image = UIImage(named: iconFileName) {
//            return Image(image)
//        }
//        #endif
//        #if os(macOS)
//        if let image = NSImage(named: iconFileName) {
//            return Image(nsImage: image)
//        }
//#endif
//        return Image("halt")
//    }
//
//    struct AppVersionInformationView: View {
//        let versionString: String
//        let appIcon: String
//
//        var body: some View {
//            HStack(alignment: .center, spacing: 12) {
//                VStack(alignment: .leading) {
//                    Text("Version")
//                        .bold()
//                    Text("v\(versionString)")
//                }
//                .font(.caption)
//                .foregroundStyle(.primary)
//            }
//            .fixedSize()
//            .accessibilityElement(children: .ignore)
//            .accessibilityLabel("App version \(versionString)")
//        }
//    }
//}

//  .symbolEffect(.bounce.down.byLayer, options: .nonRepeating)
