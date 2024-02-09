//
//  ContentView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/12/2023.
//

import SwiftUI
import SwiftData

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
                    Text("Placeholder").redacted(reason: /*@START_MENU_TOKEN@*/.placeholder/*@END_MENU_TOKEN@*/)
#endif
                }.background(Color.background)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 400)
                    .navigationTitle("Three Daily Goals")
#if os(macOS)
                    .navigationSubtitle(
                        streakView(model: model)).multilineTextAlignment(.center)
#endif
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
        }
    }
}

#Preview {
    ContentView(model: dummyViewModel())
#if os(macOS)
        .frame(width: 1000, height: 600)
#endif
    
    
}
