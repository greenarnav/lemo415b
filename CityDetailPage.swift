import SwiftUI

struct CityDetailPage: View {
    let city: CitySentiment
    
    var body: some View {
        ZStack {
            // Dynamic background gradient based on city emotion
            LinearGradient(
                gradient: Gradient(colors: EmotionTheme.gradientColors(for: city.label)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // City header section with emoji and mood
                    VStack(spacing: 16) {
                        Text(city.emoji)
                            .font(.system(size: 80))
                        
                        Text(city.city)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(EmotionTheme.textColor(for: city.label))
                        
                        HStack {
                            Text("Current Mood:")
                                .font(.headline)
                                .foregroundColor(EmotionTheme.textColor(for: city.label).opacity(0.8))
                            
                            Text(city.label)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(EmotionTheme.textColor(for: city.label))
                        }
                        
                        // Mood intensity bar
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Intensity")
                                    .font(.caption)
                                    .foregroundColor(EmotionTheme.textColor(for: city.label).opacity(0.8))
                                Spacer()
                                Text("\(Int(city.intensity * 100))%")
                                    .font(.caption)
                                    .foregroundColor(EmotionTheme.textColor(for: city.label).opacity(0.8))
                            }
                            
                            ProgressView(value: city.intensity)
                                .progressViewStyle(LinearProgressViewStyle(tint: EmotionTheme.cardColor(for: city.label)))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(EmotionTheme.cardColor(for: city.label).opacity(0.3))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // What people are thinking section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "thought.bubble.fill")
                                .font(.title3)
                                .foregroundColor(EmotionTheme.cardColor(for: city.label))
                            Text("What People Are Thinking")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(EmotionTheme.textColor(for: city.label))
                        }
                        
                        if city.whatPeopleThinking.isEmpty {
                            Text("No thoughts recorded at this time")
                                .foregroundColor(EmotionTheme.textColor(for: city.label).opacity(0.7))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(EmotionTheme.cardColor(for: city.label).opacity(0.2))
                                .cornerRadius(12)
                        } else {
                            ForEach(city.whatPeopleThinking, id: \.self) { thought in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(EmotionTheme.cardColor(for: city.label))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    
                                    Text(thought)
                                        .foregroundColor(EmotionTheme.textColor(for: city.label))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(EmotionTheme.cardColor(for: city.label).opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // What people care about section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.title3)
                                .foregroundColor(EmotionTheme.cardColor(for: city.label))
                            Text("What People Care About")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(EmotionTheme.textColor(for: city.label))
                        }
                        
                        if city.whatPeopleCare.isEmpty {
                            Text("No topics recorded at this time")
                                .foregroundColor(EmotionTheme.textColor(for: city.label).opacity(0.7))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(EmotionTheme.cardColor(for: city.label).opacity(0.2))
                                .cornerRadius(12)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                                ForEach(city.whatPeopleCare, id: \.self) { topic in
                                    HStack {
                                        Image(systemName: "tag.fill")
                                            .font(.caption)
                                            .foregroundColor(EmotionTheme.cardColor(for: city.label))
                                        Text(topic)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .foregroundColor(EmotionTheme.textColor(for: city.label))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(EmotionTheme.cardColor(for: city.label).opacity(0.2))
                                    .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // City statistics (dummy data)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .foregroundColor(EmotionTheme.cardColor(for: city.label))
                            Text("Mood Statistics")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(EmotionTheme.textColor(for: city.label))
                        }
                        
                        VStack(spacing: 12) {
                            // Recent trend
                            HStack {
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading) {
                                    Text("Mood Trend")
                                        .font(.headline)
                                        .foregroundColor(EmotionTheme.textColor(for: city.label))
                                    Text("Improving over last 7 days")
                                        .font(.caption)
                                        .foregroundColor(EmotionTheme.textColor(for: city.label).opacity(0.8))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(EmotionTheme.cardColor(for: city.label).opacity(0.2))
                            .cornerRadius(12)
                            
                            // Peak mood time
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(EmotionTheme.cardColor(for: city.label))
                                VStack(alignment: .leading) {
                                    Text("Peak Mood Time")
                                        .font(.headline)
                                        .foregroundColor(EmotionTheme.textColor(for: city.label))
                                    Text("Usually around 3:00 PM")
                                        .font(.caption)
                                        .foregroundColor(EmotionTheme.textColor(for: city.label).opacity(0.8))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(EmotionTheme.cardColor(for: city.label).opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Related moods section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .font(.title3)
                                .foregroundColor(EmotionTheme.cardColor(for: city.label))
                            Text("Related Moods")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(EmotionTheme.textColor(for: city.label))
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(getRelatedMoods(), id: \.self) { mood in
                                VStack(spacing: 8) {
                                    Text(getMoodEmoji(mood))
                                        .font(.title2)
                                    Text(mood)
                                        .font(.caption)
                                        .foregroundColor(EmotionTheme.textColor(for: city.label))
                                }
                                .padding()
                                .background(EmotionTheme.cardColor(for: city.label).opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 32)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(city.city)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper functions
    private func getRelatedMoods() -> [String] {
        switch city.label.lowercased() {
        case "happy":
            return ["Excited", "Joyful", "Optimistic"]
        case "sad":
            return ["Thoughtful", "Reflective", "Melancholic"]
        case "calm":
            return ["Peaceful", "Content", "Relaxed"]
        case "excited":
            return ["Energetic", "Happy", "Motivated"]
        case "neutral":
            return ["Content", "Stable", "Balanced"]
        default:
            return ["Thoughtful", "Reflective", "Contemplative"]
        }
    }
    
    private func getMoodEmoji(_ mood: String) -> String {
        switch mood.lowercased() {
        case "excited": return "🤩"
        case "joyful": return "😄"
        case "optimistic": return "🌟"
        case "thoughtful": return "🤔"
        case "reflective": return "🪞"
        case "melancholic": return "😔"
        case "peaceful": return "☮️"
        case "content": return "😊"
        case "relaxed": return "😌"
        case "energetic": return "⚡"
        case "motivated": return "💪"
        case "stable": return "⚖️"
        case "balanced": return "☯️"
        case "contemplative": return "🧘"
        default: return "😐"
        }
    }
}

// Preview
struct CityDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CityDetailPage(
                city: CitySentiment(
                    city: "San Francisco",
                    emoji: "😊",
                    label: "Happy",
                    intensity: 0.75,
                    whatPeopleThinking: [
                        "The weather is perfect today",
                        "Great new restaurants opening downtown",
                        "Tech scene is booming with opportunities"
                    ],
                    whatPeopleCare: [
                        "Community", "Innovation", "Environment", "Culture", "Food"
                    ]
                )
            )
        }
    }
}
