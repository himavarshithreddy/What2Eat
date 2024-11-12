import UIKit

// MARK: - User Model

struct User{
    let id: UUID
        var name: String
        var dietaryRestrictions: [DietaryRestriction]
        var allergies: [Allergen]
    var recentlyViewedProducts : [Product]
    
}

// MARK: - Product Model
struct Product {
    let id: UUID
    let name: String
    let imageURL: String
    let healthScore: Int
    var ingredients: [Ingredient]
    var allergens: [Allergen]
    var nutritionInfo: NutritionInfo
    var userRating: Float
    var numberOfRatings: Int
    let categoryId: UUID
    let pros: [String]
    let cons: [String]
}

// MARK: - Saved List Model
struct SavedList{
    let id: UUID
    let name: String
    var products: [Product]
    let iconName: UIImage
}

// MARK: - Category Model
struct Category {
    let id: UUID
    let name: String
    let imageName: String
    
}
// Categories Data
let Categories: [Category] = [
    Category(id: UUID(), name: "Bakery", imageName: "bakeryImage"),
    Category(id: UUID(), name: "Juices", imageName: "juicesImage"),
    Category(id: UUID(), name: "Dairy", imageName: "dairyImage"),
    Category(id: UUID(), name: "Breakfast", imageName: "breakfastImage"),
    Category(id: UUID(), name: "Frozen Food", imageName: "frozenfoodImage"),
    Category(id: UUID(), name: "Cereal Bars", imageName: "cerealBarsImage"),
    Category(id: UUID(), name: "Sauces", imageName: "saucesImage"),
    Category(id: UUID(), name: "Bakery", imageName: "bakeryImage"),
    Category(id: UUID(), name: "Juices", imageName: "juicesImage"),
    Category(id: UUID(), name: "Desserts", imageName: "dessertsImage"),
]

// MARK: - Nutrition Model
struct NutritionInfo {
    let calories: Int
    let fats: Double
    let sugars: Double
    let protein: Double
    let sodium: Double
    let carbohydrates: Double
    let vitamins: [Vitamin]
    let minerals: [Mineral]
}
struct Nutrient {
        let name: String
        let value: String
        let percentage: Float?  
    }
struct Vitamin {
    let name: String
    let dailyValue: Double
}
struct Mineral {
    let name: String
    let dailyValue: Double
}

// MARK: - Ingredient Model
struct Ingredient {
    let id: UUID
    let name: String
    let riskLevel: RiskLevel
    let nutritionalInfo: String
    let potentialConcerns: String
    let description: String
    var riskColor: UIColor {
            switch riskLevel {
            case .low:
                return UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1)
            case .high:
                return UIColor.systemRed
            case .riskFree:
                return UIColor.systemGreen
        }
    }
}

// MARK: - Enumerations
enum RiskLevel: String {
    case low = "Low Risk"
    case high = "High Risk"
    case riskFree = "Risk Free"
}
enum Allergen: String{
    case milk = "Milk"
    case peanuts = "Peanuts"
    case treeNuts = "Tree Nuts"
    case eggs = "Eggs"
    case soy = "Soy"
    case wheat = "Wheat"
    case fish = "Fish"
    case shellfish = "Shellfish"
    case sesame = "Sesame"
}

enum DietaryRestriction: String{
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case lowSugar = "Low Sugar"
    case keto = "Keto"
}

