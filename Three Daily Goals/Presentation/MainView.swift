//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftData
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
    @State var model: TaskManagerViewModel

    init(model: TaskManagerViewModel) {
        self._model = State(wrappedValue: model)
    }

    var body: some View {
        SingleView {
            if isLargeDevice {
                RegularMainView(model: model).frame(minWidth: 1000, minHeight: 600)
            } else {
                CompactMainView(model: model).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.background)
        #if os(iOS)
            .fullScreenCover(isPresented: Binding(
                get: { uiState.showCompassCheckDialog },
                set: { uiState.showCompassCheckDialog = $0 }
            )) {
                CompassCheckDialog(model: model)
            }
        #else
            .sheet(isPresented: Binding(
                get: { uiState.showCompassCheckDialog },
                set: { uiState.showCompassCheckDialog = $0 }
            )) {
                CompassCheckDialog(model: model)
            }
        #endif
        .sheet(isPresented: Binding(
            get: { uiState.showSettingsDialog },
            set: { uiState.showSettingsDialog = $0 }
        )) {
            PreferencesView(model: model)
        }
        .sheet(isPresented: Binding(
            get: { uiState.showSelectDuringImportDialog },
            set: { uiState.showSelectDuringImportDialog = $0 }
        )) {
            SelectVersions(choices: uiState.selectDuringImport, model: model)
        }
        .sheet(isPresented: Binding(
            get: { uiState.showNewItemNameDialog },
            set: { uiState.showNewItemNameDialog = $0 }
        )) {
            NewItemDialog(model: model)
        }
        .sheet(
            isPresented: Binding(
                get: { uiState.showInfoMessage },
                set: { uiState.showInfoMessage = $0 }
            ),
            content: {
                VStack {
                    GroupBox {
                        HStack(alignment: .center) {
                            Image(systemName: imgInformation).frame(width: 32, height: 32).foregroundStyle(
                                model.accentColor)
                            Text(uiState.infoMessage).padding(5)
                        }
                    }.padding(5)
                    Button("OK") {
                        uiState.showInfoMessage = false
                    }
                }.padding(10)

            }
        )
        .fileExporter(
            isPresented: Binding(
                get: { uiState.showExportDialog },
                set: { uiState.showExportDialog = $0 }
            ),
            document: model.jsonExportDoc,
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
            isPresented: Binding(
                get: { uiState.showImportDialog },
                set: { uiState.showImportDialog = $0 }
            ),
            allowedContentTypes: [UTType.json],
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
            }
        )

    }
}

#Preview {
    let model = dummyViewModel()
    let uiState = UIStateManager.testManager()
    uiState.infoMessage = " hall "
    uiState.showInfoMessage = true
    return MainView(model: model)
        .environment(uiState)
        #if os(macOS)
            .frame(width: 1000, height: 600)
        #endif

}
