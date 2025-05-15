import SwiftUI

struct EmotionPickerModal: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedEmotion: String?

    let emotions: [(name: String, emoji: String, color: Color)] = [
        ("Happy", "😊", .pink),
        ("Sad", "😢", .gray),
        ("Angry", "😡", .red),
        ("Fear", "😱", .purple)
    ]

    var body: some View {
        VStack(spacing: 30) {
            Text("How are you feeling?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            ZStack {
                ForEach(0..<emotions.count, id: \.self) { index in
                    let emotion = emotions[index]
                    Button {
                        selectedEmotion = emotion.name
                    } label: {
                        VStack(spacing: 6) {
                            Text(emotion.emoji)
                                .font(.system(size: 32))
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
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .offset(circleOffset(index: index))
                }
            }
            .frame(width: 220, height: 220)

            Button(action: {
                print("Submitted: \(selectedEmotion ?? "None")")
                dismiss()
            }) {
                Text("Submit")
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
        .padding(.bottom)
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Circular Layout Helper
    func circleOffset(index: Int) -> CGSize {
        let radius: CGFloat = 90
        let angle = Double(index) * (360.0 / Double(emotions.count)) * (.pi / 180)

        let x = CGFloat(cos(angle)) * radius
        let y = CGFloat(sin(angle)) * radius
        return CGSize(width: x, height: y)
    }
}

