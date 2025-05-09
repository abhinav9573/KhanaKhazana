//
//  ContentView.swift
//  KhanaKhazana
//
//  Created by Harshit Gupta on 07/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataController = DataController.shared
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            HomeView()
            
            if isLoading {
                ProgressView("Loading cuisines...")
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .onAppear {
            Task {
                do {
                    try await dataController.loadCuisines(count: 10)
                    isLoading = false
                } catch {
                    print("Error loading cuisines: \(error)")
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
