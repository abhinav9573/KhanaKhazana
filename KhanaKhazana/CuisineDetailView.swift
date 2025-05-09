import SwiftUI

struct CuisineDetailView: View {
    let cuisine: Cuisine
    @EnvironmentObject private var dataController: DataController
    @State var selectedLanguage: Language = .english
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Cuisine Header
                        AsyncImage(url: URL(string: cuisine.image)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text(cuisine.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Dishes List
                        if !isLoading {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                ForEach(cuisine.dishes, id: \.id) { dish in
                                    DishTile(dish: dish, selectedLanguage: $selectedLanguage)
                                        .environmentObject(dataController)
                                        .id(dish.id)
                                        .onTapGesture {
                                            print("Tapped dish in cuisine view: \(dish.name), ID: \(dish.id)")
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.6))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedLanguage = selectedLanguage == .english ? .hindi : .english
                    }) {
                        Text(selectedLanguage == .english ? "अ" : "A")
                            .padding(.horizontal, 12)
                            .padding(.vertical, selectedLanguage == .english ? 8 : 7)
                            .background(Color.green.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(.infinity)
                    }
                }
            }
            .onAppear {
                // Set a small delay to ensure data is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                }
                
                print("CuisineDetailView appeared with \(cuisine.dishes.count) dishes")
                cuisine.dishes.forEach { dish in
                    print("Dish: \(dish.name), ID: \(dish.id), Price: \(dish.price)")
                }
                
                // Debug print cart status
                if let cart = dataController.getCart(), !cart.cartItems.isEmpty {
                    print("CuisineDetailView: cart has \(cart.cartItems.count) items")
                } else {
                    print("CuisineDetailView: cart is empty")
                }
            }
        }
    }
} 
