import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataController: DataController
    @State var selectedLanguage: Language = .english
    @State private var selectedCuisine: Cuisine?
    @State private var showCuisineDetail = false
    @State private var showCart = false
    @State private var scrollTarget: Int = 0
    @State private var currentIndex: Int = 0
    @State private var selectedSegment = 0
    
    var originalCuisines: [Cuisine] {
        // Create a dictionary where the key is the cuisine ID to filter out duplicates
        let uniqueCuisines = Dictionary(grouping: dataController.getCuisines(), by: { $0.id })
            .compactMapValues { $0.first }
            .values
            .sorted(by: { $0.name < $1.name })
        return Array(uniqueCuisines)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Segment Picker
                Picker("View", selection: $selectedSegment) {
                    Text("Menu").tag(0)
                    Text("Search").tag(1)
                    Text("History").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if selectedSegment == 0 {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Segment 1: Cuisine Categories
                            cuisineCategoriesView
                            
                            // Segment 2: Top Dishes
                            topDishesView
                        }
                        .padding()
                    }
                } else if selectedSegment == 1 {
                    SearchView()
                } else {
                    TransactionHistoryView()
                }
            }
            .navigationTitle(selectedLanguage == .english ? "Khana Khazana" : "खाना खज़ाना")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    languageButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    cartButton
                }
            }
            .sheet(isPresented: $showCuisineDetail, onDismiss: {
                selectedCuisine = nil
            }) {
                if let cuisine = selectedCuisine {
                    CuisineDetailView(cuisine: cuisine)
                }
            }
            .sheet(isPresented: $showCart) {
                CartView()
            }
            .onAppear {
                if selectedCuisine == nil && !originalCuisines.isEmpty {
                    selectedCuisine = originalCuisines.first
                }
            }
        }
    }
    
    private var cuisineCategoriesView: some View {
        let cuisines = originalCuisines

        return VStack(alignment: .leading) {
            Text(selectedLanguage == .english ? "Cuisine Categories" : "खाने की श्रेणियां")
                .font(.title2)
                .fontWeight(.bold)

            ScrollViewReader { proxy in
                VStack {
                    HStack(spacing: 1) {
                        Button("", systemImage: "chevron.left") {
                            guard currentIndex > 0 else { return }
                            currentIndex = (currentIndex - 1 + cuisines.count) % cuisines.count
                            withAnimation {
                                proxy.scrollTo(currentIndex, anchor: .center)
                            }
                        }
                        .foregroundColor(.brown.opacity(0.7))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(cuisines.indices, id: \.self) { i in
                                    let cuisine = cuisines[i]
                                    CuisineCard(cuisine: cuisine, selectedLanguage: $selectedLanguage)
                                        .onTapGesture {
                                            selectedCuisine = cuisine
                                            // Add a slight delay to ensure the selection is properly registered
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                showCuisineDetail = true
                                            }
                                        }
                                        .id(i)
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                        Button("", systemImage: "chevron.right") {
                            guard currentIndex < cuisines.count - 1 else { return }
                            currentIndex = (currentIndex + 1) % cuisines.count
                            withAnimation {
                                proxy.scrollTo(currentIndex, anchor: .center)
                            }
                        }
                        .foregroundColor(.brown.opacity(0.7))
                    }

                    HStack(spacing: 30) {
                        

                        
                    }
                    .padding(.top, 10)
                }
                .onAppear {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }

    }

    
    
    
    
    private var topDishesView: some View {
        VStack(alignment: .leading) {
            Text(selectedLanguage == .english ? "Popular Dishes" : "लोकप्रिय व्यंजन")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(dataController.getTopDishes(), id: \.id) { dish in
                    DishTile(dish: dish, selectedLanguage: $selectedLanguage)
                }
            }
        }
    }
    
    private var languageButton: some View {
        Button(action: {
            selectedLanguage = selectedLanguage == .english ? .hindi : .english
        }) {
            Text(selectedLanguage == .english ? "अ" : "A")
                .padding(.horizontal, 12)
                .padding(.vertical, selectedLanguage == .english ? 8 : 7)
                .background(Color.brown.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(.infinity)
        }
    }
    
    private var cartButton: some View {
        Button(action: {
            showCart = true
        }) {
            Image(systemName: "cart")
                .font(.title2)
                .foregroundStyle(Color.brown.opacity(0.7))
        }
    }
    struct ScrollOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }


}

