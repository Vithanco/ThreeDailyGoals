//
//  ReviewDialog.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 19/12/2023.
//

import SwiftUI


struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


struct ReviewDialog: View {
    
    @Bindable var model: TaskManagerViewModel
    //    @State private var sheetHeight: CGFloat = .zero
    
    var body: some View {
        VStack {
            
            HStack{
                Text("Daily Review").font(.title).foregroundStyle(model.accentColor)
                Spacer()
                Button(role: .cancel, action: model.cancelReview) {
                    Text("Cancel")
                }.buttonStyle(.bordered).frame(maxHeight: 30)
                Button(action: model.moveStateForward) {
                    Text(model.nameOfNextStep)
                }.buttonStyle(.borderedProminent)
            }
            Spacer()
            
            switch model.stateOfReview {
            case .inform:
                ReviewInformView(model: model)
            case .currentPriorities:
                ReviewCurrentPriorities(model: model)
            case .pending:
                ReviewPendingResponses(model:model)
            case .review:
                ReviewNextPriorities(model: model)
            case .dueDate:
                ReviewDueDate(model: model)
            case .plan:
                ReviewPlanDay(model: model, events: [], date: .today)
            }
            Spacer()
        }.padding(4).frame(minHeight: 350,idealHeight: 600)
    }
    //                .overlay {
    //                    GeometryReader { geometry in
    //                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
    //                    }
    //                }
    //                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
    //                    sheetHeight = newHeight
    //                }
    //                .presentationDetents([.height(sheetHeight)])
}


#Preview {
    let model = dummyViewModel()
    model.stateOfReview = .review
    return ReviewDialog(model: model)
}
