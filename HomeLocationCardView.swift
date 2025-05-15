import SwiftUI

struct HomeLocationCardView: View {
    let city: CitySentiment
    
    var body: some View {
        HStack(spacing: 16) {
            Text(city.emoji).font(.system(size: 64))
            VStack(alignment: .leading, spacing: 4) {
                Text(city.city).font(.title2).bold().foregroundColor(.white)
                Text("Current Mood: \(city.label)")
                    .foregroundColor(.white.opacity(0.9))
                ProgressView(value: city.intensity)
                    .progressViewStyle(LinearProgressViewStyle(tint: EmotionTheme.cardColor(for: city.label)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [EmotionTheme.cardColor(for: city.label).opacity(0.6), .black.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
