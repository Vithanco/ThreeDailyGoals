//
//  ReviewDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI


struct InnerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ReviewDialog: View {
    enum DialogState {
        case inform
        case review
    }
    
    @Bindable var model: TaskManagerViewModel
    @State var state: DialogState = .inform
    
    @State private var sheetHeight: CGFloat = .zero
    
    func removePrioritiesAndStartReview(){
        for p in model.priorityTasks {
            model.move(task: p, to: .open)
        }
        state = .review
    }
    
    func startReviewWithClosingAll(){
        for p in model.priorityTasks {
            model.move(task: p, to: .closed)
        }
        state = .review
    }
    
    func keepPrioritiesAndReview() {
        state = .review
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
        let hasTasks = (model.priorityTasks.count) > 0
        switch state {
            case .inform:
                VStack {
                    Text("Review your Tasks!").font(.title).foregroundStyle(Color.mainColor)
                    if hasTasks {
                        Text("The previous Tasks were: ")
                        ListView(whichList: .priority, model: model)
                    } else {
                        Text("No previous Tasks")
                    }
                    if model.pendingTasks.count > 0 {
                        Spacer()
                        Text("Can you close some tasks you wait for?").font(.title).foregroundStyle(Color.mainColor)
                        ListView(whichList: .pendingResponse, model: model)
                    }
                    
                    HStack{
                        Button(action: cancelReview){
                            Text("Cancel")
                        }
                        Spacer()
                        if hasTasks {
                            Button(action: keepPrioritiesAndReview) {
                                Text("Keep Priorities and Review Now")
                            }
                            Button(action: startReviewWithClosingAll ){
                                Text("Close All and Review Now")
                            }
                            Spacer()
                        }
                        Button(action: removePrioritiesAndStartReview){
                            Text("Review Now")
                        }
                    }
                    
                }.padding(4)
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                        }
                    }
                    .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                        sheetHeight = newHeight
                    }
                    .presentationDetents([.height(sheetHeight)])
            case .review:
                VStack{
                    
                    Text("Choose Today's Priorities!").font(.title).foregroundStyle(Color.mainColor)
                    HStack {
                        ListView(whichList: .priority, model: model).frame(minHeight: 300)
                        VStack {
                            Image(systemName: "arrowshape.left.arrowshape.right.fill")
                            Text("drag'n'drop")
                            
                        }
                        ListView(whichList: .open ,model: model)
                    }
                    Button(action: endReview){
                        Text("Done")
                    }
                }.padding(4)
        }
    }
}

#Preview {
    return ReviewDialog(model: TaskManagerViewModel(modelContext: TestStorage()))
}
