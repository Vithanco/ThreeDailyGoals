//
//  IconsRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

// MARK: - List Icons
let imgOpen = "circle"
let imgClosed = "checkmark.circle.fill"
let imgGraveyard = "archivebox"
let imgPendingResponse = "clock"
let imgDueSoon = "calendar"
let imgDated = "clock.fill"
let imgInformation = "info.square.fill"
let imgCompassCheck = "compass.drawing"
let imgStreak = "flame"
let imgPriority = "star.fill"

// MARK: - Streak and Compass Check Icons
let imgStreakActive = "flame.fill"
let imgCompassCheckDone = "checkmark.circle.fill"
let imgCompassCheckPending = "clock.circle"
let imgCompassCheckStart = "safari"

let imgReopenTask = imgOpen  //arrow.uturn.forward.circle.fill
let imgTouch = "hand.tap"

let imgUndo = "arrow.uturn.backward.circle.fill"
let imgRedo = "arrow.uturn.forward.circle.fill"
let imgAttachment = "paperclip"
let imgTag = "tag"
let imgStateChange = "arrow.triangle.2.circlepath"

// MARK: - UI Icons
let imgAddItem = "plus.app.fill"
let imgPreferences = "gearshape"

let imgExport = "square.and.arrow.up.on.square.fill"
let imgImport = "square.and.arrow.down.on.square.fill"
let imgStats = "chart.bar.fill"
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
//                .foregroundColor(.primary)
//            }
//            .fixedSize()
//            .accessibilityElement(children: .ignore)
//            .accessibilityLabel("App version \(versionString)")
//        }
//    }
//}

//  .symbolEffect(.bounce.down.byLayer, options: .nonRepeating)
