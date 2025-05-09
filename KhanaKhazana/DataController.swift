//
//  DataController.swift
//  KhanaKhazana
//
//  Created by Harshit Gupta on 07/05/25.
//

import Foundation

// MARK: - Payment Models
struct PaymentResponse: Codable {
    let responseCode: Int
    let outcomeCode: Int
    let responseMessage: String
    let txnRefNo: String
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case outcomeCode = "outcome_code"
        case responseMessage = "response_message"
        case txnRefNo = "txn_ref_no"
    }
}

struct PaymentItem: Codable {
    let cuisineId: Int
    let itemId: Int
    let itemPrice: Int
    let itemQuantity: Int

    enum CodingKeys: String, CodingKey {
        case cuisineId = "cuisine_id"
        case itemId = "item_id"
        case itemPrice = "item_price"
        case itemQuantity = "item_quantity"
    }
}




struct PaymentRequest: Codable {
    let totalAmount: String
    let totalItems: Int
    let data: [PaymentItem]
    
    enum CodingKeys: String, CodingKey {
        case totalAmount = "total_amount"
        case totalItems = "total_items"
        case data
    }
}

class DataController: ObservableObject {
    static let shared = DataController()
    
    private var cuisines: [Cuisine] = []
    
    private var dish: Dish?
    
    private var user: User?
    
    @Published private(set) var cart: Cart? = nil {
        didSet {
            // Save to UserDefaults whenever cart changes
            saveCartToUserDefaults()
        }
    }
    @Published private(set) var transactions: [Transaction] = [] {
        didSet {
            // Save to UserDefaults whenever transactions change
            saveTransactionsToUserDefaults()
        }
    }
    
    @Published var isAPIWorking: Bool = false
    @Published var searchText: String = ""
    
    private let cartKey = "com.khanakhazana.cart"
    private let transactionsKey = "com.khanakhazana.transactions"
    
    private init() {
        print("DataController initialization - Loading saved data")
        loadFromUserDefaults()
        
        // Print loaded cart for debugging
        if let cart = self.cart {
            print("Loaded cart with \(cart.cartItems.count) items")
            for (index, item) in cart.cartItems.enumerated() {
                print("  Item \(index + 1): \(item.dish.name), Quantity: \(item.quantity)")
            }
        } else {
            print("No saved cart found")
        }
        
        Task {
            do {
                try await loadCuisines(count: 10)
            } catch {
                print("Error initializing cuisines: \(error)")
            }
        }
    }
    
    // MARK: - UserDefaults Functions
    private func loadFromUserDefaults() {
        print("Loading data from UserDefaults")
        
        // Load cart
        if let cartData = UserDefaults.standard.data(forKey: cartKey) {
            do {
                let savedCart = try JSONDecoder().decode(Cart.self, from: cartData)
                self.cart = savedCart
                print("Successfully loaded cart with \(savedCart.cartItems.count) items")
            } catch {
                print("Error decoding cart from UserDefaults: \(error)")
                UserDefaults.standard.removeObject(forKey: cartKey)
            }
        }
        
        // Load transactions
        if let transactionsData = UserDefaults.standard.data(forKey: transactionsKey) {
            do {
                let savedTransactions = try JSONDecoder().decode([Transaction].self, from: transactionsData)
                self.transactions = savedTransactions
                print("Successfully loaded \(savedTransactions.count) transactions")
            } catch {
                print("Error decoding transactions from UserDefaults: \(error)")
                UserDefaults.standard.removeObject(forKey: transactionsKey)
            }
        }
    }
    
