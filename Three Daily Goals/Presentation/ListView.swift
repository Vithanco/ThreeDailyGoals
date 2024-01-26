//
//  TaskListView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI




struct ListHeader: View, Identifiable{
    
    var id: String {
        return name
    }
    
    let name: String
    let image: String
    let timeFrom: Int
    let timeTo: Int
    
    func filter(item: TaskItem) -> Bool {
        let fromDate = getDate(daysPrior: timeFrom)
        let toDate = timeTo == 0 ? Date.now : getDate(daysPrior: timeTo)
        return item.changed > fromDate && item.changed <= toDate
    }
    
    var body: some View {
//        HStack{
            
//            Spacer()
//            ZStack {
//                Rectangle()
//                    .fill(Color.secondaryColor)
//                    .frame(width: 200, height: 18)
//                    .cornerRadius(9)
                Text("Last updated: " + name).font(.callout)
//                    .foregroundColor(.white)
//            }
//            Spacer()
//            Spacer()
//        }
    }
}

let secLastWeek = ListHeader(name: "Last Week", image: imgDated, timeFrom: 7, timeTo: 0)
let secLastMonth = ListHeader(name: "Last Month", image: imgDated, timeFrom: 30, timeTo: 7)
let secOlder = ListHeader(name: "over a month ago", image: imgDated, timeFrom: 1000000, timeTo: 30)


struct ListView: View {
    @State var whichList: TaskItemState?
    @Bindable var model: TaskManagerViewModel
    
    var list: TaskItemState {
        return whichList ?? model.whichList
    }
    
    let headers = [secOlder,secLastMonth,secLastWeek];
    
    var body: some View {
        let itemList = model.list(which: list)
        List{
            Section (header: VStack(alignment: .leading) {
                ForEach(list.sections) { sec in
                    sec.asText
                }
            }) {
                ForEach(headers) {header in
                    let partialList = itemList.filter(header.filter)
                    if partialList.count > 0 {
//                        if list != .priority {
                            header.listRowSeparator(.hidden)
//                        }
                        ForEach(partialList) { item in
                            LinkToTask(model: model,item: item, list: list).listRowSeparator(.hidden)
                        }
                    }
                }
            }
        }.frame(minHeight: 200).background(Color.background)
            .dropDestination(for: String.self){
                items, location in
                for item in items.compactMap({model.findTask(withID: $0)}) {
                    model.move(task: item, to: list)
                }
                return true
            }
#if os(iOS)
            .tdgToolbar(model: model)
#endif
    }
}

#Preview {
    ListView( model: TaskManagerViewModel(modelContext: TestStorage()))
}
