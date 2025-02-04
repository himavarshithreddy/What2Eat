import UIKit

// MARK: - User Model

struct User{
    let id: UUID
    var name: String
    var dietaryRestrictions: [DietaryRestriction]
    var allergies: [Allergen]
    var picksforyou: [Product]
    var recentScans : [Product]
    var ratings: [UUID: Int]
}
struct Users{
    var name: String
    var dietaryRestrictions: [String]
    var allergies: [String]
    var recentScans : [String]
}

// MARK: - Product Model
struct Product {
    let id: UUID
    let barcode: String
    let name: String
    let imageURL: String
 
    var nutritionInfo: NutritionInfo
    var userRating: Float
    var numberOfRatings: Int
    let categoryId: UUID
    let pros: [String]
    let cons: [String]
    var healthScore: Int // Health score calculated from grade score

    // Method to calculate health score from Nutri-Score grade logic
    static func calculateHealthScore(from nutritionInfo: NutritionInfo) -> Int {
        let negativePoints = calculateNegativePoints(from: nutritionInfo)
        let positivePoints = calculatePositivePoints(from: nutritionInfo)
        
        var gradeScore: Int
        if negativePoints < 11 {
            gradeScore = negativePoints - positivePoints
        } else if nutritionInfo.fruitsVegetablesNuts >= 80 {
            gradeScore = negativePoints - positivePoints
        } else {
            gradeScore = negativePoints - (positivePoints - Int(nutritionInfo.fiber / 1.5))
        }
        
        // Convert grade score to health score (0-100 scale)
        return convertGradeScoreToHealthScore(gradeScore: gradeScore)
    }
    
    // Function to convert grade score to health score
    private static func convertGradeScoreToHealthScore(gradeScore: Int) -> Int {
        var healthScore: Int
            
            switch gradeScore {
            case ...2: // Green
                healthScore = 76 + (2 - gradeScore) * 12
            case 3...11: // Orange
                healthScore = 75 - (gradeScore - 3) * 5
            case 12...: // Red
                healthScore = max(0, 39 - (gradeScore - 12) * 4)
            default:
                healthScore = 0
            }
            return max(0, min(100, healthScore))
        }

    // Static methods to calculate negative and positive points (unchanged)
    private static func calculateNegativePoints(from nutritionInfo: NutritionInfo) -> Int {
        var points = 0
        let energy = Double(nutritionInfo.energy) * 4.184 // Convert kcal to kJ
        if energy > 335 {
            points += min(Int(energy / 335), 10)
        }
        if nutritionInfo.fats > 1 {
            points += min(Int(nutritionInfo.fats), 10)
        }
        if nutritionInfo.sugars > 4.5 {
            points += min(Int(nutritionInfo.sugars / 4.5), 10)
        }
        if nutritionInfo.sodium > 90 {
            points += min(Int(nutritionInfo.sodium / 90), 10)
        }
        return points
    }
    
    private static func calculatePositivePoints(from nutritionInfo: NutritionInfo) -> Int {
        var points = 0
        if nutritionInfo.fruitsVegetablesNuts >= 80 {
            points += 5
        } else if nutritionInfo.fruitsVegetablesNuts >= 60 {
            points += 4
        } else if nutritionInfo.fruitsVegetablesNuts >= 40 {
            points += 3
        } else if nutritionInfo.fruitsVegetablesNuts > 0 {
            points += 2
        }
        if nutritionInfo.fiber >= 3.5 {
            points += 5
        } else if nutritionInfo.fiber >= 2.8 {
            points += 4
        } else if nutritionInfo.fiber >= 2.1 {
            points += 3
        } else if nutritionInfo.fiber >= 1.4 {
            points += 2
        } else if nutritionInfo.fiber >= 0.7 {
            points += 1
        }
        if nutritionInfo.protein >= 8.0 {
            points += 5
        } else if nutritionInfo.protein >= 6.4 {
            points += 4
        } else if nutritionInfo.protein >= 4.8 {
            points += 3
        } else if nutritionInfo.protein >= 3.2 {
            points += 2
        } else if nutritionInfo.protein >= 1.6 {
            points += 1
        }
        return points
    }
}

// MARK: - Saved List Model
struct SavedList{
    let id: UUID
    let name: String
    var products: [ProductData]
    let iconName: UIImage
}

