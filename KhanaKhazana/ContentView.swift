//
//  ContentView.swift
//  KhanaKhazana
//
//  Created by Harshit Gupta on 07/05/25.
//

import SwiftUI

struct ContentView: View {
    // Use EnvironmentObject instead of StateObject to ensure consistent state across the app
    @EnvironmentObject private var dataController: DataController
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            HomeView()
                .environmentObject(dataController)
            
            if isLoading {
                ProgressView("Loading cuisines...")
                    .padding()
                    .background(Color.brown.opacity(0.2))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .onAppear {
            // Check if data is already loaded
            if dataController.isAPIWorking {
                isLoading = false
            } else {
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
            
            // Debug print cart content on startup
            if let cart = dataController.getCart(), !cart.cartItems.isEmpty {
                print("ContentView appeared with \(cart.cartItems.count) items in cart")
                for (index, item) in cart.cartItems.enumerated() {
                    print("Cart item \(index + 1): \(item.dish.name), Quantity: \(item.quantity)")
                }
            } else {
                print("ContentView appeared with empty cart")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataController.shared)
}
