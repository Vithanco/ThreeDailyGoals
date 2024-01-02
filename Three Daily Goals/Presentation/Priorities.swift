////
////  Priorities.swift
////  Three Daily Goals
////
////  Created by Klaus Kneupner on 18/12/2023.
////
//
//import SwiftUI
//
//
//struct APriority: View {
//    @State var which: Int
//    @Bindable var model: TaskManagerViewModel
//    
//    var image: Image {
//        if which == 0 {
//            return Image(systemName: imgPriority1)
//        }
//        if which == 1 {
//            return Image(systemName: imgPriority2)
//        }
//        if which == 2 {
//            return Image(systemName: imgPriority3)
//        }
//        return Image(systemName: imgPriorityX)
//    }
//    
//    var body: some View {
//        HStack {
//            image
//            if let item = model.priority(which: which) {
//#if os(macOS)
//                HStack {
//                    Text(item.title).strikethrough(item.isClosed, color: .mainColor)
//                }.onTapGesture {
//                    model.select(which: .priorities, item: item)
//                }
//#endif
//#if os(iOS)
//                LinkToTask(item: item)
//#endif
//            }else {
//                Text("(missing)")
//            }
//        }
//    }
//}
//
//struct Priorities: View {
//    @Bindable var model: TaskManagerViewModel
//    var body: some View {   
//        VStack{
//            List {
//                NavigationLink {
//                    LinkToList(whichList: .priorities, model: model)
//                } label: {
//                    Section (header: Text("\(Image(systemName: imgToday)) Today")
//                        .font(.title)
//                        .foregroundStyle(Color.mainColor)
//                             //                    .onTapGesture {
//                             //                        model.select(which: .priorities, item: nil)
//                             //                    }
//                    ) {
//                        
//                        if let prios = model.today?.priorities {
//                            ForEach(0..<prios.count, id: \.self) { index in
//                                APriority(which: index, model: model)
//                            }
//                        }
//                    }
//                }.frame(maxHeight: .infinity)
//            }
//        }
//    }
//}
//
//
//#Preview {
//    Priorities(model: TaskManagerViewModel(modelContext: sharedModelContainer(inMemory: true).mainContext).addSamples())
//}