// MARK: - Category Model
struct Category {
    let id: UUID
    let name: String
    let imageName: String
}
struct category {
    let id: Int
    let name: String
    let imageName: String
}
struct ProductList {
    let id:String
    let name: String
    let healthScore: Int
    let imageURL: String
}
struct ProductData: Codable {
    let id: String
    let barcode: String
    let name: String
    let imageURL: String
    let ingredients: [String]
    let artificialIngredients: [String]
    let nutritionInfo: [String: String]  // Dynamic dictionary to accommodate varying nutrition fields
    var userRating: Float
    var numberOfRatings: Int
    let categoryId: String
    let pros: [String]
    let cons: [String]
    let healthScore: Double
}

// Categories Data
let Categories: [Category] = [
    Category(id: UUID(), name: "Cakes & Bakes", imageName: "cakesandbakes"),
    Category(id: UUID(), name: "Biscuits", imageName: "biscuits"),
    Category(id: UUID(), name: "Breakfast", imageName: "breakfast"),
    Category(id: UUID(), name: "Chocolates & Desserts", imageName: "chocolates"),
    Category(id: UUID(), name: "Cold Drinks and Juices", imageName: "colddrinks"),
    Category(id: UUID(), name: "Dairy & Bread", imageName: "dairy"),
    Category(id: UUID(), name: "Oil , Masalas & more", imageName: "oilandmasalas"),
    Category(id: UUID(), name: "Instant Foods", imageName: "instantfoods"),
    Category(id: UUID(), name: "Chips and Munchies", imageName: "chips"),
    Category(id: UUID(), name: "Suppliments & more", imageName: "suppliments"),
    Category(id: UUID(), name: "Tea , Coffee and more", imageName: "teacoffee"),
    Category(id: UUID(), name: "Miscellaneous", imageName: "Miscellaneous")
]

// MARK: - Nutrition Model
struct NutritionInfo {
    let energy: Int
    let fats: Double
    let sugars: Double
    let protein: Double
    let sodium: Double
    let carbohydrates: Double
    let vitaminB: Double
    let iron: Double
    let fiber: Double
    let fruitsVegetablesNuts: Double
}
struct Nutrient {
        let name: String
    }
let nutrients: [Nutrient] = [
    Nutrient(name: "Calories"),
    Nutrient(name: "Fats"),
    Nutrient(name: "Sugars"),
    Nutrient(name: "Protein"),
    Nutrient(name: "Sodium"),
    Nutrient(name: "Carbohydrates"),
    Nutrient(name: "Vitamin B"),
    Nutrient(name: "Iron")
]

// MARK: - Ingredient Model
struct IngredientDetail {
    var name: String
    var description: String
    var potentialConcern: String
    var regulatoryStatus: String
    var riskLevel: String
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
    case dairy = "Dairy"
    case nuts = "Nuts"
}

enum DietaryRestriction: String{
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case lowSugar = "Low Sugar"
    case keto = "Keto"
    case highBP = "High Blood Pressure"
}


    

