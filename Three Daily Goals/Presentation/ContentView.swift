//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData

#if os(macOS)
    let dialogMinWidth = 1440
    let dialogMinHeight = 900
    let dialogMaxWidth = 2500
    let dialogMaxHeight = 1600
#endif

#if os(iOS)
    let dialogMinWidth = 1080
    let dialogMinHeight = 2340
    let dialogMaxWidth = 2796
    let dialogMaxHeight = 2340
#endif



struct SingleView<Content: View>: View {
    
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
    }
}

struct ContentView: View {
    @State var model : TaskManagerViewModel
    
    init(model: TaskManagerViewModel){
        self._model = State(wrappedValue: model)
    }
    
    var body: some View {
        GeometryReader { geometry in
            SingleView{
                NavigationSplitView {
                    LeftSideView(model: model).background(Color.background).frame(maxHeight: .infinity)
                        .navigationDestination(isPresented: $model.showItem) {
                            if let item = model.selectedItem {
                                TaskItemView(model:model, item: item)
                            }
                        }
#if os(macOS)
                        .navigationSplitViewColumnWidth(min: 300, ideal: 400)
#endif
                } content: {
                    SingleView{
#if os(macOS)
                        ListView( model: model).background(Color.background)
#endif
#if os(iOS)
                        Text("Placeholder")
#endif
                    }.background(Color.background)
                        .navigationSplitViewColumnWidth(min: 250, ideal: 400)
                }
            detail: {
                if let detail = model.selectedItem {
                    TaskItemView(model: model, item: detail)
                } else {
                    Text("Select an item")
                }
            }.background(Color.background)
                    .sheet(isPresented: $model.showReviewDialog) {
                        ReviewDialog(model: ReviewModel(taskModel: model))
                        
                    }
                    .sheet(isPresented: $model.showSettingsDialog) {
                        PreferencesView(model: model)
                    }
//                    .onAppear(perform: {
//                        preferences = loadPreferences(modelContext: modelContext )
//                    })
                    .environment(model.today)
            }//.background(Color.background).frame(width:geometry.size.width-20,height: geometry.size.height-20,alignment: .center)
        }
    }
    
    
}

#Preview {
    ContentView(model: TaskManagerViewModel(modelContext: TestStorage()))
    
}
