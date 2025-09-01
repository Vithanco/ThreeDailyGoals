//
//  MainView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: MainView.self)
)

/// a simple block, to be used e.g. when I use an if then else, see below in MainView
struct SingleView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
    }
}

struct MainView: View {
    @Environment(UIStateManager.self) private var uiState
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        @Bindable var uiState = uiState

        return SingleView {
            if isLargeDevice {
                RegularMainView().frame(minWidth: 1000, minHeight: 600)
            } else {
                CompactMainView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.background)
        #if os(iOS)
            .fullScreenCover(isPresented: $uiState.showCompassCheckDialog) {
                CompassCheckDialog()
            }
        #else
            .sheet(isPresented: $uiState.showCompassCheckDialog) {
                CompassCheckDialog()
            }
        #endif
        .sheet(isPresented: $uiState.showSettingsDialog) {
            PreferencesView()
        }
        .sheet(isPresented: $uiState.showSelectDuringImportDialog) {
            SelectVersions(choices: uiState.selectDuringImport)
        }
        .sheet(isPresented: $uiState.showInfoMessage) {
            VStack {
                GroupBox {
                    HStack(alignment: .center) {
                        Image(systemName: imgInformation)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.priority)
                        Text(uiState.infoMessage).padding(5)
                    }
                }.padding(5)
                Button("OK") {
                    uiState.showInfoMessage = false
                }
            }.padding(10)
        }
        .fileExporter(
            isPresented: $uiState.showExportDialog,
            document: dataManager.jsonExportDoc,
            contentTypes: [UTType.json],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    logger.info("Tasks exported to \(url)")
                case .failure(let error):
                    logger.error("Exporting tasks led to \(error.localizedDescription)")
                }
            }
        )
        .fileImporter(
            isPresented: $uiState.showImportDialog,
            allowedContentTypes: [UTType.json],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    // Ensure we have permission to access the file
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    if gotAccess {
                        dataManager.importTasks(url: url, uiState: uiState)
                        // Remember to release the file access when done
                        url.stopAccessingSecurityScopedResource()
                    }
                case .failure(let error):
                    logger.error("Importing Tasks led to \(error.localizedDescription)")
                }
            }
        )
    }
}

//#Preview {
//    MainView()
//        .environment(dummyViewModel())
//}
