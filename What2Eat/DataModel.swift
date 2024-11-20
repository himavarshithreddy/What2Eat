import UIKit

// MARK: - User Model

struct User{
    let id: UUID
    var name: String
    var dietaryRestrictions: [DietaryRestriction]
    var allergies: [Allergen]
    var picksforyou: [Product]
    var recentlyViewedProducts : [Product]
    var ratings: [UUID: Int]
    
}

// MARK: - Product Model
struct Product {
    let id: UUID
    let name: String
    let imageURL: String
    var ingredients: [Ingredient]
    func getAllergensForUser(_ user: User) -> [Allergen] {
                return ingredients.compactMap { ingredient in
                    user.allergies.first { allergen in
                        ingredient.name.lowercased().contains(allergen.rawValue.lowercased())
                    }
                }
            }
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
                return UIColor.systemOrange
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
    ),

        "Flaxseeds": Ingredient(
            id: UUID(),
            name: "Flaxseeds",
            riskLevel: .low,
            nutritionalInfo: "Rich in omega-3 fatty acids and fiber",
            potentialConcerns: "May interfere with certain medications when consumed in excess",
            description: "Flaxseeds are tiny seeds packed with nutrients like omega-3s, fiber, and lignans, offering numerous health benefits."
        ),
        "Sunflower Seeds": Ingredient(
            id: UUID(),
            name: "Sunflower Seeds",
            riskLevel: .low,
            nutritionalInfo: "Good source of healthy fats, vitamin E, and selenium",
            potentialConcerns: "High in calories, so should be consumed in moderation",
            description: "Sunflower seeds are nutrient-dense seeds that provide essential vitamins, minerals, and antioxidants."
        ),
        "Honey": Ingredient(
            id: UUID(),
            name: "Honey",
            riskLevel: .low,
            nutritionalInfo: "Natural sweetener with antioxidants and trace nutrients",
            potentialConcerns: "Not suitable for infants under 1 year due to botulism risk",
            description: "Honey is a natural sweetener made by bees, known for its antimicrobial properties and rich flavor."
        ),
        "Multigrain Mix": Ingredient(
            id: UUID(),
            name: "Multigrain Mix",
            riskLevel: .low,
            nutritionalInfo: "Blend of grains providing fiber, protein, and vitamins",
            potentialConcerns: "May contain gluten depending on the grains used",
            description: "A multigrain mix typically includes a blend of whole grains such as oats, barley, and millet, offering diverse nutrients."
        ),
        "Butter": Ingredient(
            id: UUID(),
            name: "Butter",
            riskLevel: .riskFree,
            nutritionalInfo: "High in saturated fats and vitamin A",
            potentialConcerns: "Excessive consumption can raise cholesterol levels",
            description: "Butter is a dairy product made by churning cream, commonly used in cooking and baking for its rich flavor."
        ),
        "Wheat Flour": Ingredient(
            id: UUID(),
            name: "Wheat Flour",
            riskLevel: .low,
            nutritionalInfo: "Source of carbohydrates and some protein",
            potentialConcerns: "Contains gluten",
            description: "Wheat flour is a versatile baking ingredient made by grinding wheat grains, commonly used in bread and pastries."
        ),
        "Blueberries": Ingredient(
            id: UUID(),
            name: "Blueberries",
            riskLevel: .low,
            nutritionalInfo: "Rich in antioxidants, fiber, and vitamin C",
            potentialConcerns: "Rarely causes allergic reactions",
            description: "Blueberries are small, sweet fruits that are highly nutritious and known for their antioxidant properties."
        ),
        "Vanilla Extract": Ingredient(
            id: UUID(),
            name: "Vanilla Extract",
            riskLevel: .low,
            nutritionalInfo: "Contains trace nutrients from vanilla beans",
            potentialConcerns: "High-alcohol extracts are not suitable for direct consumption",
            description: "Vanilla extract is a flavoring derived from vanilla beans, widely used in baking and desserts for its aroma and taste."
        ),
        "Eggs": Ingredient(
            id: UUID(),
            name: "Eggs",
            riskLevel: .low,
            nutritionalInfo: "Rich in protein, vitamins, and healthy fats",
            potentialConcerns: "Allergen for some individuals",
            description: "Eggs are a nutrient-dense food containing high-quality protein, essential vitamins, and choline."
        ),
        "Chocolate Chips": Ingredient(
            id: UUID(),
            name: "Chocolate Chips",
            riskLevel: .riskFree,
            nutritionalInfo: "Source of sugar and cocoa-derived antioxidants",
            potentialConcerns: "High in sugar and calories",
            description: "Chocolate chips are small pieces of sweetened chocolate, commonly used in baking for added flavor."
        ),
        "Baking Soda": Ingredient(
            id: UUID(),
            name: "Baking Soda",
            riskLevel: .low,
            nutritionalInfo: "Leavening agent with minimal nutritional value",
            potentialConcerns: "Overuse may cause an unpleasant taste",
            description: "Baking soda is a leavening agent that reacts with acids to release carbon dioxide, helping baked goods rise."
        ),
        "Bananas": Ingredient(
            id: UUID(),
            name: "Bananas",
            riskLevel: .low,
            nutritionalInfo: "Rich in potassium, fiber, and natural sugars",
            potentialConcerns: "May cause issues for people with latex allergies",
            description: "Bananas are a tropical fruit known for their sweet flavor and high potassium content, often used in baking."
        ),
        "Cinnamon": Ingredient(
            id: UUID(),
            name: "Cinnamon",
            riskLevel: .low,
            nutritionalInfo: "Rich in antioxidants and has anti-inflammatory properties",
            potentialConcerns: "Excessive consumption may cause liver issues due to coumarin content",
            description: "Cinnamon is a spice obtained from the bark of certain tree species, known for its warm, aromatic flavor."
        ),
        "Milk": Ingredient(
            id: UUID(),
            name: "Milk",
            riskLevel: .riskFree,
            nutritionalInfo: "Rich in calcium, protein, and vitamin D",
            potentialConcerns: "Common allergen and not suitable for lactose-intolerant individuals",
            description: "Milk is a nutrient-rich liquid commonly consumed as a beverage and used as an ingredient in cooking and baking."
        ),
    "Mango Pulp": Ingredient(
        id: UUID(),
        name: "Mango Pulp",
        riskLevel: .low,
        nutritionalInfo: "Rich in vitamins A and C, contains natural sugars and dietary fiber",
        potentialConcerns: "May cause allergic reactions in sensitive individuals",
        description: "Mango pulp is a thick, sweet product made from ripe mangoes, commonly used in desserts and beverages."
    ),

    "Citric Acid": Ingredient(
        id: UUID(),
        name: "Citric Acid",
        riskLevel: .low,
        nutritionalInfo: "Acts as a natural preservative and provides a tart flavor",
        potentialConcerns: "Overconsumption may irritate the stomach or teeth enamel",
        description: "Citric acid is an organic acid found naturally in citrus fruits, widely used as a flavor enhancer and preservative."
    ),

    "Apple Juice Concentrate": Ingredient(
        id: UUID(),
        name: "Apple Juice Concentrate",
        riskLevel: .low,
        nutritionalInfo: "Contains natural sugars, vitamin C, and antioxidants",
        potentialConcerns: "May contribute to high sugar intake if consumed in excess",
        description: "Apple juice concentrate is a concentrated form of apple juice, often used as a natural sweetener in foods and beverages."
    ),

    "Orange Juice Concentrate": Ingredient(
        id: UUID(),
        name: "Orange Juice Concentrate",
        riskLevel: .low,
        nutritionalInfo: "Rich in vitamin C and natural sugars, with a tangy flavor",
        potentialConcerns: "May trigger acid reflux in sensitive individuals",
        description: "Orange juice concentrate is a condensed form of orange juice, used to add flavor and nutrients to various recipes."
    ),

    "Ascorbic Acid": Ingredient(
        id: UUID(),
        name: "Ascorbic Acid",
        riskLevel: .low,
        nutritionalInfo: "A form of vitamin C, supports immune health and acts as an antioxidant",
        potentialConcerns: "Excessive intake may cause stomach upset",
        description: "Ascorbic acid is a water-soluble vitamin commonly used as a dietary supplement and food preservative."
    ),

    "Strawberry Puree": Ingredient(
        id: UUID(),
        name: "Strawberry Puree",
        riskLevel: .low,
        nutritionalInfo: "Rich in vitamin C, antioxidants, and natural sugars",
        potentialConcerns: "May cause allergic reactions in individuals sensitive to strawberries",
        description: "Strawberry puree is a smooth blend of ripe strawberries, used for its vibrant flavor and natural sweetness."
    ),

    "Blueberry Puree": Ingredient(
        id: UUID(),
        name: "Blueberry Puree",
        riskLevel: .low,
        nutritionalInfo: "Contains antioxidants, vitamin C, and dietary fiber",
        potentialConcerns: "May cause discoloration of teeth with frequent consumption",
        description: "Blueberry puree is made from fresh blueberries, offering a deep color and sweet-tart flavor for culinary use."
    ),

    "Blackberry Puree": Ingredient(
        id: UUID(),
        name: "Blackberry Puree",
        riskLevel: .low,
        nutritionalInfo: "Rich in antioxidants, vitamin K, and fiber",
        potentialConcerns: "Seeds may cause discomfort for some individuals",
        description: "Blackberry puree is a flavorful blend of ripe blackberries, commonly used in sauces, desserts, and beverages."
    ),

    "Grape Juice Concentrate": Ingredient(
        id: UUID(),
        name: "Grape Juice Concentrate",
        riskLevel: .low,
        nutritionalInfo: "Contains natural sugars, antioxidants, and vitamin C",
        potentialConcerns: "May contribute to high sugar intake if overused",
        description: "Grape juice concentrate is a sweet, thick liquid made from grapes, often used to enhance flavor and sweetness in foods."
    ),
    "Cream": Ingredient(
        id: UUID(),
        name: "Cream",
        riskLevel: .low,
        nutritionalInfo: "High in fat and calories, provides a rich texture and flavor",
        potentialConcerns: "May cause issues for individuals with lactose intolerance",
        description: "Cream is a dairy product separated from milk, often used to add richness to recipes and beverages."
    ),

    "Live Cultures": Ingredient(
        id: UUID(),
        name: "Live Cultures",
        riskLevel: .low,
        nutritionalInfo: "Rich in probiotics that support gut health",
        potentialConcerns: "May cause mild bloating or gas in some individuals",
        description: "Live cultures are beneficial bacteria found in fermented foods, promoting a healthy digestive system."
    ),

    "Enzymes": Ingredient(
        id: UUID(),
        name: "Enzymes",
        riskLevel: .low,
        nutritionalInfo: "Assist in breaking down nutrients for digestion",
        potentialConcerns: "Rarely cause allergic reactions in sensitive individuals",
        description: "Enzymes are proteins that catalyze chemical reactions, often added to foods to improve texture or digestibility."
    ),

    "Oats": Ingredient(
        id: UUID(),
        name: "Oats",
        riskLevel: .low,
        nutritionalInfo: "High in fiber, protein, and essential vitamins like B1",
        potentialConcerns: "May cause reactions in people with oat allergies or gluten sensitivity (if cross-contaminated)",
        description: "Oats are a whole grain commonly used in cereals, baked goods, and as a nutritious ingredient in many recipes."
    ),

    "Almonds": Ingredient(
        id: UUID(),
        name: "Almonds",
        riskLevel: .low,
        nutritionalInfo: "Rich in healthy fats, vitamin E, and magnesium",
        potentialConcerns: "A common allergen that may cause severe reactions in some individuals",
        description: "Almonds are a nutrient-dense nut used as a snack or ingredient in sweet and savory dishes."
    ),

    "Flour": Ingredient(
        id: UUID(),
        name: "Flour",
        riskLevel: .low,
        nutritionalInfo: "Source of carbohydrates and some essential vitamins and minerals",
        potentialConcerns: "May contain gluten, which is problematic for individuals with celiac disease or gluten sensitivity",
        description: "Flour is a finely ground powder made from grains, commonly used as a base for baking and cooking."
    ),

    "Baking Powder": Ingredient(
        id: UUID(),
        name: "Baking Powder",
        riskLevel: .low,
        nutritionalInfo: "Contains sodium bicarbonate and acid to help baked goods rise",
        potentialConcerns: "Excessive use may lead to a slightly bitter taste",
        description: "Baking powder is a leavening agent used in baking to create light and fluffy textures."
    ),

    "Corn": Ingredient(
        id: UUID(),
        name: "Corn",
        riskLevel: .low,
        nutritionalInfo: "Provides carbohydrates, fiber, and small amounts of vitamins like B3 and B6",
        potentialConcerns: "May cause allergic reactions in rare cases",
        description: "Corn is a versatile grain used as a staple food in many cultures, consumed fresh, dried, or processed into various products."
    ),

    "Rolled Oats": Ingredient(
        id: UUID(),
        name: "Rolled Oats",
        riskLevel: .low,
        nutritionalInfo: "High in soluble fiber and essential nutrients like manganese",
        potentialConcerns: "May cause reactions in people with oat allergies or gluten sensitivity (if cross-contaminated)",
        description: "Rolled oats are steamed and flattened oats used in oatmeal, granola, and baking recipes."
    )

    
]
    

