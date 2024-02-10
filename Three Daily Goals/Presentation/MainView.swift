//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData

struct SingleView<Content: View>: View {
    
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
    }
}

//extension UserInterfaceSizeClass {
//    var columnVisibility : NavigationSplitViewVisibility {
//        switch self {
//            case .compact: return .detailOnly
//            case .regular: return .all
//            @unknown default:
//                return .all
//        }
//    }columnVisibility: horizontalSizeClass?.columnVisibility ?? .all
//}

struct MainView: View {
    @State var model : TaskManagerViewModel
    
    
    init(model: TaskManagerViewModel){
        self._model = State(wrappedValue: model)
    }
    
    var body: some View {
        SingleView{
            if isLargeDevice {
                RegularMainView(model: model).frame(minWidth: 1000, minHeight: 600)
            } else {
                CompactMainView(model: model)
            }
        }.background(Color.background)
            .sheet(isPresented: $model.showReviewDialog) {
                ReviewDialog(model: ReviewModel(taskModel: model))
                
            }
            .sheet(isPresented: $model.showSettingsDialog) {
                PreferencesView(model: model)
            }
    }
}

#Preview {
    MainView(model: dummyViewModel())
#if os(macOS)
        .frame(width: 1000, height: 600)
#endif
    
}
