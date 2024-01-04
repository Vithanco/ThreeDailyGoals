//
//  ReviewDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI

struct ReviewDialog: View {
    enum DialogState {
        case inform
        case review
    }
    
    @Bindable var model: TaskManagerViewModel
    @State var state: DialogState = .inform
    //    @State var listModel = ListViewModel(sections: [secToday], list: [])
    //
    //    func updateModel() {
    //        listModel.list = today.priorities ?? []
    //    }
    
    func startReview(){
        for p in model.today?.priorities ?? [] {
            p.removePriority()
        }
        state = .review
    }
    
    func startReviewWithClosingAll(){
        for p in model.today?.priorities ?? [] {
            p.closeTask()
        }
        startReview()
    }
    
    func cancelReview(){
        model.showReviewDialog = false
        state = .inform
    }
    
    func endReview(){
        model.showReviewDialog = false
        state = .inform
    }
    
    var body: some View {
        let hasTasks = (model.today?.priorities?.count ?? 0) > 0
        switch state {
            case .inform:
                VStack {
                    Text("Review your Tasks!").font(.caption).foregroundStyle(Color.mainColor)
                    if hasTasks {
                        Text("The previous Tasks were: ")
                        ListView(whichList: .priorities, model: model)
                    } else {
                        Text("No previous Tasks")
                    }
                    
                    HStack{
                        Button(action: cancelReview){
                            Text("Cancel")
                        }
                        Spacer()
                        if hasTasks {
                            Button(action: startReviewWithClosingAll ){
                                Text("Close All and Review Now")
                            }
                            Spacer()
                        }
                        Button(action: startReview){
                            Text("Review Now")
                        }
                    }
                    
                }.padding(4).frame(minWidth: 600, minHeight: 400)
            case .review:
                VStack{
                    HStack {
                        ListView(whichList: .priorities, model: model).dropDestination(for: String.self){
                            items, location in
                            for item in items.compactMap({model.findTask(withID: $0)}) {
                                item.makePriority(position: 0, day: model.today!)
                            }
                           return true
                        }.frame(minHeight: 300)
                        ListView(whichList: .openItems,model: model).dropDestination(for: String.self){
                            items, location in
                            for item in items.compactMap({model.findTask(withID: $0)}) {
                                item.removePriority()
                            }
                           return true
                        }
                        .dropDestination(for: Data.self){
                            items, location in debugPrint(items, location)
                           return true
                        }
                    }
                    Button(action: endReview){
                        Text("Done")
                    }
                }.padding(4)
        }
    }
}

#Preview {
    return ReviewDialog(model: TaskManagerViewModel(modelContext: sharedModelContainer(inMemory: true).mainContext).addSamples())
}
