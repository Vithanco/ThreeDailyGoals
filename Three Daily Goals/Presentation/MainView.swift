//
//  MainView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import os
import tdgCoreMain

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
    @State private var hasLoadedData = false

    #if os(macOS)
        @Environment(\.openWindow) private var openWindow
        @Environment(\.dismissWindow) private var dismissWindow
    #endif

    var body: some View {
        @Bindable var uiState = uiState

        return SingleView {
            if isLargeDevice {
                RegularMainView().frame(minWidth: 1200, minHeight: 600)
            } else {
                CompactMainView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.background)
        .task {
            // Defer heavy data operations until after initial UI render
            guard !hasLoadedData else { return }
            hasLoadedData = true
            await dataManager.mergeDataFromCentralStorageAsync()
        }
        #if os(iOS)
            .fullScreenCover(isPresented: $uiState.showCompassCheckDialog) {
                CompassCheckDialog()
                    .interactiveDismissDisabled()
            }
        #else
            // On macOS, open/close a dedicated window instead of a sheet
            .onChange(of: uiState.showCompassCheckDialog) { oldValue, newValue in
                guard oldValue != newValue else { return }
                if newValue {
                    openWindow(id: "CompassCheckWindow")
                } else {
                    dismissWindow(id: "CompassCheckWindow")
                }
            }
            .onAppear {
                if uiState.showCompassCheckDialog {
                    openWindow(id: "CompassCheckWindow")
                }
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
        .alert(
            uiState.databaseError?.userFriendlyTitle ?? "Database Error",
            isPresented: $uiState.showDatabaseErrorAlert
        ) {
            if let error = uiState.databaseError, error.isUpgradeRequired {
                Button("Update App") {
                    // Open App Store for app update
                    if let url = URL(string: "https://apps.apple.com/app/three-daily-goals/id1234567890") {
                        PlatformFileSystem.openURL(url)
                    }
                }
                Button("Later", role: .cancel) {
                    uiState.showDatabaseErrorAlert = false
                }
            } else {
                Button("OK") {
                    uiState.showDatabaseErrorAlert = false
                }
            }
        } message: {
            if let error = uiState.databaseError {
                Text(error.userFriendlyMessage)
            }
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
