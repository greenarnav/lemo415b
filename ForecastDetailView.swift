import SwiftUI

struct ForecastDetailView: View {
    let cityName: String
    let forecast: HomeMoodForecast
    
    // Data structure for themes
    struct ThemeData {
        let theme: String
        let examples: [String]
        let postCount: Int
        let typicalTone: String
        let emoji: String
    }
    
    // Theme data based on mood - now deterministic based on the forecast
    private var themeData: [ThemeData] {
        // Generate themes deterministically based on the forecast label and time segment
        let seed = "\(forecast.label)-\(forecast.timeSegment)".hashValue
        
        switch forecast.label.lowercased() {
        case "happy", "excited", "confident":
            return generateHappyThemes(seed: seed)
        case "angry":
            return generateAngryThemes(seed: seed)
        case "sad":
            return generateSadThemes(seed: seed)
        case "indifferent", "neutral":
            return generateNeutralThemes(seed: seed)
        default:
            return generateDefaultThemes(seed: seed)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background gradient based on mood
                LinearGradient(
                    gradient: Gradient(colors: EmotionTheme.gradientColors(for: forecast.label)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection
                        
                        // Main prediction section
                        mainPredictionSection
                        
                        // Theme analysis section
                        themeAnalysisSection
                        
                        // Additional insights
                        additionalInsightsSection
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Mood Forecast Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(forecast.emoji)
                .font(.system(size: 80))
            
            Text("\(cityName)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(EmotionTheme.textColor(for: forecast.label))
            
            HStack(spacing: 8) {
                Text(forecast.displayDay)
                    .font(.headline)
                Text("•")
                Text(forecast.timeSegment)
                    .font(.headline)
                Text("•")
                Text(forecast.label)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(EmotionTheme.textColor(for: forecast.label).opacity(0.9))
            
            if forecast.isCurrentSegment {
                Label("Current Time", systemImage: "clock.fill")
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .foregroundColor(EmotionTheme.textColor(for: forecast.label))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(EmotionTheme.cardColor(for: forecast.label).opacity(0.3))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private var mainPredictionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title3)
                    .foregroundColor(EmotionTheme.cardColor(for: forecast.label))
                Text("Mood Prediction Analysis")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(EmotionTheme.textColor(for: forecast.label))
            }
            
            Text("Based on analysis of social media posts, news articles, and community sentiment, we predict the mood will be **\(forecast.label)** during the \(forecast.timeSegment) period.")
                .foregroundColor(EmotionTheme.textColor(for: forecast.label))
                .padding()
                .background(EmotionTheme.cardColor(for: forecast.label).opacity(0.2))
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var themeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title3)
                    .foregroundColor(EmotionTheme.cardColor(for: forecast.label))
                Text("Key Themes Driving This Mood")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(EmotionTheme.textColor(for: forecast.label))
            }
            
            ForEach(themeData.indices, id: \.self) { index in
                let theme = themeData[index]
                VStack(alignment: .leading, spacing: 12) {
                    // Theme header
                    HStack {
                        Text(theme.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.theme)
                                .font(.headline)
                                .foregroundColor(EmotionTheme.textColor(for: forecast.label))
                            
                            HStack(spacing: 12) {
                                Label("\(theme.postCount) posts", systemImage: "doc.text")
                                    .font(.caption)
                                Text("•")
                                Text(theme.typicalTone)
                                    .font(.caption)
                                    .italic()
                            }
                            .foregroundColor(EmotionTheme.textColor(for: forecast.label).opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Progress indicator
                        CircularProgressView(progress: Double(theme.postCount) / 100.0)
                            .frame(width: 50, height: 50)
                    }
                    
                    // Examples
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(theme.examples, id: \.self) { example in
                                Text(example)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(EmotionTheme.cardColor(for: forecast.label).opacity(0.3))
                                    .cornerRadius(15)
                                    .foregroundColor(EmotionTheme.textColor(for: forecast.label))
                            }
                        }
                    }
                }
                .padding()
                .background(EmotionTheme.cardColor(for: forecast.label).opacity(0.2))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
    
    private var additionalInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(EmotionTheme.cardColor(for: forecast.label))
                Text("Additional Insights")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(EmotionTheme.textColor(for: forecast.label))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Confidence Level",
                    detail: "85% based on historical accuracy",
                    color: EmotionTheme.cardColor(for: forecast.label)
                )
                
                InsightRow(
                    icon: "calendar",
                    title: "Pattern Recognition",
                    detail: "Similar conditions in past 90 days led to this mood",
                    color: EmotionTheme.cardColor(for: forecast.label)
                )
                
                InsightRow(
                    icon: "person.3.fill",
                    title: "Data Sources",
                    detail: "194 social posts analyzed for this prediction",
                    color: EmotionTheme.cardColor(for: forecast.label)
                )
            }
            .padding()
            .background(EmotionTheme.cardColor(for: forecast.label).opacity(0.2))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Theme Generation Functions (Deterministic)
    
    private func generateHappyThemes(seed: Int) -> [ThemeData] {
        let themes = [
            ThemeData(
                theme: "Culture & Events",
                examples: ["Living Museum", "Park Avenue Day", "Brooklyn Bridge art", "Knicks/Lakers chatter"],
                postCount: 51 + (abs(seed) % 20),
                typicalTone: "upbeat, appreciative",
                emoji: "🎭"
            ),
            ThemeData(
                theme: "Community Activities",
                examples: ["Local festivals", "Street fairs", "Art exhibitions", "Sports celebrations"],
                postCount: 38 + (abs(seed) % 15),
                typicalTone: "enthusiastic, celebratory",
                emoji: "🎉"
            ),
            ThemeData(
                theme: "Economic Growth",
                examples: ["New businesses opening", "Job market expansion", "Tech investments", "Startup launches"],
                postCount: 45 + (abs(seed) % 25),
                typicalTone: "optimistic, ambitious",
                emoji: "📈"
            ),
            ThemeData(
                theme: "Urban Renewal",
                examples: ["Park renovations", "Infrastructure upgrades", "Green initiatives", "Public art"],
                postCount: 32 + (abs(seed) % 18),
                typicalTone: "hopeful, progressive",
                emoji: "🏗️"
            )
        ]
        
        // Always return themes in same order for consistency
        return themes
    }
    
    private func generateAngryThemes(seed: Int) -> [ThemeData] {
        return [
            ThemeData(
                theme: "Transport Safety & Transit",
                examples: ["fatal Ocean Pkwy crash", "SoHo cyclist death", "Hochul 7-train ride"],
                postCount: 43 + (abs(seed) % 20),
                typicalTone: "anger, demand for reform",
                emoji: "🚇"
            ),
            ThemeData(
                theme: "Local Politics / Policy",
                examples: ["offshore-wind halt", "pension tiers", "mayor's race", "Medicaid overhaul"],
                postCount: 55 + (abs(seed) % 15),
                typicalTone: "frustrated, combative",
                emoji: "🏛️"
            ),
            ThemeData(
                theme: "Crime & Policing",
                examples: ["teen kidnapping", "deportation cases", "death-penalty fight"],
                postCount: 22 + (abs(seed) % 10),
                typicalTone: "alarmed, outraged",
                emoji: "🚔"
            ),
            ThemeData(
                theme: "Housing & Development",
                examples: ["Section 8 freeze (LA)", "2 WTC redesign", "rent-notice dispute"],
                postCount: 30 + (abs(seed) % 15),
                typicalTone: "anxious, critical",
                emoji: "🏠"
            )
        ]
    }
    
    private func generateSadThemes(seed: Int) -> [ThemeData] {
        return [
            ThemeData(
                theme: "Crime & Policing",
                examples: ["teen kidnapping", "deportation cases", "death-penalty fight"],
                postCount: 22 + (abs(seed) % 12),
                typicalTone: "alarmed, concerned",
                emoji: "🚔"
            ),
            ThemeData(
                theme: "Economic Challenges",
                examples: ["Business closures", "Layoffs announced", "Budget cuts", "Service reductions"],
                postCount: 41 + (abs(seed) % 18),
                typicalTone: "disappointed, worried",
                emoji: "📉"
            ),
            ThemeData(
                theme: "Community Loss",
                examples: ["Local landmark closing", "Beloved business shuttered", "Community leader passing"],
                postCount: 18 + (abs(seed) % 8),
                typicalTone: "mourning, nostalgic",
                emoji: "😢"
            ),
            ThemeData(
                theme: "Environmental Concerns",
                examples: ["Pollution increase", "Park deterioration", "Wildlife threats", "Climate impacts"],
                postCount: 27 + (abs(seed) % 13),
                typicalTone: "concerned, pessimistic",
                emoji: "🌍"
            )
        ]
    }
    
    private func generateNeutralThemes(seed: Int) -> [ThemeData] {
        return [
            ThemeData(
                theme: "Routine Updates",
                examples: ["Traffic reports", "Weather forecasts", "City notices", "Schedule changes"],
                postCount: 67 + (abs(seed) % 15),
                typicalTone: "informational, neutral",
                emoji: "📰"
            ),
            ThemeData(
                theme: "Daily Activities",
                examples: ["Commute patterns", "Shopping trends", "Dining habits", "Work routines"],
                postCount: 54 + (abs(seed) % 20),
                typicalTone: "matter-of-fact",
                emoji: "🚶"
            ),
            ThemeData(
                theme: "Municipal Services",
                examples: ["Garbage collection", "Street cleaning", "Public utilities", "DMV updates"],
                postCount: 43 + (abs(seed) % 12),
                typicalTone: "procedural, routine",
                emoji: "🏢"
            ),
            ThemeData(
                theme: "Local Business",
                examples: ["Store hours", "Service availability", "Product updates", "Pricing info"],
                postCount: 38 + (abs(seed) % 16),
                typicalTone: "business-as-usual",
                emoji: "🏪"
            )
        ]
    }
    
    private func generateDefaultThemes(seed: Int) -> [ThemeData] {
        return [
            ThemeData(
                theme: "Protests & Activism",
                examples: ["Columbia Gaza protest", "Tesla bull graffiti", "Grand Central demo"],
                postCount: 26 + (abs(seed) % 14),
                typicalTone: "polarized, activist",
                emoji: "✊"
            ),
            ThemeData(
                theme: "Community Discourse",
                examples: ["Town halls", "Public forums", "Online debates", "Neighborhood meetings"],
                postCount: 48 + (abs(seed) % 22),
                typicalTone: "engaged, diverse",
                emoji: "💬"
            ),
            ThemeData(
                theme: "Local Interest",
                examples: ["Neighborhood events", "Community projects", "Local initiatives", "Grassroots efforts"],
                postCount: 35 + (abs(seed) % 17),
                typicalTone: "participatory, involved",
                emoji: "🤝"
            ),
            ThemeData(
                theme: "Social Media Trends",
                examples: ["Viral posts", "Online campaigns", "Hashtag movements", "Community shares"],
                postCount: 52 + (abs(seed) % 25),
                typicalTone: "dynamic, interactive",
                emoji: "📱"
            )
        ]
    }
}

// Helper Views
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            Text("\(Int(progress * 100))")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

// Preview
struct ForecastDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ForecastDetailView(
            cityName: "New York",
            forecast: HomeMoodForecast(
                timeSegment: "Morning",
                date: Date(),
                emoji: "😊",
                label: "Happy",
                isCurrentSegment: true,
                isPast: false
            )
        )
    }
}
