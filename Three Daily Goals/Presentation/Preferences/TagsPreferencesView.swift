//
//  AppearancePreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI
import tdgCoreMain

public struct EditTag: View {
    @Binding var currentTagName: String
    @Binding var changeTo: String
    @Environment(CloudPreferences.self) private var preferences
    @Environment(DataManager.self) private var dataManager

    var displayCurrentTagName: String {
        if standardTags.contains(currentTagName) {
            return "\(currentTagName) (inbuilt)"
        }
        return currentTagName
    }
    public var body: some View {
        GroupBox(label: Text("Tag: \(displayCurrentTagName)").bold()) {
            VStack(alignment: .leading) {
                ForEach(TaskItemState.allCases) { state in
                    HStack {
                        Text(state.description + ":").bold()
                        Text("\(dataManager.statsForTags(tag: currentTagName, which: state))")
                    }
                }

                TextField("New Name", text: $changeTo)
                Button("Change Name") {
                    dataManager.exchangeTag(from: currentTagName, to: changeTo)
                }.buttonStyle(.bordered)

            }
            Spacer()
            Button("Delete this tag", role: .destructive) {
                dataManager.delete(tag: currentTagName)
            }.buttonStyle(.bordered)
                .disabled(standardTags.contains(currentTagName))
        }
        Spacer()
    }
}

public struct TagsPreferencesView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences
    @State var tag: String = ""
    @State var changeTo: String = ""
    public var body: some View {
        VStack {
            HStack(alignment: .top) {
                GroupBox(label: Text("All Tags").bold()) {
                    ScrollView(.vertical, showsIndicators: false) {
                        FlowLayout(spacing: 8, runSpacing: 8) {
                            ForEach(dataManager.allTags.asArray.sorted(), id: \.self) { text in
                                TagView(
                                    text: text,
                                    isSelected: tag == text,  // Highlight selected tag
                                    accentColor: Color.priority,
                                    onTap: {
                                        tag = text
                                        changeTo = text
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 150)  // Reduced height for preferences
                    Spacer()
                }
                Spacer()
                EditTag(currentTagName: $tag, changeTo: $changeTo)
            }
        }.padding(10).frame(maxWidth: 400)
    }
}

#Preview {
    let appComponents = setupApp(isTesting: true)
    TagsPreferencesView()
        .environment(appComponents.preferences)
        .environment(appComponents.dataManager)
}
