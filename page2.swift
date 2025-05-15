import SwiftUI

struct Page2: View {
    var body: some View {
        VStack(spacing: 20) {
           
            // MAP BUTTON
            NavigationLink(destination: MapScreen()) {
                Text("🗺️ Open Map")
                    .font(.title2)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .navigationTitle("Page 2")
    }
}

#Preview {
    NavigationStack {
        Page2()
    }
}
