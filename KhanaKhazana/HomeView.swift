import SwiftUI

struct HomeView: View {
    @StateObject private var dataController = DataController.shared
    @State var selectedLanguage: Language = .english
    @State private var selectedCuisine: Cuisine?
    @State private var showCuisineDetail = false
    @State private var showCart = false
    @State private var scrollTarget: Int = 0
    @State private var currentIndex: Int = 0
    
    var originalCuisines: [Cuisine] {
        dataController.getCuisines()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Segment 1: Cuisine Categories
                    cuisineCategoriesView
                    
                    // Segment 2: Top Dishes
                    topDishesView
                }
                .padding()
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
                        .foregroundColor(.green.opacity(0.7))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(cuisines.indices, id: \.self) { i in
                                    let cuisine = cuisines[i]
                                    CuisineCard(cuisine: cuisine, selectedLanguage: $selectedLanguage)
                                        .onTapGesture {
                                            selectedCuisine = cuisine
                                            DispatchQueue.main.async {
                                                showCuisineDetail = true
                                            }
                                        }
                                        .id(i)
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                        Button("", systemImage: "chevron.right") {
                            guard currentIndex > 0 else { return }
                            currentIndex = (currentIndex + 1) % cuisines.count
                            withAnimation {
                                proxy.scrollTo(currentIndex, anchor: .center)
                            }
                        }
                        .foregroundColor(.green.opacity(0.7))
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
                .background(Color.green.opacity(0.7))
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
                .foregroundStyle(Color.green.opacity(0.7))
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
    @StateObject private var dataController = DataController.shared
    @Binding var selectedLanguage: Language
    
    private var cartItem: CartItem? {
        dataController.getCart()?.cartItems.first { $0.dish.id == dish.id }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                AsyncImage(url: URL(string: dish.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 120)
                        .clipped()
                } placeholder: {
                    Color.gray
                        .frame(width: 160, height: 120)
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
                        withAnimation {
                            dataController.removeDishFromCart(dish: dish)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.green.opacity(0.7))
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("\(cartItem.quantity)")
                        .font(.headline)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        withAnimation {
                            dataController.addDishToCart(dish: dish)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green.opacity(0.7))
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: {
                    withAnimation {
                        dataController.addDishToCart(dish: dish)
                    }
                }) {
                    Text(selectedLanguage == .english ? "Add to Cart" : "कार्ट में जोड़ें")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

#Preview {
    HomeView()
}
