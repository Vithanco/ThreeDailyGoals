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
    
    var displayCurrentTagName : String {
        if currentTagName == "private" {
            return "private (inbuilt)"
        }
        if currentTagName == "work" {
            return "private (work)"
        }
        return currentTagName
    }
    var body: some View {
        GroupBox(label: Text("Tag: \(displayCurrentTagName)").bold()){
            VStack(alignment: .leading){
                ForEach(TaskItemState.allCases) {state in
                    HStack{
                        Text( state.description + ":").bold()
                        Text( "\(model.statsForTags(tag: currentTagName, which: state))")
                    }
                }
            
                    TextField("New Name", text: $changeTo)
                    Button ("Change Name") {
                        model.exchangeTag(from: currentTagName, to: changeTo)
                    }.buttonStyle(.bordered)
            

                
            }
            Spacer()
            Button("Delete this tag", role: .destructive){
                model.delete(tag: currentTagName)
            }.buttonStyle(.bordered)
                .disabled(currentTagName == "private" || currentTagName == "work")
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
