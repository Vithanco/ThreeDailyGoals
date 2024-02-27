//
//  AllCommentsView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 13/02/2024.
//

import SwiftUI

struct AllCommentsView: View {
    @Bindable var item: TaskItem
    
    @State private var presentAlert = false
    @State private var newComment: String = ""
    
    var body: some View {
        EmptyView()
//        VStack (alignment: .leading){
//            HStack{
//                Text("History:").bold().foregroundColor(Color.secondaryColor)
//                Spacer()
//                Button(action: {presentAlert = true}) {
//                    Label("Add Comment", systemImage: "plus.circle.fill").help("Add some comment to the history of this task")
//                }.accessibilityIdentifier("addCommentButton")
//            }
//            if let comments = item.comments, comments.count > 0 {
//                List{
//                    ForEach(comments.sorted()){comment in
//                        CommentView(comment: comment).frame(maxWidth: .infinity)
//                    }.listRowInsets( EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) )
//                }
//            } else {
//                Text("No comments yet")
//            }
//            
//        }.alert("Add Comment", isPresented: $presentAlert, actions: {
//            TextField("Comment Text", text: $newComment)
//            
//            Button("Cancel", role: .cancel, action: {presentAlert = false})
//            Button("Add", action: {
//                presentAlert = false
//                item.addComment(text: newComment)
//            })
//        }, message: {
//            Text("Please enter new Comment")
//        })
    }
}

#Preview {
    AllCommentsView(item: TaskItem().addComment(text: "hello").addComment(text: "World"))
}
