import UIKit
struct User{
    let id: UUID
        var name: String
        var dietaryRestrictions: [DietaryRestriction]
        var allergies: [Allergen]
    var recentlyViewedProducts : [Product]
    
}

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

struct SavedList{
    let id: UUID
    let name: String
    var products: [Product]
    let iconName: UIImage

    }
struct Category {
    let id: UUID
    let name: String
    let imageName: String
    
}
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
struct Vitamin {
    let name: String
    let dailyValue: Double
}
struct Mineral {
    let name: String
    let dailyValue: Double
}

struct Ingredient {
    let id: UUID
    let name: String
    let riskLevel: RiskLevel
    let nutritionalInfo: String
    let potentialConcerns: String
}

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
let Ingredients: [String: Ingredient] = [
    "Whole Wheat Flour": Ingredient(
        id: UUID(),
        name: "Whole Wheat Flour",
        riskLevel: .low,
        nutritionalInfo: "Source of fiber and carbohydrates",
        potentialConcerns: "Contains gluten"
    ),
    "Yeast": Ingredient(
        id: UUID(),
        name: "Yeast",
        riskLevel: .riskFree,
        nutritionalInfo: "Helps with bread fermentation",
        potentialConcerns: "None"
    ),
    "Salt": Ingredient(
        id: UUID(),
        name: "Salt",
        riskLevel: .low,
        nutritionalInfo: "Essential mineral, but excessive intake can raise blood pressure",
        potentialConcerns: "Sodium content"
    ),
    "Sugar": Ingredient(
        id: UUID(),
        name: "Sugar",
        riskLevel: .high,
        nutritionalInfo: "Sweetener",
        potentialConcerns: "May contribute to high blood sugar"
    ),
    "Soybean Oil": Ingredient(
        id: UUID(),
        name: "Soybean Oil",
        riskLevel: .high,
        nutritionalInfo: "Contains fats, adds flavor",
        potentialConcerns: "Common allergen for some people"
    )
]
// MARK: - Sample Data
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
let sampleUser = User(
    id: UUID(),
    name: "Arjun",
    dietaryRestrictions: [.glutenFree, .dairyFree],
    allergies: [.peanuts, .wheat],
    recentlyViewedProducts: [sampleProducts[0]]
)
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
