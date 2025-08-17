//
//  ShareExtensionView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//

import SwiftData
import SwiftUI
import TagKit

struct ShareExtensionView: View {
    @State private var item: TaskItem = .init()
    @EnvironmentObject private var pref: CloudPreferences
    @Environment(\.modelContext) var model

    @Query private var allItems: [TaskItem]

    init(text: String) {
        self.item.title = text
    }
    init(details: String) {
        self.item.details = details
    }
    init(url: String) {
        self.item.title = "Read"
        self.item.url = url
    }

    init() {
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button {
                    debugPrint("Number: \(allItems.count)")
                    model.insert(item)

                    do {
                        debugPrint(item)
                        try model.save()
                        debugPrint("Number: \(allItems.count)")
                    } catch {
                        debugPrint(error)
                    }
                    self.close()
                } label: {
                    Text("Add to Three Daily Goals")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                InnerTaskItemView(
                    accentColor: pref.accentColor,
                    item: item,
                    allTags: [],
                    selectedTagStyle: selectedTagStyle(accentColor: pref.accentColor),
                    missingTagStyle: missingTagStyle
                )

            }
            .padding()
            .navigationTitle("Share Extension")
            .toolbar {
                Button("Cancel") {
                    self.close()
                }
            }
        }
    }

    // so we can close the whole extension
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
}