    private func saveCartToUserDefaults() {
        print("Saving cart to UserDefaults")
        
        if let cart = cart {
            do {
                let cartData = try JSONEncoder().encode(cart)
                UserDefaults.standard.set(cartData, forKey: cartKey)
                UserDefaults.standard.synchronize()
                print("Successfully saved cart with \(cart.cartItems.count) items")
            } catch {
                print("Error encoding cart for UserDefaults: \(error)")
            }
        } else {
            print("Removing cart from UserDefaults")
            UserDefaults.standard.removeObject(forKey: cartKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func saveTransactionsToUserDefaults() {
        print("Saving transactions to UserDefaults")
        
        do {
            let transactionsData = try JSONEncoder().encode(transactions)
            UserDefaults.standard.set(transactionsData, forKey: transactionsKey)
            UserDefaults.standard.synchronize()
            print("Successfully saved \(transactions.count) transactions")
        } catch {
            print("Error encoding transactions for UserDefaults: \(error)")
        }
    }
    
    // Public method to force data save (can be called at app termination)
    func saveAllData() {
        print("Manually triggering data save")
        saveCartToUserDefaults()
        saveTransactionsToUserDefaults()
    }
    
    // MARK: - API Response Models
    struct ItemListResponse: Codable {
        let responseCode: Int
        let outcomeCode: Int
        let responseMessage: String
        let page: Int
        let count: Int
        let totalPages: Int
        let totalItems: Int
        let cuisines: [Cuisine]
        
        enum CodingKeys: String, CodingKey {
            case responseCode = "response_code"
            case outcomeCode = "outcome_code"
            case responseMessage = "response_message"
            case page
            case count
            case totalPages = "total_pages"
            case totalItems = "total_items"
            case cuisines
        }
    }

    // MARK: - Fetching Functions
    func fetchCuisines(page: Int = 1, count: Int = 10) async throws -> (cuisines: [Cuisine]?, totalPages: Int)? {
        guard let url = URL(string: "https://uat.onebanc.ai/emulator/interview/get_item_list") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("uonebancservceemultrS3cg8RaL30", forHTTPHeaderField: "X-Partner-API-Key")
        request.addValue("get_item_list", forHTTPHeaderField: "X-Forward-Proxy-Action")

        let requestBody = [
            "page": page,
            "count": count
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(ItemListResponse.self, from: data)
        return (decodedResponse.cuisines, decodedResponse.totalPages)
    }
    
    func fetchAllCuisines(count: Int = 10) async throws -> [Cuisine] {
        var allCuisines: [Cuisine] = []
        
        // Get first page to determine total pages
        guard let (firstPageCuisines, totalPages) = try await fetchCuisines(page: 1, count: count) else {
            throw URLError(.badServerResponse)
        }
        
        allCuisines.append(contentsOf: firstPageCuisines!)
        
        // Fetch remaining pages if any
        if totalPages > 1 {
            for page in 2...totalPages {
                if let (pageCuisines, _) = try await fetchCuisines(page: page, count: count) {
                    allCuisines.append(contentsOf: pageCuisines!)
                }
            }
        }
        
        return allCuisines
    }
    
    func fetchDishById(itemId: Int) async throws -> Dish? {
        guard let url = URL(string: "https://uat.onebanc.ai/emulator/interview/get_item_by_id") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("uonebancservceemultrS3cg8RaL30", forHTTPHeaderField: "X-Partner-API-Key")
        request.addValue("get_item_by_id", forHTTPHeaderField: "X-Forward-Proxy-Action")

        let body: [String: Any] = ["item_id": itemId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let dishResponse = try JSONDecoder().decode(DishDetailResponse.self, from: data)
        return dishResponse.dish
    }

    

    // MARK: - Cuisine Functions
    func loadCuisines(count: Int = 10) async throws {
        isAPIWorking = false
        do {
            cuisines = try await fetchAllCuisines(count: count)
            isAPIWorking = true
        } catch {
            print("Error loading cuisines: \(error)")
            throw error
        }
    }
    
    func getCuisines() -> [Cuisine] {
        return cuisines
    }
    
    //MARK: - Dish Functions
    func getDish() -> Dish? {
        return dish
    }
    
    func getDish(by id: Int) async throws -> Dish? {
        return try await fetchDishById(itemId: id)
    }
    
    func getTopDishes() -> [Dish] {
        var dishes: [Dish] = []
        for cuisine in cuisines {
            for dish in cuisine.dishes {
                dishes.append(dish)
            }
        }
        dishes = dishes.sorted { $0.rating > $1.rating }
        var topDishes: [Dish] = []
        for i in 0..<min(dishes.count, 3) {
            topDishes.append(dishes[i])
        }
        return topDishes
    }

    //MARK: - Cart Functions
    func getCart() -> Cart? {
        return cart
    }
    
    func addDishToCart(dish: Dish) {
        print("Adding dish to cart: \(dish.name), ID: \(dish.id), Price: \(dish.price)")
        
        // Ensure this happens on the main thread for UI consistency
        DispatchQueue.main.async {
            // Create a new CartItem directly ensuring we have valid data
            let newItem = CartItem(
                dish: Dish(
                    id: dish.id,
                    name: dish.name.isEmpty ? "Unknown Dish" : dish.name,
                    image: dish.image,
                    price: max(0.01, dish.price),
                    rating: dish.rating
                ),
                quantity: 1
            )
            
            if var currentCart = self.cart {
                // Check if dish already exists in cart
                if let existingIndex = currentCart.cartItems.firstIndex(where: { $0.dish.id == dish.id }) {
                    // Dish already exists, increase quantity
                    currentCart.cartItems[existingIndex].quantity += 1
                    print("Increased quantity for \(dish.name) to \(currentCart.cartItems[existingIndex].quantity)")
                } else {
                    // Add new dish to cart
                    currentCart.cartItems.append(newItem)
                    print("Added new dish \(dish.name) to cart")
                }
                self.cart = currentCart
            } else {
                // Create new cart
                self.cart = Cart(
                    id: UUID(),
                    userId: UUID(),
                    cartItems: [newItem]
                )
                print("Created new cart with dish \(dish.name)")
            }
            
            // Notify observers
            self.objectWillChange.send()
            // Cart saving is now handled by the didSet observer
        }
    }
    
    func removeDishFromCart(dish: Dish) {
        guard var currentCart = self.cart else { return }
        
        if let index = currentCart.cartItems.firstIndex(where: { $0.dish.id == dish.id }) {
            if currentCart.cartItems[index].quantity > 1 {
                currentCart.cartItems[index].quantity -= 1
            } else {
                currentCart.cartItems.remove(at: index)
            }
            self.cart = currentCart
            // Cart saving is now handled by the didSet observer
        }
    }
    
    func orderDishesFromCart() {
        cart = nil
        // Cart saving is now handled by the didSet observer
    }
    
    func getCurrentUser() -> User? {
        return user
    }
    
    func fetchDishes(of cuisine: Cuisine) -> [Dish] {
        cuisine.dishes
    }
    
    // MARK: - Transaction Functions
    func getTransactions() -> [Transaction] {
        return transactions
    }
    
    func addTransaction(transactionId: String, items: [CartItem], totalAmount: Double) {
        let newTransaction = Transaction(
            id: UUID().uuidString,
            date: Date(),
            items: items,
            totalAmount: totalAmount,
            transactionId: transactionId
        )
        transactions.append(newTransaction)
        // Transaction saving is now handled by the didSet observer
    }
    
    // MARK: - Search Functions
    var filteredDishes: [Dish] {
        guard !searchText.isEmpty else { return [] }
        
        var allDishes: [Dish] = []
        for cuisine in cuisines {
            allDishes.append(contentsOf: cuisine.dishes)
        }
        
        return allDishes.filter { dish in
            dish.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    // MARK: - Payment Functions
    func makePayment() async throws -> PaymentResponse {
        print("Starting payment process...")
        
        guard let cart = self.cart, !cart.cartItems.isEmpty else {
            print("Error: No cart found or cart is empty")
            throw URLError(.badURL)
        }
        
        print("Cart found with \(cart.cartItems.count) items")
        
        guard let url = URL(string: "https://uat.onebanc.ai/emulator/interview/make_payment") else {
            print("Error: Invalid URL")
            throw URLError(.badURL)
        }
        
        print("Creating request...")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("uonebancservceemultrS3cg8RaL30", forHTTPHeaderField: "X-Partner-API-Key")
        request.addValue("make_payment", forHTTPHeaderField: "X-Forward-Proxy-Action")
        
        // Create plain Dictionary representation for better API compatibility
        let requestDict: [String: Any] = [
            "total_amount": String(format: "%.2f", cart.grandTotal),
            "total_items": cart.cartItems.reduce(0) { $0 + $1.quantity },
            "data": cart.cartItems.map { item in
                [
                    "cuisine_id": Int(item.dish.id) ?? 1,
                    "item_id": Int(item.dish.id) ?? 1,
                    "item_price": Int(item.dish.price),
                    "item_quantity": item.quantity
                ]
            }
        ]
        
        print("Payment request: \(requestDict)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestDict)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Request body: \(jsonString)")
            }
        } catch {
            print("Error encoding request body: \(error)")
            throw error
        }
        
        print("Sending request to server...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Received response from server")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid HTTP response")
                throw URLError(.badServerResponse)
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let paymentResponse = try JSONDecoder().decode(PaymentResponse.self, from: data)
                    print("Payment successful with transaction reference: \(paymentResponse.txnRefNo)")
                    
                    // Add transaction to history before clearing cart
                    addTransaction(
                        transactionId: paymentResponse.txnRefNo,
                        items: cart.cartItems,
                        totalAmount: cart.grandTotal
                    )
                    
                    self.cart = nil
                    return paymentResponse
                } catch {
                    print("Error decoding response: \(error)")
                    throw error
                }
            case 400:
                print("Error: Bad request - Invalid request format")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Server error details: \(responseString)")
                }
                throw URLError(.badURL)
            case 404:
                print("Error: Resource not found")
                throw URLError(.resourceUnavailable)
            case 500:
                print("Error: Server error")
                throw URLError(.badServerResponse)
            default:
                print("Error: Unknown status code \(httpResponse.statusCode)")
                throw URLError(.unknown)
            }
        } catch {
            print("Network error: \(error)")
            throw error
        }
    }

}
