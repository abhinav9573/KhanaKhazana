//
//  CartView.swift
//  KhanaKhazana
//
//  Created by Harshit Gupta on 08/05/25.
//

import SwiftUI

struct CartView: View {
    @StateObject private var dataController = DataController.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showOrderPlaced = false
    @State private var showOrderError = false
    @State private var errorMessage = ""
    @State private var transactionId: String = ""
    @State private var isProcessingOrder = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let cart = dataController.getCart(), !cart.cartItems.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Cart Items List
                            ForEach(cart.cartItems, id: \.dish.id) { item in
                                CartItemRow(item: item)
                            }
                            
                            // Price Details
                            VStack(spacing: 12) {
                                PriceRow(title: "Net Amount", amount: cart.netAmount)
                                PriceRow(title: "CGST (2.5%)", amount: cart.cgst)
                                PriceRow(title: "SGST (2.5%)", amount: cart.sgst)
                                
                                Divider()
                                
                                PriceRow(title: "Grand Total", amount: cart.grandTotal, isTotal: true)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Place Order Button
                            Button(action: {
                                placeOrder()
                            }) {
                                if isProcessingOrder {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                } else {
                                    Text("Place Order")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(isProcessingOrder)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Your cart is empty")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Cart")
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
            }
            .alert("Order Placed", isPresented: $showOrderPlaced) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your order has been placed successfully!\nTransaction ID: \(transactionId)")
            }
            .alert("Order Failed", isPresented: $showOrderError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func placeOrder() {
        guard !isProcessingOrder else { return }
        
        print("Starting order placement process")
        isProcessingOrder = true
        
        if let cart = dataController.getCart() {
            print("Cart contains \(cart.cartItems.count) items with a total of \(cart.grandTotal)")
            
            for (index, item) in cart.cartItems.enumerated() {
                print("Item \(index+1): \(item.dish.name), Price: \(item.dish.price), Quantity: \(item.quantity)")
            }
        }
        
        Task {
            do {
                print("Calling makePayment...")
                let response = try await DataController.shared.makePayment()
                print("Payment successful with transaction reference: \(response.txnRefNo)")
                
                // Update on main thread
                await MainActor.run {
                    transactionId = response.txnRefNo
                    isProcessingOrder = false
                    showOrderPlaced = true
                    print("Order placed successfully")
                }
            } catch {
                print("Payment failed with error: \(error), \(error.localizedDescription)")
                
                // Update on main thread
                await MainActor.run {
                    // More specific error message
                    errorMessage = "Failed to place order: \(error.localizedDescription)"
                    isProcessingOrder = false
                    showOrderError = true
                    print("Order placement failed")
                }
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    @StateObject private var dataController = DataController.shared
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: item.dish.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.dish.name)
                    .font(.headline)
                
                Text("₹\(String(format: "%.2f", item.dish.price))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Button(action: {
                        dataController.removeDishFromCart(dish: item.dish)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(item.quantity)")
                        .font(.headline)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        dataController.addDishToCart(dish: item.dish)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            Text("₹\(String(format: "%.2f", item.dish.price * Double(item.quantity)))")
                .font(.headline)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct PriceRow: View {
    let title: String
    let amount: Double
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .title3 : .body)
                .fontWeight(isTotal ? .bold : .regular)
            
            Spacer()
            
            Text("₹\(String(format: "%.2f", amount))")
                .font(isTotal ? .title3 : .body)
                .fontWeight(isTotal ? .bold : .regular)
        }
    }
}

#Preview {
    CartView()
}
