//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: MainView.self)
)

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
                CompactMainView(model: model).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.background)
        .sheet(isPresented: $model.showReviewDialog) {
            ReviewDialog(model: ReviewModel(taskModel: model))
        }
        .sheet(isPresented: $model.showSettingsDialog) {
            PreferencesView(model: model)
        }
        .confirmationDialog(model.infoMessage, isPresented: $model.showInfoMessage, actions: {Button("ok") {
            model.showInfoMessage = false
        }})
        .fileExporter(isPresented: $model.showExportDialog,
                      document: model.jsonExportDoc,
                      contentTypes:  [UTType.json],
                      onCompletion:  { result in
            switch result {
                case .success(let url):
                    logger.info("Tasks exported to \(url)")
                case .failure(let error):
                    logger.error("Exporting tasks led to \(error.localizedDescription)")
            }})
        .fileImporter(isPresented: $model.showImportDialog,
                      allowedContentTypes:  [UTType.json],
                      onCompletion: { result in
            switch result {
                case .success(let url):
                    // Ensure we have permission to access the file
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    if gotAccess {
                        model.importTasks(url: url)
                        // Remember to release the file access when done
                        url.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    logger.error("Importing Tasks led to \(error.localizedDescription)")
            }
        })
    }
}

#Preview {
    MainView(model: dummyViewModel())
#if os(macOS)
        .frame(width: 1000, height: 600)
#endif
    
}
