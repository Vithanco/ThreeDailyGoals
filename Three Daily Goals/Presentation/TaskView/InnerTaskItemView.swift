//
//  InnerTaskItemView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/08/2025.
//
import SwiftUI
import TagKit

struct InnerTaskItemView: View {
    let accentColor: Color
    @Bindable var item: TaskItem
    @FocusState var isTitleFocused: Bool
    let allTags: [String]
    @State var buildTag: String = ""
    let selectedTagStyle: TagCapsuleStyle
    let missingTagStyle: TagCapsuleStyle

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                StateView(state: item.state, accentColor: accentColor)
                Text("Task").font(.title).foregroundStyle(accentColor)
                Spacer()
            }

            LabeledContent {
                TextField("titleField", text: $item.title).accessibilityIdentifier("titleField").focused(
                    $isTitleFocused
                )
                .bold().frame(idealHeight: 13)
            } label: {
                Text("Title:").bold().foregroundColor(Color.secondaryColor)
            }

            //        Details
            LabeledContent {
                TextField("Details", text: $item.details, axis: .vertical)
                    #if os(macOS)
                        .textFieldStyle(.squareBorder)
                    #endif
                    .frame(minHeight: 30, idealHeight: 30)
            } label: {
                Text("Details:").bold().foregroundColor(Color.secondaryColor)
            }

            //        URL
            LabeledContent {
                HStack {
                    TextField("URL", text: $item.url, axis: .vertical)
                        #if os(macOS)
                            .textFieldStyle(.squareBorder)
                        #endif
                        .frame(idealHeight: 30).frame(minHeight: 30)
                    if let link = URL(string: item.url) {
                        Link("Open", destination: link)
                    }
                }
            } label: {
                Text("URL:").bold().foregroundColor(Color.secondaryColor)
            }

            LabeledContent {
                DatePickerNullable(selected: $item.due, defaultDate: getDate(inDays: 7))
            } label: {
                Text("Due Date:").bold().foregroundColor(Color.secondaryColor)
            }

            GroupBox {
                HStack {
                    Text("Add new Label:")
                    TagTextField(text: $buildTag, placeholder: "Tag Me").onSubmit({
                        item.addTag(buildTag)
                    })
                }
                TagEditList(
                    tags: Binding(
                        get: { item.tags },
                        set: { item.tags = $0 }
                    ),
                    additionalTags: allTags,
                    container: .vstack
                ) { text, isTag in
                    TagCapsule(text)
                        .tagCapsuleStyle(isTag ? selectedTagStyle : missingTagStyle)
                }.frame(maxHeight: 70)
            }

            Spacer()
            AllCommentsView(item: item).frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                LabeledContent {
                    Text(item.created, format: stdOnlyDateFormat)
                } label: {
                    Text("Created:").bold().foregroundColor(Color.secondaryColor)
                }
                LabeledContent {
                    Text(item.changed.timeAgoDisplay())
                } label: {
                    Text("Changed:").bold().foregroundColor(Color.secondaryColor)
                }
            }
        }.background(Color.background).padding()
    }
}
