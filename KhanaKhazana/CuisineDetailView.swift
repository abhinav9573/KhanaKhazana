//
//  CuisineDetailView.swift
//  KhanaKhazana
//

import SwiftUI

struct CuisineDetailView: View {
    let cuisine: Cuisine
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataController: DataController
    
    var body: some View {
        VStack(spacing: 0) {
            // Header image with back button
            ZStack(alignment: .top) {
                // Header Image
                AsyncImage(url: URL(string: cuisine.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(height: 200)
                .clipped()
                
                // Gradient overlay for better visibility of content against the image
                LinearGradient(
                    gradient: Gradient(
                        colors: [
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.1),
                            Color.clear
                        ]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                
                // Back button and title
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            // Change from X to Cancel text
                            Text("Cancel")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.brown.opacity(0.7))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            
            // Cuisine title
            Text(cuisine.name)
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Divider()
                .padding(.horizontal)
            
            // Dishes list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cuisine.dishes, id: \.id) { dish in
                        DishRow(dish: dish)
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
    }
}

struct DishRow: View {
    let dish: Dish
    @EnvironmentObject private var dataController: DataController
    
    private var cartItem: CartItem? {
        dataController.getCart()?.cartItems.first { $0.dish.id == dish.id }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Dish image
            AsyncImage(url: URL(string: dish.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Dish info
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", dish.rating))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text("₹\(String(format: "%.2f", dish.price))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brown.opacity(0.8))
            }
            
            Spacer()
            
            // Add to cart controls
            if let cartItem = cartItem {
                HStack {
                    Button(action: {
                        dataController.removeDishFromCart(dish: dish)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.brown)
                            .imageScale(.large)
                    }
                    
                    Text("\(cartItem.quantity)")
                        .font(.headline)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        dataController.addDishToCart(dish: dish)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brown)
                            .imageScale(.large)
                    }
                }
            } else {
                Button(action: {
                    dataController.addDishToCart(dish: dish)
                }) {
                    Text("Add")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brown)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.brown.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
//    CuisineDetailView(cuisine: Cuisine.example)
//        .environmentObject(DataController.shared)
} 
