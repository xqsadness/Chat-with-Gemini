//
//  Chat.swift
//  ChatWithGemini
//
//  Created by xqsadness on 14/06/2024.
//

import Foundation

enum ChatRole{
    case user
    case model
}

struct ChatMessage: Identifiable, Equatable{
    let id = UUID().uuidString
    var role: ChatRole
    var message: String
    var images: [Data]?
}
