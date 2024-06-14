//
//  ContentView.swift
//  ChatWithGemini
//
//  Created by xqsadness on 14/06/2024.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    
    @State private var textInput = ""
    @State private var chatService = ChatService()
    @State private var photoPickerItems = [PhotosPickerItem]()
    @State private var selectedPhotoData = [Data]()
    
    var body: some View {
        ZStack{
            Color.black.ignoresSafeArea()
            
            VStack {
                // MARK: Logo
                Image(.geminiLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                
                // MARK: Chat message list
                ScrollViewReader(content: { proxy in
                    ScrollView {
                        ForEach(chatService.messages) { chatMessage in
                            // MARK: Chat message view
                            chatMessageView(chatMessage)
                        }
                        .padding(.top, 20)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: chatService.messages) {
                        guard let recentMessage = chatService.messages.last else { return }
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(recentMessage.id, anchor: .bottom)
                            }
                        }
                    }
                })
                
                // MARK: Image preview
                if selectedPhotoData.count > 0 {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 10, content: {
                            ForEach(0..<selectedPhotoData.count, id: \.self) { index in
                                Image(uiImage: UIImage(data: selectedPhotoData[index])!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                        })
                    }
                    .frame(height: 50)
                    .scrollIndicators(.hidden)
                }
                
                // MARK: Input fields
                HStack {
                    PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 3, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .frame(width: 40, height: 25)
                    }
                    .onChange(of: photoPickerItems) {
                        Task {
                            selectedPhotoData.removeAll()
                            for item in photoPickerItems {
                                if let imageData = try await item.loadTransferable(type: Data.self) {
                                    selectedPhotoData.append(imageData)
                                }
                            }
                        }
                    }
                    
                    TextField("Enter a message...", text: $textInput)
                        .textFieldStyle(.roundedBorder)
                        .background(Color.black)
                        .foregroundStyle(Color.white)
                        .onSubmit {
                            if !textInput.isEmpty{
                                sendMessage()
                            }
                        }
                    
                    if chatService.loadingResponse {
                        // MARK: Loading indicator
                        ProgressView()
                            .tint(Color.white)
                            .frame(width: 30)
                    } else {
                        // MARK: Send button
                        Button{
                            sendMessage()
                        }label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.blue)
                        }
                        .frame(width: 30)
                        .disabled(textInput.isEmpty)
                        .opacity(textInput.isEmpty ? 0.5 : 1)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal)
        }
    }
    
    // MARK: Chat message view
    @ViewBuilder private func chatMessageView(_ message: ChatMessage) -> some View {
        // MARK: Chat image dislay
        if let images = message.images, images.isEmpty == false {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10, content: {
                    ForEach(0..<images.count, id: \.self) { index in
                        Image(uiImage: UIImage(data: images[index])!)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .containerRelativeFrame(.horizontal)
                    }
                })
                .scrollTargetLayout()
            }
            .frame(height: 150)
            .scrollIndicators(.hidden)
        }
        
        // MARK: Chat message bubble
        ChatBubble(direction: message.role == .model ? .left : .right) {
            if message.message.isEmpty{
                ProgressView()
                    .frame(width: 45, height: 45)
                    .background(BackgroundStyle.background, in: .rect(cornerRadius: 5))
            }else{
                Text(message.message)
                    .font(.title3)
                    .padding(.all, 20)
                    .foregroundStyle(.white)
                    .background(message.role == .model ? Color.blue : Color.green)
                    .foregroundStyle(.primary)
            }
        }
        .overlay(alignment: message.role == .model ? .topLeading : .topTrailing){
            Text(message.role == .model ? "Gemini" : "Your")
                .foregroundStyle(message.role == .model ? .indigo : .white)
                .offset(y: -10)
        }
    }
    
    // MARK: Fetch response
    private func sendMessage() {
        Task {
            await chatService.sendMessage(message: textInput, imageData: selectedPhotoData)
            textInput = ""
            selectedPhotoData.removeAll()
        }
    }
}
