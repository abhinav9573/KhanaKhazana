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
    
    @Published private(set) var cart: Cart? = nil
    
    @Published var isAPIWorking: Bool = false
    
    private init() {
        Task {
            do {
                try await loadCuisines(count: 10)
            } catch {
                print("Error initializing cuisines: \(error)")
            }
        }
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
        if var currentCart = self.cart {
            if let index = currentCart.cartItems.firstIndex(where: { $0.dish.id == dish.id }) {
                currentCart.cartItems[index].quantity += 1
                self.cart = currentCart
            } else {
                currentCart.cartItems.append(CartItem(dish: dish, quantity: 1))
                self.cart = currentCart
            }
        } else {
            // Create new cart with first item
            let newCart = Cart(
                id: UUID(),
                userId: user?.id ?? UUID(),
                cartItems: [CartItem(dish: dish, quantity: 1)]
            )
            self.cart = newCart
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
        }
    }
    
    func orderDishesFromCart() {
        cart = nil
    }
    
    func getCurrentUser() -> User? {
        return user
    }
    
    func fetchDishes(of cuisine: Cuisine) -> [Dish] {
        cuisine.dishes
    }
    
    // MARK: - Payment Functions
    func makePayment() async throws -> PaymentResponse {
        print("Starting payment process...")
        
        guard let cart = self.cart else {
            print("Error: No cart found")
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
        
        // Create payment items from cart items using rupee values as Double
        let paymentItems = cart.cartItems.map { item in
            PaymentItem(
                cuisineId: Int(item.dish.id) ?? 0,
                itemId: Int(item.dish.id) ?? 0,
                itemPrice: Int(item.dish.price),
                itemQuantity: item.quantity
            )
        }

        // Total amount = sum of (price × quantity)
        let totalAmount = cart.cartItems.reduce(into: 0.0) {
            $0 += ($1.dish.price * Double($1.quantity))
        }

        print("Preparing payment request with total amount: \(totalAmount)")
        
        let paymentRequest = PaymentRequest(
            totalAmount: String(Int(totalAmount) + Int(0.05 * Double(totalAmount))),
            totalItems: paymentItems.reduce(0) { $0 + $1.itemQuantity },
            data: paymentItems
        )
        
        do {
            let jsonData = try JSONEncoder().encode(paymentRequest)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Request body: \(jsonString)")
            }
            request.httpBody = jsonData
            print("Request body encoded successfully")
        } catch {
            print("Error encoding request body: \(error)")
            throw error
        }
        
        print("Sending request to server...")
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
    }

}