// MARK: - Sample Ingredients
let Ingredients: [String: Ingredient] = [
    "Whole Wheat Flour": Ingredient(
        id: UUID(),
        name: "Whole Wheat Flour",
        riskLevel: .low,
        nutritionalInfo: "Source of fiber and carbohydrates",
        potentialConcerns: "Contains gluten",
        description: "Whole wheat flour is made by grinding entire wheat kernels, retaining bran and germ, and is a nutritious source of fiber and minerals."
    ),
    "Yeast": Ingredient(
        id: UUID(),
        name: "Yeast",
        riskLevel: .riskFree,
        nutritionalInfo: "Helps with bread fermentation",
        potentialConcerns: "None",
        description: "Yeast is a microorganism used in baking to help dough rise and develop a light, airy texture through fermentation."
    ),
    "Salt": Ingredient(
        id: UUID(),
        name: "Salt",
        riskLevel: .low,
        nutritionalInfo: "Essential mineral, but excessive intake can raise blood pressure",
        potentialConcerns: "Sodium content",
        description: "Salt is a mineral essential for bodily functions and food preservation, but excessive intake may raise blood pressure."
    ),
    "Sugar": Ingredient(
        id: UUID(),
        name: "Sugar",
        riskLevel: .high,
        nutritionalInfo: "Sweetener",
        potentialConcerns: "May contribute to high blood sugar",
        description: "Sugar is a carbohydrate that provides sweetness and energy but may increase blood glucose levels when consumed in excess."
    ),
    "Soybean Oil": Ingredient(
        id: UUID(),
        name: "Soybean Oil",
        riskLevel: .high,
        nutritionalInfo: "Contains fats, adds flavor",
        potentialConcerns: "Common allergen for some people",
        description: "Soybean oil is extracted from soybeans, adding flavor and fats to foods. It may trigger allergic reactions in some people."
    )
]
    

