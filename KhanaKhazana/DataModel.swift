//
//  DataModel.swift
//  KhanaKhazana
//
//  Created by Harshit Gupta on 07/05/25.
//

import Foundation

struct Dish: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var image: String
    var price: Double
    var rating: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case image = "image_url"
        case price
        case rating
    }

    init(id: String, name: String, image: String, price: Double, rating: Double) {
        self.id = id
        self.name = name
        self.image = image
        self.price = price
        self.rating = rating
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle different ID types (String or Int)
        if let stringId = try? container.decode(String.self, forKey: .id) {
            id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = UUID().uuidString
        }
        
        // Handle name with fallback
        if let decodedName = try? container.decode(String.self, forKey: .name) {
            name = decodedName
        } else {
            name = "Unknown Dish"
        }
        
        // Handle image with fallback
        if let decodedImage = try? container.decode(String.self, forKey: .image) {
            image = decodedImage
        } else {
            image = ""
        }
        
        // Handle price with multiple formats
        if let priceString = try? container.decode(String.self, forKey: .price) {
            price = Double(priceString) ?? 0
        } else if let priceDouble = try? container.decode(Double.self, forKey: .price) {
            price = priceDouble
        } else if let priceInt = try? container.decode(Int.self, forKey: .price) {
            price = Double(priceInt)
        } else {
            price = 0
        }
        
        // Handle rating with multiple formats
        if let ratingString = try? container.decode(String.self, forKey: .rating) {
            rating = Double(ratingString) ?? 0
        } else if let ratingDouble = try? container.decode(Double.self, forKey: .rating) {
            rating = ratingDouble
        } else if let ratingInt = try? container.decode(Int.self, forKey: .rating) {
            rating = Double(ratingInt)
        } else {
            rating = 0
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(image, forKey: .image)
        try container.encode(price, forKey: .price)
        try container.encode(rating, forKey: .rating)
    }
}



struct Cuisine: Codable {
    var id: String
    var name: String
    var image: String
    var dishes: [Dish] 

    enum CodingKeys: String, CodingKey {
        case id = "cuisine_id"
        case name = "cuisine_name"
        case image = "cuisine_image_url"
        case dishes = "items"
    }
}


struct CartItem: Codable, Hashable, Identifiable {
    var dish: Dish
    var quantity: Int
    
    var id: String {
        dish.id
    }
}

struct Cart: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var cartItems: [CartItem]
    var netAmount: Double {
        cartItems.reduce(0.0) { $0 + ($1.dish.price * Double($1.quantity)) }
    }
    
    private var taxRate: Double = 0.025
    var cgst: Double {
        netAmount * taxRate
    }
    var sgst: Double {
        netAmount * taxRate
    }
    var grandTotal: Double {
        netAmount + cgst + sgst
    }
    
    init(id: UUID, userId: UUID, cartItems: [CartItem]) {
        self.id = id
        self.userId = userId
        self.cartItems = cartItems
    }
    
    // Custom encode/decode to handle computed properties
    private enum CodingKeys: String, CodingKey {
        case id, userId, cartItems
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        cartItems = try container.decode([CartItem].self, forKey: .cartItems)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(cartItems, forKey: .cartItems)
    }
}

struct User: Codable {
    var id: UUID
    var name: String
}

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
        case page, count
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case cuisines
    }
}

enum Language {
    case english, hindi
}

struct DishDetailResponse: Decodable {
    let cuisineId: String
    let cuisineName: String
    let cuisineImageURL: String
    let dish: Dish

    enum CodingKeys: String, CodingKey {
        case cuisineId = "cuisine_id"
        case cuisineName = "cuisine_name"
        case cuisineImageURL = "cuisine_image_url"
        case itemId = "item_id"
        case itemName = "item_name"
        case itemPrice = "item_price"
        case itemRating = "item_rating"
        case itemImageURL = "item_image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        cuisineId = try container.decode(String.self, forKey: .cuisineId)
        cuisineName = try container.decode(String.self, forKey: .cuisineName)
        cuisineImageURL = try container.decode(String.self, forKey: .cuisineImageURL)

        let id = String(try container.decode(Int.self, forKey: .itemId))
        let name = try container.decode(String.self, forKey: .itemName)
        let image = try container.decode(String.self, forKey: .itemImageURL)
        let price = try container.decode(Double.self, forKey: .itemPrice)
        let rating = try container.decode(Double.self, forKey: .itemRating)

        dish = Dish(id: id, name: name, image: image, price: price, rating: rating)
        
    }
}

struct Transaction: Codable, Identifiable {
    var id: String
    var date: Date
    var items: [CartItem]
    var totalAmount: Double
    var transactionId: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



