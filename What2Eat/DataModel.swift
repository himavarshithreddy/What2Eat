//import UIKit
//struct Product {
//    let id: String
//    let name: String
//    let imageURL: String
//    let healthScore: Int
//    var ingredients: [Ingredient]
//    var allergens: [Allergen]
//    var nutritionFacts: NutritionInfo
//    var userRating: Float
//}
//struct NutritionInfo {
//    let calories: Int
//    let fats: Double
//    let sugars: Double
//    let protein: Double
//    let sodium: Double
//    let carbohydrates: Double
//    let vitamins: [String]
//    let minerals: [String]
//}
//struct User {
//    let id: String
//    var name: String
//    var dietaryRestrictions: [DietaryRestriction]
//    var allergies: [Allergen]
//}
//struct SavedList {
//    let id: String
//    let name: String
//    var products: [Product]
//    let icon: String
//}
//struct Ingredient {
//    let name: String
//    let riskLevel: RiskLevel
//    let nutritionalInfo: String
//    let potentialConcerns: String
//    let description: String
//}
//enum RiskLevel: String {
//    case low = "Low Risk"
//    case high = "High Risk"
//    case riskFree = "Risk Free"
//}
//enum Allergen: String {
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
//enum DietaryRestriction: String{
//    case glutenFree = "Gluten-Free"
//    case dairyFree = "Dairy-Free"
//    case nutFree = "Nut-Free"
//    case vegan = "Vegan"
//    case vegetarian = "Vegetarian"
//    case lowSugar = "Low Sugar"
//    case keto = "Keto"
//}
//struct Ingredients {
//    let name: String
//    let riskLevel: String
//    let riskColor: UIColor
//    let nutritionalInfo: String
//    let potentialConcerns: String
//    let description: String
//}
//var ingredients = [
//    Ingredients(
//        name: "Wheat Flour",
//        riskLevel: "Low Risk",
//        riskColor: .orange,
//        nutritionalInfo: "High in carbohydrates, moderate protein.",
//        potentialConcerns: "May contain gluten, can cause allergies.",
//        description: "A finely milled flour from wheat, used as a staple ingredient."
//    ),
//    Ingredients(
//        name: "Millet",
//        riskLevel: "Risk Free",
//        riskColor: .systemGreen,
//        nutritionalInfo: "Rich in magnesium, phosphorus, and antioxidants.",
//        potentialConcerns: "Generally safe, but may cause issues for those with grain sensitivities.",
//        description: "A small-seeded grass, millet is a versatile and nutritious grain."
//    ),
//    Ingredients(
//        name: "Soy",
//        riskLevel: "High Risk",
//        riskColor: .red,
//        nutritionalInfo: "High in protein, contains essential amino acids.",
//        potentialConcerns: "Contains phytoestrogens; can cause allergies.",
//        description: "A legume used widely for its protein and health benefits."
//    ),
//    Ingredients(
//        name: "Wheat Gluten",
//        riskLevel: "High Risk",
//        riskColor: .red,
//        nutritionalInfo: "High in protein, low in fat.",
//        potentialConcerns: "A common allergen; may cause digestive issues in those with gluten intolerance.",
//        description: "A protein found in wheat that provides elasticity to dough."
//    ),
//    Ingredients(
//        name: "Cocoa Powder",
//        riskLevel: "Low Risk",
//        riskColor: .orange,
//        nutritionalInfo: "Rich in antioxidants, low in sugar and fat.",
//        potentialConcerns: "May contain trace allergens; caffeine content can be stimulating.",
//        description: "A powder made from roasted cocoa beans, used to flavor foods."
//    ),
//    Ingredients(
//        name: "Milk Solids",
//        riskLevel: "High Risk",
//        riskColor: .red,
//        nutritionalInfo: "High in calcium, protein, and vitamins.",
//        potentialConcerns: "Contains lactose, a common allergen; may cause digestive issues.",
//        description: "Concentrated milk without water content, adds richness to products."
//    )
//]
//
//struct NutritionFact {
//    let name: String
//    let amount: String
//    let percentage: Float
//}
//let nutritionFacts: [NutritionFact] = [
//    NutritionFact(name: "Total Fat", amount: "3.5 g", percentage: 0.35),
//    NutritionFact(name: "Saturated Fat", amount: "3.5 g", percentage: 0.7),
//    NutritionFact(name: "Cholesterol", amount: "10 mg", percentage: 0.1),
//    NutritionFact(name: "Carbohydrates", amount: "15 g", percentage: 0.6),
//    NutritionFact(name: "Protein", amount: "7.5 g", percentage: 0.8),
//    NutritionFact(name: "Calcium", amount: "7.5 g", percentage: 0.3),
//    NutritionFact(name: "Iron", amount: "7.5 mg", percentage: 0.2),
//    NutritionFact(name: "Vitamin A", amount: "44 mg", percentage: 0.9)
//]
//
//struct Category {
//    let name: String
//    let imageName: String
//}
//
//let categories = [
//        Category(name: "Bakery", imageName: "bakeryImage"),
//        Category(name: "Juices", imageName: "juicesImage"),
//        Category(name: "Dairy", imageName: "dairyImage"),
//        Category(name: "Breakfast", imageName: "breakfastImage"),
//        Category(name: "Frozen Food", imageName: "frozenfoodImage"),
//        Category(name: "Cereal Bars", imageName: "cerealBarsImage"),
//        Category(name: "Sauces", imageName: "saucesImage"),
//        Category(name: "Bakery", imageName: "bakeryImage"),
//        Category(name: "Juices", imageName: "juicesImage"),
//        Category(name: "Desserts", imageName: "dessertsImage")
//    ]
//
//
//
//import UIKit
//struct AlertModel {
//    let text: String
//}
//let alerts = [
//    AlertModel(text: "Contains Milk and Soy"),
//    AlertModel(text: "Non Vegetarian")
//]

//struct Saved{
//    let name:String
//    let icon:UIImage
//}
//var Savedlists = [
//    Saved(name: "Snacks", icon: UIImage(systemName: "popcorn")!),
//    Saved(name: "Healthy choices", icon: UIImage(systemName: "heart")!),
//    Saved(name: "Workout", icon: UIImage(systemName: "figure.run")!),
//    Saved(name: "Kids", icon: UIImage(systemName: "figure.2.and.child.holdinghands")!),
//    ]
//let randomlistImages = [
//    "leaf", "carrot", "fork.knife", "cart", "cup.and.saucer",
//               "takeoutbag.and.cup.and.straw", "popcorn", "flame", "applelogo",
//               "fork.knife.circle", "heart", "heart.circle", "staroflife",
//               "cross.case", "pills", "figure.walk", "figure.walk.circle",
//               "figure.run", "figure.strengthtraining.traditional", "bandage"
//]
//struct SavedProducts{
//    let name:String
//    let image:String
//    let score:Int
//}
//var SavedProductsList = [
//    SavedProducts(name: "Boost", image: "Frame 2146",score: 55),
//    SavedProducts(name: "Good Day Chunkies", image: "Frame 2193",score: 16),
//    SavedProducts(name: "Lays", image: "Frame 2197",score: 78)]
//
//struct ExploreProducts{
//    let name:String
//    let image:String
//    let score:Int
//}
//var ExploreProductslist = [
//    ExploreProducts(name: "Butter", image: "Frame 2145", score: 10),
//    ExploreProducts(name: "Heritage Curd", image: "Frame 2145", score: 90),
//    ExploreProducts(name: "Arokya Milk", image: "Frame 2145", score: 60),
//    ExploreProducts(name: "Ghee", image: "Frame 2145", score: 55)]
