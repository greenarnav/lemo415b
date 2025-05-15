//
//  HomeSearchView.swift
//  MoodGpt
//
//  Created by Test on 5/7/25.
//


// HomeSearchView.swift
import SwiftUI

struct HomeSearchView: View {
    @Binding var searchText: String
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.7))
            TextField("Search cities…", text: $searchText)
                .foregroundColor(.white)
                .accentColor(.white)
            if !searchText.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}