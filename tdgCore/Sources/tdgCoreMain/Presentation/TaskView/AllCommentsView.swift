//
//  AllCommentsView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 13/02/2024.
//

import SwiftUI

public struct AllCommentsView: View {
    @Bindable var item: TaskItem

    @State private var presentAlert: Bool 
    @State private var newComment: String

    public init(item: TaskItem, presentAlert: Bool = false, newComment: String = "") {
        self.item = item
        self.presentAlert = presentAlert
        self.newComment = newComment
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Add Comment button
            HStack {
                Text("History:").bold().foregroundColor(Color.secondary)
                Spacer()
                Button(action: { presentAlert = true }) {
                    Label("Add Comment", systemImage: "plus.circle.fill").help(
                        "Add some comment to the history of this task")
                }.accessibilityIdentifier("addCommentButton")
            }
            
            // Enhanced Last Updated section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(item.color)
                        .font(.system(size: 14, weight: .medium))
                    Text("Last Updated")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                Text(item.changed.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 22)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(item.color.opacity(0.05))
            .cornerRadius(8)
            
            // Comments section
            if let comments = item.comments, !comments.isEmpty {
                ForEach(comments.sorted(by: { $0.created > $1.created })) { comment in
                    CommentView(comment: comment)
                }
            } else {
                Text("No history yet").foregroundColor(.secondary).italic()
            }
            
            // Enhanced Created section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.open)
                        .font(.system(size: 14, weight: .medium))
                    Text("Created")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                Text(item.created.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 22)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.open.opacity(0.05))
            .cornerRadius(8)
        }
        .alert("Add Comment", isPresented: $presentAlert) {
            TextField("Comment", text: $newComment)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                if !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    item.addComment(text: newComment.trimmingCharacters(in: .whitespacesAndNewlines))
                    newComment = ""
                }
            }
        } message: {
            Text("Add a comment to the history of this task")
        }
    }
}

#Preview {
    AllCommentsView(item: TaskItem().addComment(text: "hello").addComment(text: "World"))
}
