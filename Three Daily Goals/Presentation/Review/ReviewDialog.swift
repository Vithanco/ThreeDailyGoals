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
    
    @Bindable var model: ReviewModel
    @State private var sheetHeight: CGFloat = .zero
    
    var body: some View {
        VStack {
            GroupBox(label:
                        HStack{
                Text("Review your Tasks!").font(.title).foregroundStyle(model.accentColor)
                Spacer()
                Button(role: .cancel, action: model.cancelReview) {
                    Text("Cancel")
                }
                Button(action: model.moveStateForward) {
                    Text(model.nameOfNextStep)
                }.buttonStyle(.borderedProminent)
            }){
                
                switch model.stateOfReview {
                    case .inform:
                        Inform(model: model)
                    case .currentPriorities:
                        ReviewCurrentPriorities(model: model)
                    case .pending:
                        ReviewPendingResponses(model:model)
                    case .review:
                        ReviewNextPriorities(model: model)
                }
                
            }.padding(4)
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
    
}

#Preview {
    return ReviewDialog(model: dummyReviewModel())
}
