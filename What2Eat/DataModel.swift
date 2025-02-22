import UIKit

// MARK: - User Model


struct Users{
    var name: String
    var dietaryRestrictions: [String]
    var allergies: [String]
    var recentScans : [String]
}



struct SavedList {
    let listId: String
    let name: String
    let iconName: String
    var products: [String]// Store as string
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
    let barcode: [String]
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

struct IngredientDetail {
    var name: String
    var description: String
    var potentialConcern: String
    var regulatoryStatus: String
    var riskLevel: String
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




enum DietaryRestriction: String {
    case lowSodium = "Low-sodium"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case sugarFree = "Sugar-Free"
    case lowCalorie = "Low-Calorie"
    case ketoDiet = "Keto Diet"
    case paleoDiet = "Paleo Diet"
    case lowSugar = "Low Sugar"
    case lactoseFree = "Lactose Free"
    case glutenFree = "Gluten Free"
}


let savedlistImages = [
    "leaf", "carrot", "fork.knife", "cart", "cup.and.saucer",
               "takeoutbag.and.cup.and.straw", "popcorn", "flame", "applelogo",
               "fork.knife.circle", "heart", "heart.circle", "staroflife",
               "cross.case", "pills", "figure.walk", "figure.walk.circle",
               "figure.run", "figure.strengthtraining.traditional", "bandage"
]
struct RecentItem: Codable {
    enum ItemType: String, Codable {
        case query  // A search query entered by the user
        case product // A product that was selected
    }
    
    let id: String      // Either the Firestore product ID or a generated UUID for queries
    let name: String    // The search query text or the product name
    let type: ItemType  // Indicates whether this item is a query or a product
}

var recentScansProducts: [(id: String, name: String, healthScore: Int, imageURL: String)] = []


enum Allergen: String {
    case milk = "Milk"
    case eggs = "Eggs"
    case fish = "Fish"
    case shellfish = "Shellfish"
    case Nuts = "Nuts"
    case peanuts = "Peanuts"
    case wheat = "Wheat"
    case soybean = "Soybean"
    case sesame = "Sesame"
    case celery = "Celery"
    case mustard = "Mustard"
    case lupin = "Lupin"
    case molluscs = "Molluscs"
    case sulfites = "Sulfites"
    case gluten = "Gluten"
    case corn = "Corn"
    case garlic = "Garlic"
    case onion = "Onion"
}


let allergies: [String] = [
    "Milk", "Eggs", "Fish", "Wheat", "Lupin", "Soybean",
    "Peanuts",  "Shellfish", "Sesame", "Gluten", "Corn",
    "Mustard", "Sulfites", "Celery", "Molluscs",
    "Garlic", "Onion","Nuts"
]


let allergenMapping: [String: [String]] = [
    "Milk": ["Milk", "Casein", "Lactose", "Whey", "Butter", "Cheese", "Curds", "Ghee", "Cream"],
    "Eggs": ["Egg", "Albumin", "Mayonnaise", "Ovalbumin", "Lysozyme"],
    "Fish": ["Fish", "Cod", "Salmon", "Tuna", "Anchovy", "Haddock", "Fish Sauce"],
    "Shellfish": ["Crab", "Lobster", "Shrimp", "Prawn", "Scallop", "Oyster", "Clam"],
    "Nuts": ["Almond", "Cashew", "Walnut", "Pistachio", "Pecan", "Hazelnut", "Macadamia"],
    "Peanuts": ["Peanut", "Peanut Butter", "Peanut Oil", "Groundnut"],
    "Wheat": ["Wheat", "Durum", "Semolina", "Spelt", "Kamut", "Bulgur", "Farina"],
    "Soybean": ["Soy", "Soybeans", "Soy Lecithin", "Soy Sauce", "Tofu", "Miso", "Tempeh"],
    "Sesame": ["Sesame", "Sesame Seeds", "Sesame Oil", "Tahini"],
    "Celery": ["Celery", "Celery Salt", "Celery Powder"],
    "Mustard": ["Mustard", "Mustard Seeds", "Yellow Mustard", "Dijon"],
    "Lupin": ["Lupin", "Lupine Flour"],
    "Molluscs": ["Octopus", "Squid", "Cuttlefish", "Snail"],
    "Sulfites": ["Sulfite", "Sulfur Dioxide", "Potassium Bisulfite", "Sodium Metabisulfite"],
    "Gluten": ["Wheat", "Barley", "Rye", "Malt", "Seitan", "Triticale"],
    "Corn": ["Corn", "Corn Starch", "Corn Syrup", "Maize", "High-Fructose Corn Syrup"],
    "Garlic": ["Garlic", "Garlic Powder", "Dehydrated Garlic"],
    "Onion": ["Onion", "Onion Powder", "Dehydrated Onion"]
]

let dietaryOptions = [
        "Low-sodium",
        "Vegan",
        "Vegetarian",
        "Sugar-Free",
        "Low-Calorie",
        "Keto Diet",
        "Paleo Diet",
        "Low Sugar",
        "Lactose Free",
        "Gluten Free"
    ]
    
    // Mapping each option to a DietaryRestriction enum case
    let dietaryRestrictionMapping: [String: DietaryRestriction] = [
        "Low-sodium": .lowSodium,
        "Vegan": .vegan,
        "Vegetarian": .vegetarian,
        "Sugar-Free": .sugarFree,
        "Low-Calorie": .lowCalorie,
        "Keto Diet": .ketoDiet,
        "Paleo Diet": .paleoDiet,
        "Low Sugar": .lowSugar,
        "Lactose Free": .lactoseFree,
        "Gluten Free": .glutenFree
    ]



struct ProductResponse: Codable {
    let name: String
    let ingredients: [String]
    let nutrition: [Nutrition]
    let healthscore: HealthScore
}

struct Nutrition: Codable {
    let name: String
    let value: Float
    let unit: String
}

struct HealthScore: Codable {
    let Energy: String
    let Sugars: String
    let Sodium: String
    let Protein: String
    let Fiber: String
    let FruitsVegetablesNuts: String
    let SaturatedFat: String
}

struct HealthScoreResponse: Codable {
    let healthScore: Int
    let calculationDetails: CalculationDetails
}

struct CalculationDetails: Codable {
    let negativePoints: Int
    let positivePoints: Int
    let fsaScore: Int
}
var isOnboarding:Bool = false

struct NutritionDetail {
    let name: String
    let value: String
}
