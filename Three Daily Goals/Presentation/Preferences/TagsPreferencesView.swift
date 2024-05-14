//
//  AppearancePreferencesView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 01/02/2024.
//

import SwiftUI
import TagKit


struct EditTag : View {
    @Binding var currentTagName: String
    @Binding var changeTo: String
    @Bindable var model: TaskManagerViewModel
    var body: some View {
        GroupBox(label: Text("Tag: \(currentTagName)").bold()){
            VStack(alignment: .leading){
                ForEach(TaskItemState.allCases) {state in
                    HStack{
                        Text( state.description + ":").bold()
                        Text( "\(model.statsForTags(tag: currentTagName, which: state))")
                    }
                }
                HStack {
                    TextField("Name", text: $changeTo)
                    Button ("Change") {
                        model.exchangeTag(from: currentTagName, to: changeTo)
                    }
                }
                
            }
        }
        Spacer()
    }
}

struct TagsPreferencesView : View {
    @Bindable var model: TaskManagerViewModel
    @State var tag: String = ""
    @State var changeTo: String = ""
    var body: some View {
        VStack{
            HStack(alignment: .top){
                GroupBox(label: Text("All Tags").bold()){
                    TagList(tags: model.allTags.asArray, onSelectTag: {text in
                        tag = text ?? ""
                        changeTo = text ?? ""
                    }, tagView: {text in return
                        TagCapsule(text).tagCapsuleStyle(model.selectedTagStyle)})
                    Spacer()
                }
                Spacer()
                EditTag (currentTagName: $tag, changeTo: $changeTo, model: model)
            }
        }.padding(10).frame(maxWidth: 400)
    }
}

#Preview {
    TagsPreferencesView(model: dummyViewModel())
}
