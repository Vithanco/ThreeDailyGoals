//
//  SwiftUIView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/12/2023.
//

import SwiftUI

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        LabeledContent{
            Text(comment.text).frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Added").foregroundColor(Color.secondaryColor)
            Text(comment.created, format: stdDateFormat).foregroundColor(Color.secondaryColor)
        }.frame(maxWidth: .infinity).background(Color(white: 250.0/255.0)).padding(2)
    }
}



#Preview {
    CommentView(comment: Comment(text: "Hallo Klaus", taskItem: TaskItem()))
}