// MARK: - Sample Products
let sampleProducts: [Product] = [
    Product(
        id: UUID(),
        name: "Organic Whole Wheat Bread",
        imageURL: "Frame 2145",
        healthScore: 80,
        ingredients: [Ingredients["Whole Wheat Flour"]!, Ingredients["Yeast"]!, Ingredients["Salt"]!],
        allergens: [.wheat],
        nutritionInfo: NutritionInfo(
            calories: 150,
            fats: 2.5,
            sugars: 3,
            protein: 5,
            sodium: 230,
            carbohydrates: 27,
            vitamins: [
                Vitamin(name: "Vitamin B6", dailyValue: 6.0),
                Vitamin(name: "Thiamin", dailyValue: 8.0)
            ],
            minerals: [
                Mineral(name: "Iron", dailyValue: 8.0),
                Mineral(name: "Magnesium", dailyValue: 6.0)
            ]
        ),
        userRating: 4.2,
        numberOfRatings: 45,
        categoryId: Categories[0].id,
        pros: [
             "High in plant-based protein",
             "Contains essential vitamins and minerals",
             "Made with organic, minimally processed ingredients"
         ],
         cons: [
             "Contains tree nuts (almonds), which are a common allergen",
             "Relatively high in natural sugars from dates"
         ]
    ),
    Product(
        id: UUID(),
        name: "Organic Crunchy Peanut Butter",
        imageURL: "Frame 2145",
        healthScore: 75,
        ingredients: [Ingredients["Sugar"]!, Ingredients["Salt"]!],
        allergens: [.peanuts],
        nutritionInfo: NutritionInfo(
            calories: 190,
            fats: 16,
            sugars: 3,
            protein: 7,
            sodium: 150,
            carbohydrates: 6,
            vitamins: [
                Vitamin(name: "Vitamin E", dailyValue: 10.0)
            ],
            minerals: [
                Mineral(name: "Magnesium", dailyValue: 8.0),
                Mineral(name: "Potassium", dailyValue: 2.0)
            ]
        ),
        userRating: 4.8,
        numberOfRatings: 240,
        categoryId: Categories[1].id,
        pros: [
             "High in plant-based protein",
             "Contains essential vitamins and minerals",
             "Made with organic, minimally processed ingredients"
         ],
         cons: [
             "Contains tree nuts (almonds), which are a common allergen",
             "Relatively high in natural sugars from dates"
         ]
    ),
    Product(
        id: UUID(),
        name: "Organic Soybean Oil",
        imageURL: "Frame 2145",
        healthScore: 50,
        ingredients: [Ingredients["Soybean Oil"]!],
        allergens: [.soy],
        nutritionInfo: NutritionInfo(
            calories: 120,
            fats: 14,
            sugars: 0,
            protein: 0,
            sodium: 0,
            carbohydrates: 0,
            vitamins: [],
            minerals: []
        ),
        userRating: 3.5,
        numberOfRatings: 200,
        categoryId: Categories[2].id,
        pros: [
             "High in plant-based protein",
             "Contains essential vitamins and minerals",
             "Made with organic, minimally processed ingredients"
         ],
         cons: [
             "Contains tree nuts (almonds), which are a common allergen",
             "Relatively high in natural sugars from dates"
         ]
    ),
    Product(
        id: UUID(),
        name: "Organic Potato Chips",
        imageURL: "Frame 2145",
        healthScore: 65,
        ingredients: [Ingredients["Salt"]!],
        allergens: [],
        nutritionInfo: NutritionInfo(
            calories: 150,
            fats: 10,
            sugars: 1,
            protein: 2,
            sodium: 180,
            carbohydrates: 15,
            vitamins: [],
            minerals: []
        ),
        userRating: 4.0,
        numberOfRatings: 140,
        categoryId: Categories[3].id,
        pros: [
             "High in plant-based protein",
             "Contains essential vitamins and minerals",
             "Made with organic, minimally processed ingredients"
         ],
         cons: [
             "Contains tree nuts (almonds), which are a common allergen",
             "Relatively high in natural sugars from dates"
         ]
    ),
    Product(
        id: UUID(),
        name: "Organic Milk",
        imageURL: "Frame 2145",
        healthScore: 90,
        ingredients: [],
        allergens: [.milk],
        nutritionInfo: NutritionInfo(
            calories: 120,
            fats: 2.5,
            sugars: 12,
            protein: 8,
            sodium: 120,
            carbohydrates: 12,
            vitamins: [
                Vitamin(name: "Vitamin A", dailyValue: 10.0),
                Vitamin(name: "Vitamin D", dailyValue: 20.0)
            ],
            minerals: [
                Mineral(name: "Calcium", dailyValue: 30.0),
                Mineral(name: "Phosphorus", dailyValue: 15.0)
            ]
        ),
        userRating: 4.5,
        numberOfRatings: 170,
        categoryId: Categories[4].id,
        pros: [
             "High in plant-based protein",
             "Contains essential vitamins and minerals",
             "Made with organic, minimally processed ingredients"
         ],
         cons: [
             "Contains tree nuts (almonds), which are a common allergen",
             "Relatively high in natural sugars from dates"
         ]
    )
]

// MARK: - Sample User
let sampleUser = User(
    id: UUID(),
    name: "Arjun",
    dietaryRestrictions: [.glutenFree, .dairyFree],
    allergies: [.peanuts, .wheat],
    recentlyViewedProducts: [sampleProducts[0]]
)

// MARK: - Sample Saved Lists
let sampleLists: [SavedList] = [
    SavedList(
        id: UUID(),
        name: "Snacks",
        products: [
            sampleProducts[0],
            sampleProducts[3],
            sampleProducts[4]
        ],
        iconName: UIImage(systemName: "popcorn")!
    ),
    SavedList(
        id: UUID(),
        name: "Healthy choices",
        products: [
            sampleProducts[0],
            sampleProducts[1]
        ],
        iconName: UIImage(systemName: "heart")!
    ),
    SavedList(
        id: UUID(),
        name: "Workout",
        products: [
            sampleProducts[2],
            sampleProducts[1]
        ],
        iconName: UIImage(systemName: "figure.run")!
    ),SavedList(
        id: UUID(),
        name: "Workout",
        products: [
            sampleProducts[2],
            sampleProducts[1]
        ],
        iconName: UIImage(systemName: "figure.2.and.child.holdinghands")!
    )
]
