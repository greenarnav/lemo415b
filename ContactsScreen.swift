import SwiftUI

struct ContactsScreen: View {
    @StateObject private var viewModel = ContactsViewModel()
    @StateObject private var apiService = ApiIntegrationService.shared
    @State private var searchText = ""
    @State private var showingSyncStatus = false
    
    var filteredContacts: [ContactsViewModel.Row] {
        if searchText.isEmpty {
            return viewModel.rows
        } else {
            return viewModel.rows.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                contact.city.localizedCaseInsensitiveContains(searchText) ||
                contact.phone.contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.5), .white.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Contacts").font(.title2)
                        Spacer()
                        
                        // Sync status indicator
                        if viewModel.isSyncing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else if apiService.lastSync != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .onTapGesture {
                                    showingSyncStatus = true
                                }
                        }
                        
                        if !viewModel.loading && viewModel.authorizationStatus == .authorized {
                            Text("\(viewModel.rows.count) contacts")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    
                    // Search bar (only show if authorized and has contacts)
                    if viewModel.authorizationStatus == .authorized && !viewModel.rows.isEmpty {
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                    }
                    
                    if viewModel.loading {
                        Spacer()
                        ProgressView("Loading contacts...")
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    } else if viewModel.authorizationStatus != .authorized {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Contacts Access Required")
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            if let error = viewModel.permissionError {
                                Text(error)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else {
                                Text("Please grant access to contacts in Settings")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .padding()
                        Spacer()
                    } else if viewModel.rows.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("No Contacts Found")
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            Text("Your contact list appears to be empty")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredContacts) { contact in
                                    ContactCityNavigationLink(contact: contact)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Sync button at the bottom
                    if viewModel.authorizationStatus == .authorized && !viewModel.rows.isEmpty {
                        Button(action: {
                            Task {
                                await viewModel.syncContactsToAPI()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(viewModel.isSyncing ? "Syncing..." : "Sync Contacts")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isSyncing)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSyncStatus) {
                SyncStatusView(lastSync: apiService.lastSync)
            }
            .onAppear {
                viewModel.load()
            }
        }
    }
}

// Contact Navigation Link
struct ContactCityNavigationLink: View {
    let contact: ContactsViewModel.Row
    @StateObject private var consistentService = ConsistentCitySentimentService.shared
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            ContactRowContent(contact: contact)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!contact.hasLocation)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if contact.hasLocation {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if contact.hasLocation {
            if let citySentiment = consistentService.citySentiments.first(where: { $0.city.lowercased() == contact.city.lowercased() }) {
                CityDetailPage(city: citySentiment)
            } else {
                CityDetailPage(city: consistentService.getCitySentiment(for: contact.city))
            }
        } else {
            EmptyView()
        }
    }
}

// Contact Row Content
struct ContactRowContent: View {
    let contact: ContactsViewModel.Row
    
    var body: some View {
        HStack(spacing: 16) {
            // Contact emoji
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Text(contact.emoji)
                    .font(.system(size: 32))
            }
            
            // Contact info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(contact.phone)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    // Location badge
                    HStack(spacing: 4) {
                        Image(systemName: contact.hasLocation ? "location.fill" : "location.slash")
                            .font(.caption2)
                        Text(contact.city)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(contact.hasLocation ? Color.white.opacity(0.15) : Color.red.opacity(0.15))
                    .cornerRadius(8)
                    
                    // Mood badge
                    if contact.hasLocation && contact.mood != "Unknown" {
                        Text(contact.mood)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(getMoodColor(contact.mood).opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // Arrow indicator for clickable cities
            if contact.hasLocation {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            } else {
                // Lock icon for no location
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .opacity(contact.hasLocation ? 1.0 : 0.6)
    }
    
    func getMoodColor(_ mood: String) -> Color {
        switch mood.lowercased() {
        case "happy":
            return .green
        case "sad":
            return .blue
        case "indifferent":
            return .gray
        case "angry":
            return .red
        case "calm":
            return .mint
        case "chaotic":
            return .purple
        default:
            return .gray
        }
    }
}

// Sync Status View
struct SyncStatusView: View {
    let lastSync: Date?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.5), .white.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("Contacts Synced")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let lastSync = lastSync {
                        VStack(spacing: 8) {
                            Text("Last synced:")
                                .foregroundColor(.white.opacity(0.7))
                            Text(lastSync, style: .relative)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(lastSync, format: .dateTime)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            
            TextField("Search contacts...", text: $text)
                .foregroundColor(.white)
                .accentColor(.white)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
    }
}
