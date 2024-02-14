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
            Text(comment.created, format: stdOnlyDateFormat)//.foregroundColor(Color.secondaryColor)
        }.frame(maxWidth: .infinity).padding(1)//.background(Color.secondaryBackground)
    }
}

#Preview {
    CommentView(comment: Comment(text: "Hallo Klaus", taskItem: TaskItem()))
}
