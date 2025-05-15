//
//   EmotionPickerView.swift
//  MoodGpt
//
//  Created by Test on 4/26/25.
//

import SwiftUI

// MARK: - EmotionPickerView
struct EmotionPickerView: View {
    @Binding var isShowing: Bool
    @Binding var selectedEmotion: String?
    let onSubmit: () -> Void
    
    let emotions: [(name: String, emoji: String, color: Color)] = [
        ("Happy", "😊", .green),
        ("Sad", "😢", .blue),
        ("Angry", "😡", .red),
        ("Fear", "😱", .purple),
        ("Excited", "😃", .orange),
        ("Calm", "😌", .mint),
        ("Tired", "😴", .gray),
        ("Surprised", "😲", .yellow)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("How are you feeling?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.top, 24)
            
            // Emotion Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                ForEach(emotions, id: \.name) { emotion in
                    Button {
                        selectedEmotion = emotion.name
                    } label: {
                        VStack(spacing: 8) {
                            Text(emotion.emoji)
                                .font(.system(size: 36))
                                .padding()
                                .background(
                                    Circle()
                                        .fill(
                                            selectedEmotion == emotion.name
                                            ? emotion.color.opacity(0.3)
                                            : Color.white.opacity(0.1)
                                        )
                                )
                            
                            Text(emotion.name)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Submit Button
            Button(action: {
                if selectedEmotion != nil {
                    onSubmit()
                    isShowing = false
                }
            }) {
                Text("Submit")
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedEmotion != nil ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(selectedEmotion == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black)
        )
        .frame(width: UIScreen.main.bounds.width - 40)
        .shadow(radius: 20)
    }
}