// MARK: - Sample Products
let sampleProducts: [Product] = [
    Product(
        id: UUID(),
        name: "Boost",
        imageURL: "Frame 2145",
        ingredients: [Ingredients["Whole Wheat Flour"]!, Ingredients["Yeast"]!, Ingredients["Salt"]!],
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
    ), Product(
        id: UUID(),
        name: "Orange Juice",
        imageURL: "orange_juice",
        ingredients: [
            Ingredients["Orange Juice Concentrate"]!,
            Ingredients["Ascorbic Acid"]! // Vitamin C
        ],
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
        userRating: 4.5,
        numberOfRatings: 120,
        categoryId: Categories[1].id, // Example category ID for Juice
        pros: ["Refreshing", "Rich in Vitamin C"],
        cons: ["Contains added ascorbic acid"],
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
    ),Product(
        id: UUID(),
        name: "Crisp Apple Juice",
        imageURL: "apple_juice",
        ingredients: [
            Ingredients["Apple Juice Concentrate"]!,
            Ingredients["Citric Acid"]!
        ],
        nutritionInfo: NutritionInfo(
            energy: 46,
            fats: 5,
            sugars: 91,
            protein: 0.1,
            sodium: 1,
            carbohydrates: 12,
            vitaminB: 0,
            iron: 0.2,
            fiber: 0,
            fruitsVegetablesNuts: 100
        ),
        userRating: 4.3,
        numberOfRatings: 95,
        categoryId: Categories[1].id, // Example category ID for Juice
        pros: ["Sweet and smooth", "Good for hydration"],
        cons: ["High sugar content"],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 46,
            fats: 5,
            sugars: 91,
            protein: 0.1,
            sodium: 1,
            carbohydrates: 12,
            vitaminB: 0,
            iron: 0.2,
            fiber: 0,
            fruitsVegetablesNuts: 100
        ))
    ),Product(
        id: UUID(),
        name: "Mango Juice",
        imageURL: "mango_juice",
        ingredients: [
            Ingredients["Mango Pulp"]!,
            Ingredients["Sugar"]!,
            Ingredients["Citric Acid"]!
        ],
        nutritionInfo: NutritionInfo(
            energy: 90,
            fats: 10,
            sugars: 1,
            protein: 2,
            sodium: 30,
            carbohydrates: 15,
            vitaminB: 20,
            iron: 10,
            fiber: 2.5,
            fruitsVegetablesNuts: 90
        ),
        userRating: 4.7,
        numberOfRatings: 80,
        categoryId: Categories[1].id, // Example category ID for Juice
        pros: ["Sweet and tropical", "High in vitamins"],
        cons: ["Contains added sugar"],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 90,
            fats: 10,
            sugars: 1,
            protein: 2,
            sodium: 30,
            carbohydrates: 15,
            vitaminB: 20,
            iron: 10,
            fiber: 2.5,
            fruitsVegetablesNuts: 90
            ))

    ),Product(
        id: UUID(),
        name: "Mixed Berry Juice",
        imageURL: "mixed_berry_juice",
        ingredients: [
            Ingredients["Strawberry Puree"]!,
            Ingredients["Blueberry Puree"]!,
            Ingredients["Blackberry Puree"]!,
            Ingredients["Grape Juice Concentrate"]!
        ],
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
        userRating: 4.6,
        numberOfRatings: 110,
        categoryId: Categories[1].id, // Example category ID for Juice
        pros: ["Great taste", "Rich in antioxidants"],
        cons: ["Somewhat high in sugar"],
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
            name: "Multigrain Bread",
            imageURL: "multi",
            ingredients: [
                Ingredients["Whole Wheat Flour"]!,
                Ingredients["Multigrain Mix"]!,
                Ingredients["Honey"]!,
                Ingredients["Salt"]!,
                Ingredients["Sunflower Seeds"]!,
                Ingredients["Flaxseeds"]!
            ],
            nutritionInfo: NutritionInfo(
                    energy: 90,
                    fats: 10,
                    sugars: 1,
                    protein: 2,
                    sodium: 30,
                    carbohydrates: 15,
                    vitaminB: 20,
                    iron: 10,
                    fiber: 2.5,
                    fruitsVegetablesNuts: 90

            ),
            userRating: 4.5,
            numberOfRatings: 120,
            categoryId: Categories[0].id,
            pros: [
                "High in dietary fiber, aiding digestion.",
                "Rich in vitamins and minerals, including Vitamin B and Iron.",
            ],
            cons: [
                "Not suitable for gluten-intolerant individuals.",
                "Can be dry without spreads or toppings.",
            ],
            healthScore: Product.calculateHealthScore(from: NutritionInfo(
                energy: 90,
                fats: 10,
                sugars: 1,
                protein: 2,
                sodium: 30,
                carbohydrates: 15,
                vitaminB: 20,
                iron: 10,
                fiber: 2.5,
                fruitsVegetablesNuts: 90
                ))
        ),
        Product(
            id: UUID(),
            name: "Croissant",
            imageURL: "croissant",
            ingredients: [
                Ingredients["Wheat Flour"]!,
                Ingredients["Butter"]!,
                Ingredients["Milk"]!,
                Ingredients["Sugar"]!,
                Ingredients["Yeast"]!,
                Ingredients["Salt"]!
            ],
            nutritionInfo: NutritionInfo(
                energy: 406,
                fats: 21.0,
                sugars: 4.5,
                protein: 8.2,
                sodium: 0.32,
                carbohydrates: 45,
                vitaminB: 10,
                iron: 0.8,
                fiber: 2.0,
                fruitsVegetablesNuts: 0
            ),
            userRating: 4.2,
            numberOfRatings: 95,
            categoryId: Categories[0].id,
            pros: [
                "Source of quick energy due to carbohydrates.",
                "Pairs well with both sweet and savory toppings."
            ],
            cons: [
                "High in saturated fats due to butter content.",
                "Low in fiber compared to whole grain options.",
            ],
            healthScore: Product.calculateHealthScore(from: NutritionInfo(
                energy: 406,
                fats: 21.0,
                sugars: 4.5,
                protein: 8.2,
                sodium: 0.32,
                carbohydrates: 45,
                vitaminB: 10,
                iron: 0.8,
                fiber: 2.0,
                fruitsVegetablesNuts: 0
                ))
        ),
        Product(
            id: UUID(),
            name: "Blueberry Muffin",
            imageURL: "muffin",
            ingredients: [
                Ingredients["Wheat Flour"]!,
                Ingredients["Blueberries"]!,
                Ingredients["Sugar"]!,
                Ingredients["Eggs"]!,
                Ingredients["Butter"]!,
                Ingredients["Baking Powder"]!,
                Ingredients["Vanilla Extract"]!
            ],
            nutritionInfo: NutritionInfo(
                energy: 425,
                fats: 14.0,
                sugars: 33.0,
                protein: 5.0,
                sodium: 0.3,
                carbohydrates: 65,
                vitaminB: 5,
                iron: 1.5,
                fiber: 1.0,
                fruitsVegetablesNuts: 10
            ),
            userRating: 4.7,
            numberOfRatings: 230,
            categoryId: Categories[0].id,
            pros: [
                "Fresh blueberries provide antioxidants and natural sweetness.",
                "Contains small amounts of vitamins and minerals."
            ],
            cons: [
                "High in sugar, which can contribute to weight gain.",
                "Low in protein and fiber compared to healthier snacks.",
            ],
            healthScore: Product.calculateHealthScore(from: NutritionInfo(
                energy: 425,
                fats: 14.0,
                sugars: 33.0,
                protein: 5.0,
                sodium: 0.3,
                carbohydrates: 65,
                vitaminB: 5,
                iron: 1.5,
                fiber: 1.0,
                fruitsVegetablesNuts: 10
                ))
        ),
        Product(
            id: UUID(),
            name: "Chocolate Cookie",
            imageURL: "cookie",
            ingredients: [
                Ingredients["Wheat Flour"]!,
                Ingredients["Chocolate Chips"]!,
                Ingredients["Sugar"]!,
                Ingredients["Butter"]!,
                Ingredients["Eggs"]!,
                Ingredients["Vanilla Extract"]!,
                Ingredients["Baking Soda"]!
            ],            nutritionInfo: NutritionInfo(
                energy: 450,
                fats: 20.0,
                sugars: 40.0,
                protein: 4.0,
                sodium: 0.2,
                carbohydrates: 60,
                vitaminB: 2,
                iron: 1.0,
                fiber: 1.5,
                fruitsVegetablesNuts: 0
            ),
            userRating: 4.8,
            numberOfRatings: 350,
            categoryId: Categories[0].id,
            pros: [
                "Great for quick energy boosts.",
            ],
            cons: [
                "High in sugar and saturated fats.",
                "Not a nutritious choice for regular consumption.",
                "Lacks significant vitamins or minerals."
            ],
            healthScore: Product.calculateHealthScore(from: NutritionInfo(
                energy: 450,
                fats: 20.0,
                sugars: 40.0,
                protein: 4.0,
                sodium: 0.2,
                carbohydrates: 60,
                vitaminB: 2,
                iron: 1.0,
                fiber: 1.5,
                fruitsVegetablesNuts: 0
                ))
        ),
        Product(
            id: UUID(),
            name: "Banana Bread",
            imageURL: "banana",
            ingredients: [
                Ingredients["Bananas"]!,
                Ingredients["Wheat Flour"]!,
                Ingredients["Sugar"]!,
                Ingredients["Eggs"]!,
                Ingredients["Butter"]!,
                Ingredients["Baking Powder"]!,
                Ingredients["Cinnamon"]!
            ],
            nutritionInfo: NutritionInfo(
                energy: 305,
                fats: 10.0,
                sugars: 27.0,
                protein: 4.2,
                sodium: 0.15,
                carbohydrates: 48,
                vitaminB: 12,
                iron: 1.8,
                fiber: 2.5,
                fruitsVegetablesNuts: 15
            ),
            userRating: 4.6,
            numberOfRatings: 150,
            categoryId: Categories[0].id,
            pros: [
                "Contains cinnamon, which adds a warm flavor and antioxidants."

            ],
            cons: [
                "Moderate sugar content.",
                "Not gluten-free.",
                "Low in fiber compared to multigrain options."
            ],
            healthScore: Product.calculateHealthScore(from: NutritionInfo(
                energy: 305,
                fats: 10.0,
                sugars: 27.0,
                protein: 4.2,
                sodium: 0.15,
                carbohydrates: 48,
                vitaminB: 12,
                iron: 1.8,
                fiber: 2.5,
                fruitsVegetablesNuts: 15
            ))
        ),
    Product(
        id: UUID(),
        name: "Peanut Butter",
        imageURL: "peanut",
        ingredients: [Ingredients["Sugar"]!, Ingredients["Salt"]!],
        nutritionInfo: NutritionInfo(
            energy: 90,
            fats: 10,
            sugars: 1,
            protein: 2,
            sodium: 30,
            carbohydrates: 15,
            vitaminB: 20,
            iron: 10,
            fiber: 2.5,
            fruitsVegetablesNuts: 90
        ),
        userRating: 4.8,
        numberOfRatings: 240,
        categoryId: Categories[2].id,
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
                energy: 90,
                fats: 10,
                sugars: 1,
                protein: 2,
                sodium: 30,
                carbohydrates: 15,
                vitaminB: 20,
                iron: 10,
                fiber: 2.5,
                fruitsVegetablesNuts: 90

        ))
    ),
    Product(
        id: UUID(),
        name: "Soybean Oil",
        imageURL: "soybean",
        ingredients: [Ingredients["Soybean Oil"]!],

        nutritionInfo: NutritionInfo(
            energy: 90,
            fats: 14,
            sugars: 0,
            protein: 0,
            sodium: 0,
            carbohydrates: 0,
            vitaminB: 20,
            iron: 10,
            fiber: 2.5,
            fruitsVegetablesNuts: 90
        ),
        userRating: 3.5,
        numberOfRatings: 200,
        categoryId: Categories[2].id,
        pros: [
             "High in plant-based protein",
             "Contains essential vitamins and minerals"
         ],
         cons: [
             "Contains tree nuts (almonds), which are a common allergen",
             "Relatively high in natural sugars from dates"
         ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 90,
            fats: 14,
            sugars: 0,
            protein: 0,
            sodium: 0,
            carbohydrates: 0,
            vitaminB: 20,
            iron: 10,
            fiber: 2.5,
            fruitsVegetablesNuts: 90
        ))
    ),
    Product(
        id: UUID(),
        name: "Potato Chips",
        imageURL: "potato",
        ingredients: [Ingredients["Salt"]!],
        nutritionInfo: NutritionInfo(
            energy: 90,
            fats: 10,
            sugars: 1,
            protein: 2,
            sodium: 30,
            carbohydrates: 15,
            vitaminB: 20,
            iron: 10,
            fiber: 2.5,
            fruitsVegetablesNuts: 90
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
         ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 90,
            fats: 10,
            sugars: 1,
            protein: 2,
            sodium: 30,
            carbohydrates: 15,
            vitaminB: 20,
            iron: 10,
            fiber: 2.5,
            fruitsVegetablesNuts: 90
        ))
    ),
    Product(
        id: UUID(),
        name: "Milk",
        imageURL: "milk",
        ingredients: [],
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
        userRating: 4.5,
        numberOfRatings: 170,
        categoryId: Categories[2].id,
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
    ),Product(
        id: UUID(),
        name: "Oats",
        imageURL: "oats",
        ingredients: [Ingredients["Rolled Oats"]!],
        nutritionInfo: NutritionInfo(
            energy: 380,
            fats: 12.5,
            sugars: 1.0,
            protein: 13.0,
            sodium: 0,
            carbohydrates: 68.0,
            vitaminB: 0,
            iron: 3.6,
            fiber: 10.0,
            fruitsVegetablesNuts: 0
        ),
        userRating: 4.6,
        numberOfRatings: 120,
        categoryId: Categories[3].id,
        pros: [
            "High in dietary fiber",
            "Low in sugar",
            "Good source of plant-based protein"
        ],
        cons: [
            "Requires cooking/preparation time",
            "Bland taste without additional flavoring"
        ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 380,
            fats: 12.5,
            sugars: 1.0,
            protein: 13.0,
            sodium: 0,
            carbohydrates: 68.0,
            vitaminB: 0,
            iron: 3.6,
            fiber: 10.0,
            fruitsVegetablesNuts: 0
        ))
    ),
    Product(
        id: UUID(),
        name: "Cornflakes",
        imageURL: "flakes",
        ingredients: [Ingredients["Corn"]!, Ingredients["Sugar"]!, Ingredients["Salt"]!],
        nutritionInfo: NutritionInfo(
            energy: 370,
            fats: 4.4,
            sugars: 8.0,
            protein: 7.0,
            sodium: 10,
            carbohydrates: 4.0,
            vitaminB: 25,
            iron: 5.0,
            fiber: 3.0,
            fruitsVegetablesNuts: 0
        ),
        userRating: 4.3,
        numberOfRatings: 80,
        categoryId: Categories[3].id,
        pros: [
            "Quick and convenient",
            "Fortified with essential vitamins"
        ],
        cons: [
            "High in sodium",
            "Contains added sugar"
        ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 370,
            fats: 10.4,
            sugars: 8.0,
            protein: 7.0,
            sodium: 200,
            carbohydrates: 84.0,
            vitaminB: 25,
            iron: 5.0,
            fiber: 3.0,
            fruitsVegetablesNuts: 0
        ))
    ),
    Product(
        id: UUID(),
        name: "Pancake Mix",
        imageURL: "pancake",
        ingredients: [Ingredients["Flour"]!, Ingredients["Sugar"]!, Ingredients["Baking Powder"]!],
        nutritionInfo: NutritionInfo(
            energy: 350,
            fats: 10.0,
            sugars: 20.0,
            protein: 18.0,
            sodium: 600,
            carbohydrates: 80.0,
            vitaminB: 0,
            iron: 2.0,
            fiber: 1.5,
            fruitsVegetablesNuts: 0
        ),
        userRating: 4.0,
        numberOfRatings: 65,
        categoryId: Categories[3].id,
        pros: [
            "Easy to prepare",
            "Great taste"
        ],
        cons: [
            "High in sugar and sodium",
            "Low in fiber"
        ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 350,
            fats: 10.0,
            sugars: 20.0,
            protein: 31.0,
            sodium: 600,
            carbohydrates: 80.0,
            vitaminB: 0,
            iron: 2.0,
            fiber: 1.5,
            fruitsVegetablesNuts: 0
        ))
    ),
    Product(
        id: UUID(),
        name: "Granola Bar",
        imageURL: "granola",
        ingredients: [Ingredients["Oats"]!, Ingredients["Honey"]!, Ingredients["Almonds"]!],
        nutritionInfo: NutritionInfo(
            energy: 450,
            fats: 15.0,
            sugars: 20.0,
            protein: 31.0,
            sodium: 100,
            carbohydrates: 65.0,
            vitaminB: 0,
            iron: 3.0,
            fiber: 5.0,
            fruitsVegetablesNuts: 15
        ),
        userRating: 4.4,
        numberOfRatings: 90,
        categoryId: Categories[3].id,
        pros: [
            "Rich in fiber",
            "Good source of healthy fats"
        ],
        cons: [
            "High in sugar",
            "May contain allergens (nuts)"
        ],
        healthScore: Product.calculateHealthScore(from: NutritionInfo(
            energy: 450,
            fats: 15.0,
            sugars: 20.0,
            protein: 8.0,
            sodium: 100,
            carbohydrates: 65.0,
            vitaminB: 0,
            iron: 3.0,
            fiber: 5.0,
            fruitsVegetablesNuts: 15
        ))
    ),Product(
        id: UUID(),
        name: "Cheddar Cheese",
        imageURL: "cheddar",
        ingredients: [Ingredients["Milk"]!, Ingredients["Salt"]!, Ingredients["Enzymes"]!],
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
        name: "Yogurt",
        imageURL: "yogurt",
        ingredients: [Ingredients["Milk"]!, Ingredients["Live Cultures"]!],
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
        name: "Butter",
        imageURL: "butter",
        ingredients: [Ingredients["Cream"]!, Ingredients["Salt"]!],
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
let sampleUser = User(
    id: UUID(),
    name: "Arjun",
    dietaryRestrictions: [.glutenFree, .dairyFree],
    allergies: [.peanuts, .wheat],
    picksforyou:  [sampleProducts[3], sampleProducts[9], sampleProducts[3]],
    recentlyViewedProducts: [sampleProducts[12],sampleProducts[2],sampleProducts[4],sampleProducts[7]],
    ratings: [UUID(): 4,UUID(): 5]
)

// MARK: - Sample Saved Lists
var sampleLists: [SavedList] = [
    SavedList(
        id: UUID(),
        name: "Snacks",
        products: [
            sampleProducts[10],
            sampleProducts[11],
            sampleProducts[12]
        ],
        iconName: UIImage(systemName: "popcorn")!
    ),
    SavedList(
        id: UUID(),
        name: "Healthy choices",
        products: [
            sampleProducts[0],
            sampleProducts[8],
            sampleProducts[3],
        ],
        iconName: UIImage(systemName: "heart")!
    ),
    SavedList(
        id: UUID(),
        name: "Workout",
        products: [
            sampleProducts[2],
            sampleProducts[1],
            sampleProducts[6],
        ],
        iconName: UIImage(systemName: "figure.run")!
    ),SavedList(
        id: UUID(),
        name: "Kids",
        products: [
            sampleProducts[9],
            sampleProducts[7],
            sampleProducts[4],
        ],
        iconName: UIImage(systemName: "figure.2.and.child.holdinghands")!
    )
]
let randomlistImages = [
    "leaf", "carrot", "fork.knife", "cart", "cup.and.saucer",
               "takeoutbag.and.cup.and.straw", "popcorn", "flame", "applelogo",
               "fork.knife.circle", "heart", "heart.circle", "staroflife",
               "cross.case", "pills", "figure.walk", "figure.walk.circle",
               "figure.run", "figure.strengthtraining.traditional", "bandage"
]
