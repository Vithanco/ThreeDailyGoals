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
        
    }
    
    func cancelReview(){
        
    }
    
    func endReview(){
        
    }
    
    var body: some View {
        switch state {
            case .inform:
                //                let _ = updateModel()
                VStack {
                    
                    Text("Review your Tasks!").font(.caption).foregroundStyle(Color.mainColor)
                    Text("The previous Tasks were: ")
                    ListView(whichList: .priorities, model: model)
                    HStack{
                        Button(action: cancelReview){
                            Text("Cancel")
                        }
                        Spacer()
                        Button(action: startReview){
                            Text("Review now")
                        }
                    }
                    
                }
            case .review:
                Text("soon to come")
                Button(action: endReview){
                    Text("Done")
                }
                
                
        }
    }
}

#Preview {

    return ReviewDialog(model: TaskManagerViewModel(modelContext: sharedModelContainer(inMemory: true).mainContext).addSamples())
}
