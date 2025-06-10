//
//  NullableDatePicker.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 05/03/2024.
//

import SwiftUI


struct DatePickerNullable: View {
    @Binding var selected: Date?
    let defaultDate: Date
    
    var body: some View {
        HStack {
            if let date = Binding($selected) {
                DatePicker(
                    "",
                    selection: date,
                    displayedComponents: [.date]
                )
#if os(macOS)
                .datePickerStyle(.stepperField)
#endif
                Button(action: {
                    selected = nil
                }) {
                    Image(systemName: "xmark.circle").font(.title2)
                }
                .padding(.trailing)
            } else {
                Button(action: {
                    selected = defaultDate
                }) {
                    HStack {
                        Text("isn't set")
                        Image(systemName: "plus.circle")
                    }
                }
                .background(Color.clear)
                Spacer()
            }
        }
    }
}

#Preview {
    //@Previewable
    @State var date: Date?
    return DatePickerNullable(selected: $date,defaultDate: getDate(inDays: 7))
}