// MARK: - Sample Products
let sampleProducts: [Product] = [
    Product(
        id: UUID(),
        barcode:"1234567890111",
        name: "Boost",
        imageURL: "Frame 2145",
      
        nutritionInfo: NutritionInfo(
            energy: 375,
            fats: 2.5,
            sugars: 9.5,
            protein: 7.5,
            sodium: 0,
            carbohydrates: 80,
            vitaminB: 20,
            iron: 44.5,
            fiber: 0,
            fruitsVegetablesNuts: 0
        ),
        userRating: 4.2,
        numberOfRatings: 45,
        categoryId: Categories[6].id,
        pros: [
             "High in plant-based protein",
             "Contains essential vitamins and minerals",
             "Made with organic, minimally processed ingredients"
         ],
         cons: [
             "Contains tree nuts (almonds), which are a common allergen",
             "Relatively high in natural sugars from dates"
         ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 375,
            fats: 2.5,
            sugars: 9.5,
            protein: 7.5,
            sodium: 0,
            carbohydrates: 80,
            vitaminB: 20,
            iron: 44.5,
            fiber: 0,
            fruitsVegetablesNuts: 0
        ))
    ),Product(
        id: UUID(),
        barcode:"1234567890299",
        name: "Cheddar Cheese",
        imageURL: "cheddar",
        nutritionInfo: NutritionInfo(
            energy: 402,
            fats: 33.0,
            sugars: 0.1,
            protein: 25.0,
            sodium: 621,
            carbohydrates: 1.3,
            vitaminB: 0.0,
            iron: 0.7,
            fiber: 0,
            fruitsVegetablesNuts: 0
        ),
        userRating: 4.5,
        numberOfRatings: 150,
        categoryId: Categories[4].id,
        pros: [
            "Rich in protein",
            "Good source of calcium"
        ],
        cons: [
            "High in fat and sodium",
            "Not lactose-free"
        ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 402,
            fats: 33.0,
            sugars: 0.1,
            protein: 25.0,
            sodium: 621,
            carbohydrates: 1.3,
            vitaminB: 0.0,
            iron: 0.7,
            fiber: 0,
            fruitsVegetablesNuts: 0
        ))
    ),
    Product(
        id: UUID(),
        barcode:"1234567890300",
        name: "Yogurt",
        imageURL: "yogurt",
     
            nutritionInfo: NutritionInfo(
                energy: 46,
                fats: 0,
                sugars: 71,
                protein: 7.1,
                sodium: 1,
                carbohydrates: 12,
                vitaminB: 0,
                iron: 0.2,
                fiber: 0,
                fruitsVegetablesNuts: 100
        ),
        userRating: 4.7,
        numberOfRatings: 175,
        categoryId: Categories[4].id,
        pros: [
            "Good for gut health",
            "Low in fat"
        ],
        cons: [
            "Contains lactose",
            "Plain versions may be bland"
        ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 46,
            fats: 0,
            sugars: 71,
            protein: 7.1,
            sodium: 1,
            carbohydrates: 12,
            vitaminB: 0,
            iron: 0.2,
            fiber: 0,
            fruitsVegetablesNuts: 100
        ))
    ),
    Product(
        id: UUID(),
        barcode:"1234567890311",
        name: "Butter",
        imageURL: "butter",
        nutritionInfo: NutritionInfo(
            energy: 45,
            fats: 0,
            sugars: 119,
            protein: 0.7,
            sodium: 0,
            carbohydrates: 11,
            vitaminB: 0,
            iron: 0.1,
            fiber: 0.2,
            fruitsVegetablesNuts: 100
        ),
        userRating: 4.2,
        numberOfRatings: 100,
        categoryId: Categories[4].id,
        pros: [
            "Rich in flavor",
            "Good source of fat-soluble vitamins"
        ],
        cons: [
            "Very high in saturated fats",
            "Not suitable for lactose-intolerant individuals"
        ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 45,
            fats: 0,
            sugars: 119,
            protein: 0.7,
            sodium: 0,
            carbohydrates: 11,
            vitaminB: 0,
            iron: 0.1,
            fiber: 0.2,
            fruitsVegetablesNuts: 100
        ))
    ),

]

// MARK: - Sample User
var sampleUser = User(
    id: UUID(),
    name: "Arjun",
    dietaryRestrictions: [.glutenFree, .dairyFree],
    allergies: [.peanuts, .wheat],
    picksforyou:  [sampleProducts[1], sampleProducts[2], sampleProducts[3]],
    recentScans: [sampleProducts[1],sampleProducts[2],sampleProducts[3]],
    ratings: [UUID(): 4,UUID(): 5]
)

// MARK: - Sample Saved Lists
var sampleLists: [SavedList] = [
    SavedList(
        id: UUID(),
        name: "Snacks",
        products: [
            
        ],
        iconName: UIImage(systemName: "popcorn")!
    ),
    SavedList(
        id: UUID(),
        name: "Healthy choices",
        products: [
            
        ],
        iconName: UIImage(systemName: "heart")!
    ),
    SavedList(
        id: UUID(),
        name: "Workout",
        products: [
           
        ],
        iconName: UIImage(systemName: "figure.run")!
    ),SavedList(
        id: UUID(),
        name: "Kids",
        products: [
            
        ],
        iconName: UIImage(systemName: "figure.2.and.child.holdinghands")!
    )
]
let savedlistImages = [
    "leaf", "carrot", "fork.knife", "cart", "cup.and.saucer",
               "takeoutbag.and.cup.and.straw", "popcorn", "flame", "applelogo",
               "fork.knife.circle", "heart", "heart.circle", "staroflife",
               "cross.case", "pills", "figure.walk", "figure.walk.circle",
               "figure.run", "figure.strengthtraining.traditional", "bandage"
]
struct recentSearchs{
    var products: [Product]
    var searchQueries: [String]
}
var recentSearch = recentSearchs(products: [sampleProducts[1],
                                            sampleProducts[2],
                                            sampleProducts[3]],
                                  searchQueries: [])

