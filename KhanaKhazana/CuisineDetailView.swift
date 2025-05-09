import SwiftUI

struct CuisineDetailView: View {
    let cuisine: Cuisine
    @StateObject private var dataController = DataController.shared
    @State var selectedLanguage: Language = .english
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
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
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(cuisine.dishes, id: \.id) { dish in
                            DishTile(dish: dish, selectedLanguage: $selectedLanguage)
                        }
                    }
                    .padding(.horizontal)
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
            }
        }
    }
} 
