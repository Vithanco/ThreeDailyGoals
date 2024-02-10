//
//  LinkToList.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI
import SwiftData

private struct ListLabel :View{
    let whichList: TaskItemState
    @Bindable var model: TaskManagerViewModel
    
    var name : Text {
        return whichList.section.asText
    }
    var count : Text {
        return Text( model.list(which: whichList).count.description)
    }
    var body: some View {
        HStack {
            name
            Spacer()
            if whichList.showCount {
                count
            }
        }
        .dropDestination(for: String.self){
            items, location in
            for item in items.compactMap({model.findTask(withID: $0)}) {
                model.move(task: item, to: whichList)
            }
            return true}
        .foregroundStyle(model.accentColor)
    }
}

struct LinkToList: View {
    @State var whichList: TaskItemState
    @Bindable var model: TaskManagerViewModel
    
    var body: some View {
        SingleView{
            if isLargeDevice {
                ListLabel(whichList: whichList, model: model)
                    .onTapGesture {
                        model.select(which: whichList,item: model.list(which: whichList).first)
                    }
            } else {
                NavigationLink {
                    ListView(whichList: whichList, model: model)
                } label: {
                    ListLabel(whichList: whichList, model: model)
                        .foregroundStyle(model.accentColor)
                }
            }
        }.navigationDestination(isPresented: $model.showItem) {
            if let item = model.selectedItem {
                TaskItemView(model:model, item: item)
            }
        }
        
    }
}


#Preview {
    LinkToList(whichList: .open, model: dummyViewModel())
}


