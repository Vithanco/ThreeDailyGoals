//
//  IconsRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

let imgOpen = "figure.walk.circle.fill"
let imgClosed = "flag.checkered.2.crossed"
let imgGraveyard = "heart.slash.fill"
let imgPendingResponse = "alarm.fill"
let imgDated = "clock.fill"
//let imgMagnifyingGlass = "magnifyingglass.circle.fill"
let imgReview = "brain.filled.head.profile"
let imAppearance = "paintpalette"
let imgAddItem = "plus.app.fill" // "plus"
let imgPreferences = "gearshape"

let imgToday = "exclamationmark.square.fill"
let imgPriority1 = "1.circle.fill"
let imgPriority2 = "2.circle.fill"
let imgPriority3 = "3.circle.fill"
let imgPriorityX = "x.circle.fill"

let imgCloseTask = "xmark.circle.fill"
let imgReopenTask = imgOpen  //arrow.uturn.forward.circle.fill
let imgTouch = "dot.circle.and.hand.point.up.left.fill"

let imgUndo = "arrow.uturn.backward.circle.fill"
let imgRedo = "arrow.uturn.forward.circle.fill"

let imgCheckedBox = "checkmark.square.fill"
let imgUncheckedBox = "square"
let imgStreak = "flame.fill"
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