struct CuisineCard: View {
    let cuisine: Cuisine
    @Binding var selectedLanguage: Language
    var body: some View {
        VStack {
            ZStack {
                AsyncImage(url: URL(string: cuisine.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 308, height: 176)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                let color = Color.black
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0),
                        color.opacity(0.1),
                        color.opacity(0.1),
                        color.opacity(0.1),
                        color.opacity(0.3),
                        color.opacity(0.5),
                        color.opacity(0.8),
                        color.opacity(0.8),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack {
                    Spacer()
                    HStack {
                        Text(cuisine.name)
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .padding(10)
                        Spacer()
                        Text("\(cuisine.dishes.count) \(selectedLanguage == .english ? "dishes" : "खाने")")
                            .font(.caption)
                            .foregroundStyle(Color.white)
                            .padding(10)
                            .padding(.top, 10)
                    }
                }
            }
            
            
        }
        .frame(width: 308)
        .cornerRadius(12)
    }
}

struct DishTile: View {
    let dish: Dish
    @EnvironmentObject private var dataController: DataController
    @Binding var selectedLanguage: Language
    @State private var isAddingToCart = false
    @State private var imageLoaded = true // Set to true by default
    
    private var cartItem: CartItem? {
        dataController.getCart()?.cartItems.first { $0.dish.id == dish.id }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                AsyncImage(url: URL(string: dish.image)) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.frame(width: 160, height: 120)
                            .onAppear {
                                imageLoaded = true // Set to true even before loading
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 120)
                            .clipped()
                            .onAppear {
                                imageLoaded = true
                            }
                    case .failure:
                        Color.gray.frame(width: 160, height: 120)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                            .onAppear {
                                imageLoaded = true
                            }
                    @unknown default:
                        Color.gray.frame(width: 160, height: 120)
                            .onAppear {
                                imageLoaded = true
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                let color = Color.black
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0),
                        color.opacity(0.1),
                        color.opacity(0.1),
                        color.opacity(0.1),
                        color.opacity(0.3),
                        color.opacity(0.6),
                        color.opacity(0.8),
                        color.opacity(1),
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack {
                    HStack {
                        Text(dish.name)
                            .foregroundStyle(.white)
                            .font(.headline)
                            .lineLimit(1)
                            .padding(10)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .allowsHitTesting(false)
            
            HStack {
                Text("₹\(String(format: "%.2f", dish.price))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", dish.rating))
                }
                .font(.caption)
            }
            
            if let cartItem = cartItem {
                HStack {
                    Button(action: {
                        // Remove from cart
                        withAnimation {
                            dataController.removeDishFromCart(dish: dish)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.brown.opacity(0.7))
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("\(cartItem.quantity)")
                        .font(.headline)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        // Add to cart directly
                        withAnimation {
                            directAddToCart()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brown.opacity(0.7))
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.brown.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: {
                    print("Add to Cart button tapped for \(dish.name)")
                    withAnimation {
                        directAddToCart()
                    }
                }) {
                    ZStack {
                        if isAddingToCart {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.brown.opacity(0.7))
                                .cornerRadius(8)
                        } else {
                            Text(selectedLanguage == .english ? "Add to Cart" : "कार्ट में जोड़ें")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.brown.opacity(0.7))
                                .cornerRadius(8)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isAddingToCart)
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
    
    private func directAddToCart() {
        print("Adding \(dish.name) to cart, imageLoaded: \(imageLoaded)")
        isAddingToCart = true
        
        // Create a direct copy of the dish to avoid reference issues
        let dishCopy = Dish(
            id: dish.id,
            name: dish.name,
            image: dish.image,
            price: dish.price,
            rating: dish.rating
        )
        
        // Add directly without any conditions
        dataController.addDishToCart(dish: dishCopy)
        
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAddingToCart = false
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var dataController: DataController
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search dishes...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        dataController.searchText = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        dataController.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            // Results
            if searchText.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("Search for your favorite dishes")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dataController.filteredDishes.isEmpty {
                VStack {
                    Image(systemName: "exclamationmark.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No dishes found matching '\(searchText)'")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(dataController.filteredDishes, id: \.id) { dish in
                            SearchResultTile(dish: dish)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SearchResultTile: View {
    let dish: Dish
    @EnvironmentObject private var dataController: DataController
    @State private var isAddingToCart = false
    @State private var imageLoaded = true // Set to true by default
    
    private var cartItem: CartItem? {
        dataController.getCart()?.cartItems.first { $0.dish.id == dish.id }
    }
    
    var body: some View {
        DishTile(dish: dish, selectedLanguage: .constant(.english))
//        VStack(alignment: .leading) {
//            ZStack {
//                AsyncImage(url: URL(string: dish.image)) { phase in
//                    switch phase {
//                    case .empty:
//                        Color.gray.frame(width: 160, height: 120)
//                            .onAppear {
//                                imageLoaded = true // Set to true even before loading
//                            }
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: 160, height: 120)
//                            .clipped()
//                            .onAppear {
//                                imageLoaded = true
//                            }
//                    case .failure:
//                        Color.gray.frame(width: 160, height: 120)
//                            .overlay(
//                                Image(systemName: "photo")
//                                    .foregroundColor(.white)
//                            )
//                            .onAppear {
//                                imageLoaded = true
//                            }
//                    @unknown default:
//                        Color.gray.frame(width: 160, height: 120)
//                            .onAppear {
//                                imageLoaded = true
//                            }
//                    }
//                }
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//                
//                VStack {
//                    Spacer()
//                    HStack {
//                        Text(dish.name)
//                            .font(.caption)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                            .lineLimit(1)
//                            .padding(4)
//                        Spacer()
//                    }
//                    .background(Color.black.opacity(0.7))
//                }
//            }
//            .allowsHitTesting(false)
//            
//            HStack {
//                Text("₹\(String(format: "%.2f", dish.price))")
//                    .font(.subheadline)
//                    .fontWeight(.semibold)
//                
//                Spacer()
//                
//                HStack {
//                    Image(systemName: "star.fill")
//                        .foregroundColor(.yellow)
//                    Text(String(format: "%.1f", dish.rating))
//                }
//                .font(.caption)
//            }
//            
//            if let cartItem = cartItem {
//                HStack {
//                    Button(action: {
//                        withAnimation {
//                            dataController.removeDishFromCart(dish: dish)
//                        }
//                    }) {
//                        Image(systemName: "minus.circle.fill")
//                            .foregroundColor(.brown)
//                            .imageScale(.large)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    
//                    Text("\(cartItem.quantity)")
//                        .font(.headline)
//                        .frame(minWidth: 30)
//                    
//                    Button(action: {
//                        withAnimation {
//                            directAddToCart()
//                        }
//                    }) {
//                        Image(systemName: "plus.circle.fill")
//                            .foregroundColor(.brown)
//                            .imageScale(.large)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 8)
//                .background(Color.brown.opacity(0.1))
//                .cornerRadius(8)
//            } else {
//                Button(action: {
//                    print("Add to Cart button tapped for search dish \(dish.name)")
//                    withAnimation {
//                        directAddToCart()
//                    }
//                }) {
//                    ZStack {
//                        if isAddingToCart {
//                            ProgressView()
//                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 8)
//                                .background(Color.brown)
//                                .cornerRadius(8)
//                        } else {
//                            Text("Add to Cart")
//                                .font(.caption)
//                                .fontWeight(.semibold)
//                                .foregroundColor(.white)
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 8)
//                                .background(Color.brown)
//                                .cornerRadius(8)
//                        }
//                    }
//                }
//                .buttonStyle(PlainButtonStyle())
//                .disabled(isAddingToCart)
//            }
//        }
//        .padding(8)
//        .background(Color.white)
//        .cornerRadius(12)
//        .shadow(radius: 3)
    }
    
    private func directAddToCart() {
        print("Adding search dish \(dish.name) to cart, imageLoaded: \(imageLoaded)")
        isAddingToCart = true
        
        // Create a direct copy of the dish to avoid reference issues
        let dishCopy = Dish(
            id: dish.id,
            name: dish.name,
            image: dish.image,
            price: dish.price,
            rating: dish.rating
        )
        
        // Add directly without any conditions
        dataController.addDishToCart(dish: dishCopy)
        
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAddingToCart = false
        }
    }
}

struct TransactionHistoryView: View {
    @EnvironmentObject private var dataController: DataController
    
    var body: some View {
        Group {
            if dataController.getTransactions().isEmpty {
                VStack {
                    Image(systemName: "bag")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No transaction history yet")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(dataController.getTransactions()) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .navigationTitle("Transaction History")
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(transaction.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("ID: \(transaction.transactionId)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("₹\(String(format: "%.2f", transaction.totalAmount))")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(transaction.items.count) item(s)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
            }
            
            if isExpanded {
                Divider()
                
                ForEach(transaction.items, id: \.dish.id) { item in
                    HStack {
                        Text(item.dish.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(item.quantity) × ₹\(String(format: "%.2f", item.dish.price))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 1)
        .padding(.horizontal)
        .padding(.vertical, 5)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}

#Preview {
    HomeView()
}
