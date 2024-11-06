//import UIKit
//struct User{
//    let id: UUID
//        var name: String
//        var dietaryRestrictions: [DietaryRestriction]
//        var allergies: [Allergen]
//    var recentlyViewedProducts : [Product]
//    
//}
//
//struct Product {
//    let id: UUID
//    let name: String
//    let imageURL: URL
//    let healthScore: Int
//    var ingredients: [Ingredient]
//    var allergens: [Allergen]
//    var nutritionInfo: NutritionInfo
//    var userRating: Float
//    var numberOfRatings: Int
//    let category: Category
//    let pros: [String]
//    let cons: [String]
//}
//
//struct SavedList{
//    let id: UUID
//    let name: String
//    var products: [Product]
//    let iconName: String
//    
//    }
//struct Category {
//    let id: UUID
//    let name: String
//    let imageName: String
//    
//}
//let Categories: [Category] = [
//    Category(id: UUID(), name: "Bread", imageName: "bread"),
//    Category(id: UUID(), name: "Nut Butter", imageName: "nutbutter"),
//    Category(id: UUID(), name: "Oil", imageName: "oil"),
//    Category(id: UUID(), name: "Snacks", imageName: "snacks"),
//    Category(id: UUID(), name: "Dairy", imageName: "dairy")
//]
//struct NutritionInfo {
//    let calories: Int
//    let fats: Double
//    let sugars: Double
//    let protein: Double
//    let sodium: Double
//    let carbohydrates: Double
//    let vitamins: [Vitamin]
//    let minerals: [Mineral]
//}
//struct Vitamin {
//    let name: String
//    let dailyValue: Double
//}
//struct Mineral {
//    let name: String
//    let dailyValue: Double
//}
//
//struct Ingredient {
//    let id: UUID
//    let name: String
//    let riskLevel: RiskLevel
//    let nutritionalInfo: String
//    let potentialConcerns: String
//}
//
//enum RiskLevel: String {
//    case low = "Low Risk"
//    case high = "High Risk"
//    case riskFree = "Risk Free"
//}
//enum Allergen: String{
//    case milk = "Milk"
//    case peanuts = "Peanuts"
//    case treeNuts = "Tree Nuts"
//    case eggs = "Eggs"
//    case soy = "Soy"
//    case wheat = "Wheat"
//    case fish = "Fish"
//    case shellfish = "Shellfish"
//    case sesame = "Sesame"
//}
//
//enum DietaryRestriction: String{
//    case glutenFree = "Gluten-Free"
//    case dairyFree = "Dairy-Free"
//    case nutFree = "Nut-Free"
//    case vegan = "Vegan"
//    case vegetarian = "Vegetarian"
//    case lowSugar = "Low Sugar"
//    case keto = "Keto"
//}
//let Ingredients: [String: Ingredient] = [
//    "Whole Wheat Flour": Ingredient(
//        id: UUID(),
//        name: "Whole Wheat Flour",
//        riskLevel: .low,
//        nutritionalInfo: "Source of fiber and carbohydrates",
//        potentialConcerns: "Contains gluten"
//    ),
//    "Yeast": Ingredient(
//        id: UUID(),
//        name: "Yeast",
//        riskLevel: .riskFree,
//        nutritionalInfo: "Helps with bread fermentation",
//        potentialConcerns: "None"
//    ),
//    "Salt": Ingredient(
//        id: UUID(),
//        name: "Salt",
//        riskLevel: .low,
//        nutritionalInfo: "Essential mineral, but excessive intake can raise blood pressure",
//        potentialConcerns: "Sodium content"
//    ),
//    "Sugar": Ingredient(
//        id: UUID(),
//        name: "Sugar",
//        riskLevel: .high,
//        nutritionalInfo: "Sweetener",
//        potentialConcerns: "May contribute to high blood sugar"
//    ),
//    "Soybean Oil": Ingredient(
//        id: UUID(),
//        name: "Soybean Oil",
//        riskLevel: .high,
//        nutritionalInfo: "Contains fats, adds flavor",
//        potentialConcerns: "Common allergen for some people"
//    )
//]
//// MARK: - Sample Data
//let sampleProducts: [Product] = [
//    Product(
//        id: UUID(),
//        name: "Organic Whole Wheat Bread",
//        imageURL: URL(string: "https://via.placeholder.com/300x200")!,
//        healthScore: 80,
//        ingredients: [Ingredients["Whole Wheat Flour"]!, Ingredients["Yeast"]!, Ingredients["Salt"]!],
//        allergens: [.wheat],
//        nutritionInfo: NutritionInfo(
//            calories: 150,
//            fats: 2.5,
//            sugars: 3,
//            protein: 5,
//            sodium: 230,
//            carbohydrates: 27,
//            vitamins: [
//                Vitamin(name: "Vitamin B6", dailyValue: 6.0),
//                Vitamin(name: "Thiamin", dailyValue: 8.0)
//            ],
//            minerals: [
//                Mineral(name: "Iron", dailyValue: 8.0),
//                Mineral(name: "Magnesium", dailyValue: 6.0)
//            ]
//        ),
//        userRating: 4.2,
//        numberOfRatings: 45,
//        category: Categories[0],
//        pros: [
//             "High in plant-based protein",
//             "Contains essential vitamins and minerals",
//             "Made with organic, minimally processed ingredients"
//         ],
//         cons: [
//             "Contains tree nuts (almonds), which are a common allergen",
//             "Relatively high in natural sugars from dates"
//         ]// Bread
//    ),
//    Product(
//        id: UUID(),
//        name: "Organic Crunchy Peanut Butter",
//        imageURL: URL(string: "https://via.placeholder.com/300x200")!,
//        healthScore: 75,
//        ingredients: [Ingredients["Sugar"]!, Ingredients["Salt"]!, Ingredients["Peanuts"]!],
//        allergens: [.peanuts],
//        nutritionInfo: NutritionInfo(
//            calories: 190,
//            fats: 16,
//            sugars: 3,
//            protein: 7,
//            sodium: 150,
//            carbohydrates: 6,
//            vitamins: [
//                Vitamin(name: "Vitamin E", dailyValue: 10.0)
//            ],
//            minerals: [
//                Mineral(name: "Magnesium", dailyValue: 8.0),
//                Mineral(name: "Potassium", dailyValue: 2.0)
//            ]
//        ),
//        userRating: 4.8,
//        numberOfRatings: 240,
//        category: Categories[1],
//        pros: [
//             "High in plant-based protein",
//             "Contains essential vitamins and minerals",
//             "Made with organic, minimally processed ingredients"
//         ],
//         cons: [
//             "Contains tree nuts (almonds), which are a common allergen",
//             "Relatively high in natural sugars from dates"
//         ]// Nut Butter
//    ),
//    Product(
//        id: UUID(),
//        name: "Organic Soybean Oil",
//        imageURL: URL(string: "https://via.placeholder.com/300x200")!,
//        healthScore: 50,
//        ingredients: [Ingredients["Soybean Oil"]!],
//        allergens: [.soy],
//        nutritionInfo: NutritionInfo(
//            calories: 120,
//            fats: 14,
//            sugars: 0,
//            protein: 0,
//            sodium: 0,
//            carbohydrates: 0,
//            vitamins: [],
//            minerals: []
//        ),
//        userRating: 3.5,
//        numberOfRatings: 200,
//        category: Categories[2],
//        pros: [
//             "High in plant-based protein",
//             "Contains essential vitamins and minerals",
//             "Made with organic, minimally processed ingredients"
//         ],
//         cons: [
//             "Contains tree nuts (almonds), which are a common allergen",
//             "Relatively high in natural sugars from dates"
//         ]// Oil
//    ),
//    Product(
//        id: UUID(),
//        name: "Organic Potato Chips",
//        imageURL: URL(string: "https://via.placeholder.com/300x200")!,
//        healthScore: 65,
//        ingredients: [Ingredients["Potato"]!, Ingredients["Salt"]!],
//        allergens: [],
//        nutritionInfo: NutritionInfo(
//            calories: 150,
//            fats: 10,
//            sugars: 1,
//            protein: 2,
//            sodium: 180,
//            carbohydrates: 15,
//            vitamins: [],
//            minerals: []
//        ),
//        userRating: 4.0,
//        numberOfRatings: 140,
//        category: Categories[3],
//        pros: [
//             "High in plant-based protein",
//             "Contains essential vitamins and minerals",
//             "Made with organic, minimally processed ingredients"
//         ],
//         cons: [
//             "Contains tree nuts (almonds), which are a common allergen",
//             "Relatively high in natural sugars from dates"
//         ]// Snacks
//    ),
//    Product(
//        id: UUID(),
//        name: "Organic Milk",
//        imageURL: URL(string: "https://via.placeholder.com/300x200")!,
//        healthScore: 90,
//        ingredients: [Ingredients["Milk"]!],
//        allergens: [.milk],
//        nutritionInfo: NutritionInfo(
//            calories: 120,
//            fats: 2.5,
//            sugars: 12,
//            protein: 8,
//            sodium: 120,
//            carbohydrates: 12,
//            vitamins: [
//                Vitamin(name: "Vitamin A", dailyValue: 10.0),
//                Vitamin(name: "Vitamin D", dailyValue: 20.0)
//            ],
//            minerals: [
//                Mineral(name: "Calcium", dailyValue: 30.0),
//                Mineral(name: "Phosphorus", dailyValue: 15.0)
//            ]
//        ),
//        userRating: 4.5,
//        numberOfRatings: 170,
//        category: Categories[4],
//        pros: [
//             "High in plant-based protein",
//             "Contains essential vitamins and minerals",
//             "Made with organic, minimally processed ingredients"
//         ],
//         cons: [
//             "Contains tree nuts (almonds), which are a common allergen",
//             "Relatively high in natural sugars from dates"
//         ]// Dairy
//    )
//]
//let sampleUser = User(
//    id: UUID(),
//    name: "Arjun",
//    dietaryRestrictions: [.glutenFree, .dairyFree],
//    allergies: [.peanuts, .wheat],
//    recentlyViewedProducts: [sampleProducts[0]]
//)
//let sampleLists: [SavedList] = [
//    SavedList(
//        id: UUID(),
//        name: "Grocery List",
//        products: [
//            sampleProducts[0], // Organic Whole Wheat Bread
//            sampleProducts[3], // Organic Potato Chips
//            sampleProducts[4]  // Organic Milk
//        ],
//        iconName: "list"
//    ),
//    SavedList(
//        id: UUID(),
//        name: "Baking Supplies",
//        products: [
//            sampleProducts[0], // Organic Whole Wheat Bread
//            sampleProducts[1]  // Organic Crunchy Peanut Butter
//        ],
//        iconName: "baking"
//    ),
//    SavedList(
//        id: UUID(),
//        name: "Pantry Essentials",
//        products: [
//            sampleProducts[2], // Organic Soybean Oil
//            sampleProducts[1]  // Organic Crunchy Peanut Butter
//        ],
//        iconName: "pantry"
//    )
//]
