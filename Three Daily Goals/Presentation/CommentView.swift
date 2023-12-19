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
            Text(comment.text).background(Color(white: 230.0/255.0)).frame(idealHeight: 30)
        } label: {
            Text("Added").foregroundColor(secondaryColor)
            Text(comment.created, format: stdDateFormat).foregroundColor(secondaryColor)
        }.background(.white)
    }
}



#Preview {
    CommentView(comment: Comment(text: "Hallo Klaus", taskItem: TaskItem()))
}
