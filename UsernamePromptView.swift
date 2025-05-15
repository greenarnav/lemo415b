import SwiftUI

struct UsernamePromptView: View {
    @State private var username: String = ""
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @Binding var isPresented: Bool
    
    private let minUsernameLength = 3
    private let maxUsernameLength = 20
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 30) {
                // App logo and title
                VStack(spacing: 15) {
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("MoodGPT")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Feel the pulse of your city")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Username input section
                VStack(spacing: 20) {
                    Text("What should we call you?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter your name", text: $username)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: username) { oldValue, newValue in
                            // Restrict to allowed characters
                            let filteredValue = newValue.filter {
                                $0.isLetter || $0.isNumber || $0 == "_" || $0 == "."
                            }
                            if filteredValue != newValue {
                                username = filteredValue
                            }
                        }
                    
                    if showingError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(Color.red.opacity(0.9))
                            .padding(.horizontal)
                    }
                    
                    // Continue button
                    Button(action: {
                        validateAndSaveUsername()
                    }) {
                        Text("Continue")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(27)
                    }
                    .padding(.top, 10)
                    
                    // Use a random name
                    Button(action: {
                        username = generateRandomUsername()
                    }) {
                        Text("Generate Random Name")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Terms
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .underline()
                        
                        Text("and")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .underline()
                    }
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
        .onAppear {
            // Check if a username already exists
            if let existingUsername = UserDefaults.standard.string(forKey: "moodgpt_username"),
               !existingUsername.isEmpty {
                username = existingUsername
            }
        }
    }
    
    private func validateAndSaveUsername() {
        // Trim whitespace
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate
        if trimmedUsername.isEmpty {
            showError("Please enter a name")
            return
        }
        
        if trimmedUsername.count < minUsernameLength {
            showError("Name must be at least \(minUsernameLength) characters")
            return
        }
        
        if trimmedUsername.count > maxUsernameLength {
            showError("Name must be less than \(maxUsernameLength) characters")
            return
        }
        
        // All validations passed, save the username
        UserDefaults.standard.set(trimmedUsername, forKey: "moodgpt_username")
        
        // Log this activity
        ActivityAPIClient.shared.logActivity(
            email: trimmedUsername,
            action: "setUsername",
            details: [
                "username": trimmedUsername,
                "isFirstTime": UserDefaults.standard.bool(forKey: "hasBeenLaunchedBefore") == false
            ]
        )
        
        // Dismiss the prompt
        isPresented = false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func generateRandomUsername() -> String {
        let adjectives = ["Happy", "Calm", "Bright", "Swift", "Clever", "Gentle", "Kind", "Cool", "Smart", "Sunny"]
        let nouns = ["Explorer", "Dreamer", "Voyager", "Thinker", "Wanderer", "Spirit", "Creator", "Rider", "Seeker", "Mind"]
        
        let randomAdjective = adjectives.randomElement() ?? "Happy"
        let randomNoun = nouns.randomElement() ?? "Explorer"
        let randomNumber = Int.random(in: 10...999)
        
        return "\(randomAdjective)\(randomNoun)\(randomNumber)"
    }
}

struct UsernamePromptView_Previews: PreviewProvider {
    static var previews: some View {
        UsernamePromptView(isPresented: .constant(true))
    }
}
