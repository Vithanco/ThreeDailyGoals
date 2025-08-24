//
//  AppearancePreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI
import TagKit

struct EditTag: View {
    @Binding var currentTagName: String
    @Binding var changeTo: String
    @Environment(TaskManagerViewModel.self) private var model
    @Environment(CloudPreferences.self) private var preferences

    var displayCurrentTagName: String {
        if currentTagName == "private" {
            return "private (inbuilt)"
        }
        if currentTagName == "work" {
            return "private (work)"
        }
        return currentTagName
    }
    var body: some View {
        GroupBox(label: Text("Tag: \(displayCurrentTagName)").bold()) {
            VStack(alignment: .leading) {
                ForEach(TaskItemState.allCases) { state in
                    HStack {
                        Text(state.description + ":").bold()
                        Text("\(model.statsForTags(tag: currentTagName, which: state))")
                    }
                }

                TextField("New Name", text: $changeTo)
                Button("Change Name") {
                    model.exchangeTag(from: currentTagName, to: changeTo)
                }.buttonStyle(.bordered)

            }
            Spacer()
            Button("Delete this tag", role: .destructive) {
                model.delete(tag: currentTagName)
            }.buttonStyle(.bordered)
                .disabled(currentTagName == "private" || currentTagName == "work")
        }
        Spacer()
    }
}

struct TagsPreferencesView: View {
    @Environment(TaskManagerViewModel.self) private var model
    @Environment(CloudPreferences.self) private var preferences
    @State var tag: String = ""
    @State var changeTo: String = ""
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                GroupBox(label: Text("All Tags").bold()) {
                    TagList(
                        tags: model.allTags.asArray,
                        tagView: { text in
                            return TagCapsule(text)
                                .tagCapsuleStyle(selectedTagStyle(accentColor: preferences.accentColor))
                                .onTapGesture(perform: {
                                    tag = text
                                    changeTo = text
                                })
                        })
                    Spacer()
                }
                Spacer()
                EditTag(currentTagName: $tag, changeTo: $changeTo)
            }
        }.padding(10).frame(maxWidth: 400)
    }
}

#Preview {
    TagsPreferencesView()
        .environment(dummyViewModel())
}
