import UIKit
struct Product {
    let id: String
    let name: String
    let imageURL: String
    let healthScore: Int
    var ingredients: [Ingredient]
    var allergens: [Allergen]
    var nutritionFacts: NutritionInfo
    var userRating: Float
}

struct NutritionInfo {
    let calories: Int
    let fats: Double
    let sugars: Double
    let protein: Double
    let sodium: Double
    let carbohydrates: Double
    let vitamins: [String]
    let minerals: [String]
}
struct User {
    let id: String
    var name: String
    var dietaryRestrictions: [DietaryRestriction]
    var allergies: [Allergen]
}

struct SavedList {
    let id: String
    let name: String
    var products: [Product]
    let icon: String
}

struct Ingredient {
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
enum Allergen: String {
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

struct Ingredients {
    let name: String
    let riskLevel: String
    let riskColor: UIColor
}

var ingredients = [
    Ingredients(name: "Wheat Flour", riskLevel: "Low Risk", riskColor: .orange),
    Ingredients(name: "Millet", riskLevel: "Risk Free", riskColor: .systemGreen),
    Ingredients(name: "Soy", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Wheat Gluten", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Cocoa Powder", riskLevel: "Low Risk", riskColor: .orange),
    Ingredients(name: "Milk Solids", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Wheat Flour", riskLevel: "Low Risk", riskColor: .orange),
    Ingredients(name: "Millet", riskLevel: "Risk Free", riskColor: .systemGreen),
    Ingredients(name: "Soy", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Wheat Gluten", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Cocoa Powder", riskLevel: "Low Risk", riskColor: .orange),
    Ingredients(name: "Milk Solids", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Wheat Flour", riskLevel: "Low Risk", riskColor: .orange),
    Ingredients(name: "Millet", riskLevel: "Risk Free", riskColor: .systemGreen),
    Ingredients(name: "Soy", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Wheat Gluten", riskLevel: "High Risk", riskColor: .red),
    Ingredients(name: "Cocoa Powder", riskLevel: "Low Risk", riskColor: .orange),
    Ingredients(name: "Milk Solids", riskLevel: "High Risk", riskColor: .red)
]

struct NutritionFact {
    let name: String
    let amount: String
    let percentage: Float
}
let nutritionFacts: [NutritionFact] = [
    NutritionFact(name: "Total Fat", amount: "3.5 g", percentage: 0.5),
    NutritionFact(name: "Saturated Fat", amount: "3.5 g", percentage: 0.7),
    NutritionFact(name: "Cholesterol", amount: "10 mg", percentage: 0.1),
    NutritionFact(name: "Carbohydrates", amount: "15 g", percentage: 0.6),
    NutritionFact(name: "Protein", amount: "7.5 g", percentage: 0.8),
    NutritionFact(name: "Calcium", amount: "7.5 g", percentage: 0.3),
    NutritionFact(name: "Iron", amount: "7.5 mg", percentage: 0.2),
    NutritionFact(name: "Vitamin A", amount: "44 mg", percentage: 0.9)
]
