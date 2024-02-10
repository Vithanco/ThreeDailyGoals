//
//  ReviewNextPriorities.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 31/01/2024.
//

import SwiftUI

struct ReviewNextPriorities: View {

    @Bindable var model: ReviewModel
    
    var body: some View {
        #if os(macOS)
        VStack{
                Text("Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {
                ListView(whichList: .priority, model: model.taskModel).frame(minHeight: 300)
                ListView(whichList: .open ,model: model.taskModel)
            }
        }
        #endif
#if os(iOS)  // delete this once iOS works as expected and keep macOS path for all
        VStack{
            Text("Choose Next Priorities via drag'n'drop \(Image(systemName: "arrowshape.left.arrowshape.right.fill"))").font(.title2).foregroundStyle(model.accentColor).multilineTextAlignment(.center)
            HStack {

                VStack{
                    HStack {
                        Spacer()
                        Circle().frame(width: 10).foregroundColor(.accentColor).help("Drop Target because iOS has an issue. Will be hopefully removed with next version of iOS.")
                        Spacer()
                    }.dropDestination(for: String.self){
                        items, location in
                        for item in items.compactMap({
                            model.taskModel.findTask(withID: $0)}) {
                            model.taskModel.move(task: item, to: .priority)
                        }
                        return true
                    }
                    ListView(whichList: .priority, model: model.taskModel).frame(minHeight: 300)
                }
                VStack{
                    HStack {
                        Spacer()
                        Circle().frame(width: 10).foregroundColor(.accentColor).help("Drop Target, as iOS has an issue. Will be hopefully removed with next version of iOS.")
                        Spacer()
                    }.dropDestination(for: String.self){
                        items, location in
                        for item in items.compactMap({model.taskModel.findTask(withID: $0)}) {
                            model.taskModel.move(task: item, to: .priority)
                        }
                        return true
                    }
                    ListView(whichList: .open ,model: model.taskModel)
                }
            }
        }
#endif
    }
}

#Preview {
    ReviewNextPriorities(model: dummyReviewModel())
}
