//
//  SwiftUIView.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 17/12/2023.
//

import SwiftUI

public struct CommentView: View {
    let comment: Comment

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Icon column
            if let icon = comment.icon {
                Image(systemName: icon)
                    .foregroundStyle(comment.state?.color ?? .secondary)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20, alignment: .center)
            } else {
                // Placeholder for alignment
                Color.clear
                    .frame(width: 20)
            }

            // Content column
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.created, format: stdOnlyDateFormat)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Text(comment.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, comment.icon != nil ? 4 : 0)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(comment.state?.stateColorLight ?? Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(comment.state?.stateColorMedium ?? Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    CommentView(comment: Comment(text: "Hallo Klaus", taskItem: TaskItem(), icon: imgTouch))
}
