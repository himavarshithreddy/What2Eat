import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Struct to hold split components of pros and cons
struct NutrientFeedback:Codable {
    let summaryPoint: String
    let value: Int
    let message: String
}

struct ProductAnalysis:Codable {
    let pros: [NutrientFeedback]
    let cons: [NutrientFeedback]
}

// Function to calculate RDA based on user profile
func getRDA(for user: Users) -> [String: Double] {
    let isMale = user.gender.lowercased() == "male"
    let age = user.age
    let weight = user.weight
    let activity = user.activityLevel.lowercased()
    var rda: [String: Double] = [:]
    
    if age >= 19 {
        if isMale {
            switch activity {
            case "sedentary": rda["energy"] = 32 * weight
            case "moderate": rda["energy"] = 42 * weight
            case "heavy": rda["energy"] = 53 * weight
            default: rda["energy"] = 42 * weight
            }
        } else {
            switch activity {
            case "sedentary": rda["energy"] = 30 * weight
            case "moderate": rda["energy"] = 39 * weight
            case "heavy": rda["energy"] = 49 * weight
            default: rda["energy"] = 39 * weight
            }
        }
    } else if age >= 16 && age <= 18 {
        rda["energy"] = isMale ? 52 * weight : 45 * weight
    } else if age >= 13 && age <= 15 {
        rda["energy"] = isMale ? 57 * weight : 49 * weight
    } else if age >= 10 && age <= 12 {
        rda["energy"] = isMale ? 64 * weight : 57 * weight
    } else if age >= 7 && age <= 9 {
        rda["energy"] = 67 * weight
    } else if age >= 4 && age <= 6 {
        rda["energy"] = 74 * weight
    } else if age >= 1 && age <= 3 {
        rda["energy"] = 83 * weight
    } else if age >= 0 {
        rda["energy"] = (age < 1) ? 90 * weight : 80 * weight
    }
    
    if age >= 19 {
        rda["protein"] = 0.83 * weight
    } else if age >= 16 && age <= 18 {
        rda["protein"] = isMale ? 0.86 * weight : 0.83 * weight
    } else if age >= 13 && age <= 15 {
        rda["protein"] = isMale ? 0.89 * weight : 0.87 * weight
    } else if age >= 10 && age <= 12 {
        rda["protein"] = isMale ? 0.91 * weight : 0.90 * weight
    } else if age >= 7 && age <= 9 {
        rda["protein"] = 0.92 * weight
    } else if age >= 4 && age <= 6 {
        rda["protein"] = 0.87 * weight
    } else if age >= 1 && age <= 3 {
        rda["protein"] = 0.97 * weight
    } else if age >= 0 {
        rda["protein"] = (age < 1) ? 1.40 * weight : 1.23 * weight
    }
    
    rda["total fat"] = (rda["energy"]! * 0.25) / 9
    rda["saturated fat"] = (rda["energy"]! * 0.10) / 9
    rda["carbohydrates"] = (rda["energy"]! * 0.60) / 4
    rda["fiber"] = (rda["energy"]! / 2000) * 30
    rda["sugars"] = (rda["energy"]! * 0.10) / 4
    
    rda["calcium"] = age >= 19 ? 1000 : 800
    rda["magnesium"] = isMale ? (age >= 19 ? 440 : 340) : (age >= 19 ? 370 : 310)
    rda["iron"] = isMale ? (age >= 19 ? 19 : 16) : (age >= 19 ? 29 : 18)
    rda["zinc"] = isMale ? (age >= 19 ? 17 : 11) : (age >= 19 ? 13 : 8)
    rda["iodine"] = 150
    rda["sodium"] = age >= 19 ? 2000 : 1500
    rda["potassium"] = 3500
    rda["phosphorus"] = 700
    rda["copper"] = 0.9
    rda["selenium"] = 55
    
    rda["vitamin a"] = isMale ? (age >= 19 ? 1000 : 900) : (age >= 19 ? 840 : 700)
    rda["vitamin c"] = isMale ? (age >= 19 ? 80 : 65) : (age >= 19 ? 65 : 55)
    rda["vitamin d"] = 15
    rda["thiamine"] = isMale ? (age >= 19 ? 1.8 : 1.2) : (age >= 19 ? 1.7 : 1.1)
    rda["riboflavin"] = isMale ? (age >= 19 ? 2.5 : 1.6) : (age >= 19 ? 2.4 : 1.3)
    rda["niacin"] = isMale ? (age >= 19 ? 18 : 16) : (age >= 19 ? 14 : 12)
    rda["vitamin b6"] = isMale ? (age >= 19 ? 2.4 : 1.3) : (age >= 19 ? 1.9 : 1.3)
    rda["folate"] = isMale ? (age >= 19 ? 300 : 200) : (age >= 19 ? 220 : 180)
    rda["vitamin b12"] = age >= 19 ? 2.2 : 2.0
    rda["vitamin e"] = 15
    
    return rda
}

func generateProsAndCons(product: ProductResponse, user: Users) -> ProductAnalysis {
    let rda = getRDA(for: user)
    var pros: [NutrientFeedback] = []
    var cons: [NutrientFeedback] = []
    
    // Helper function to calculate percentage of DV/RDA
    func calculatePercentage(nutrient: Nutrition, rdaValue: Double) -> Double {
        var value = Double(nutrient.value)
        switch nutrient.unit.lowercased() {
        case "mg":
            if ["calcium", "magnesium", "iron", "zinc", "sodium", "potassium", "phosphorus", "vitamin c", "thiamine", "riboflavin", "niacin", "vitamin b6", "vitamin e"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000
            }
        case "mcg", "μg":
            if ["iodine", "vitamin a", "vitamin d", "folate", "vitamin b12", "selenium", "copper"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000
            }
        case "g":
            if ["protein", "total fat", "saturated fat", "carbohydrates", "fiber", "sugars"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value *= 1000
            }
        case "kcal":
            break
        default:
            break
        }
        return (value / rdaValue) * 100
    }
    
    // Dictionary mapping nutrient names to evaluation closures with only low and high thresholds
    let evaluationRules: [String: (Double) -> ([NutrientFeedback], [NutrientFeedback])] = [
        "energy": { percentage in
            if percentage >= 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of calories", value: (Int(percentage)), message: "may be too energy-dense for a snack")])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of calories", value: (Int(percentage)), message: "light option but may not sustain you")])
            }
            return ([], [])
        },
        "protein": { percentage in
            if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a low amount of protein", value: (Int(percentage)), message: "may not sustain energy")])
            } else if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in protein", value: (Int(percentage)), message: "supports muscle health")], [])
            }
            return ([], [])
        },
        "total fat": { percentage in
            if percentage >= 25 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of fat", value: (Int(percentage)), message: "consider moderation")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Has a low amount of fat", value: (Int(percentage)), message: "heart-healthy but may lack richness")], [])
            }
            return ([], [])
        },
        "saturated fat": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of saturated fat", value: (Int(percentage)), message: "limit intake")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Low in saturated fat", value: (Int(percentage)), message: "heart-friendly")], [])
            }
            return ([], [])
        },
        "carbohydrates": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in carbohydrates", value: (Int(percentage)), message: "provides energy")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of carbs", value: (Int(percentage)), message: "may lack energy")])
            }
            return ([], [])
        },
        "fiber": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in fiber", value: (Int(percentage)), message: "aids digestion")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in fiber", value: (Int(percentage)), message: "may not support digestion")])
            }
            return ([], [])
        },
        "sugars": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sugar", value: (Int(percentage)), message: "limit consumption")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Low in sugar", value: (Int(percentage)), message: "suits your goals")], [])
            }
            return ([], [])
        },
        "sodium": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: (Int(percentage)), message: "watch intake")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Low in sodium", value: (Int(percentage)), message: "heart-friendly")], [])
            }
            return ([], [])
        },
        "calcium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in calcium", value: (Int(percentage)), message: "supports bones")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in calcium", value: (Int(percentage)), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "magnesium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in magnesium", value: (Int(percentage)), message: "aids muscle function")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in magnesium", value: (Int(percentage)), message: "may impact energy")])
            }
            return ([], [])
        },
        "iron": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in iron", value: (Int(percentage)), message: "supports blood health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iron", value: (Int(percentage)), message: "may impact oxygen transport")])
            }
            return ([], [])
        },
        "zinc": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in zinc", value: (Int(percentage)), message: "boosts immunity")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in zinc", value: (Int(percentage)), message: "may weaken immune function")])
            }
            return ([], [])
        },
        "iodine": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in iodine", value: (Int(percentage)), message: "supports thyroid function")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iodine", value: (Int(percentage)), message: "may affect thyroid function")])
            }
            return ([], [])
        },
        "potassium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in potassium", value: (Int(percentage)), message: "supports blood pressure")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in potassium", value: (Int(percentage)), message: "may affect muscle function")])
            }
            return ([], [])
        },
        "phosphorus": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in phosphorus", value: (Int(percentage)), message: "supports bone health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in phosphorus", value: (Int(percentage)), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "copper": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in copper", value: (Int(percentage)), message: "supports metabolism")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in copper", value: (Int(percentage)), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "selenium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in selenium", value: (Int(percentage)), message: "offers antioxidant benefits")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in selenium", value: (Int(percentage)), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "vitamin a": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin A", value: (Int(percentage)), message: "aids vision")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin A", value: (Int(percentage)), message: "may affect vision")])
            }
            return ([], [])
        },
        "vitamin c": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin C", value: (Int(percentage)), message: "boosts immunity")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin C", value: (Int(percentage)), message: "limited immune support")])
            }
            return ([], [])
        },
        "vitamin d": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin D", value: (Int(percentage)), message: "supports bones")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin D", value: (Int(percentage)), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "vitamin e": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin E", value: (Int(percentage)), message: "offers antioxidant benefits")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin E", value: (Int(percentage)), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "thiamine": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in thiamine", value: (Int(percentage)), message: "supports energy metabolism")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in thiamine", value: (Int(percentage)), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "riboflavin": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in riboflavin", value: (Int(percentage)), message: "aids metabolism")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in riboflavin", value: (Int(percentage)), message: "may impact energy")])
            }
            return ([], [])
        },
        "niacin": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in niacin", value: (Int(percentage)), message: "supports digestion")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in niacin", value: (Int(percentage)), message: "may affect digestion")])
            }
            return ([], [])
        },
        "vitamin b6": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B6", value: (Int(percentage)), message: "aids brain health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B6", value: (Int(percentage)), message: "may impact mood")])
            }
            return ([], [])
        },
        "folate": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in folate", value: (Int(percentage)), message: "supports cell growth")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in folate", value: (Int(percentage)), message: "may affect cell function")])
            }
            return ([], [])
        },
        "vitamin b12": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B12", value: (Int(percentage)), message: "supports nerve health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B12", value: (Int(percentage)), message: "may affect nerve health")])
            }
            return ([], [])
        }
    ]
    
    // Process each nutrient in the product
    for nutrient in product.nutrition {
        let nutrientKey = nutrient.name.lowercased()
        guard let rdaValue = rda[nutrientKey] else { continue }
        let percentageOfRDA = calculatePercentage(nutrient: nutrient, rdaValue: rdaValue)
        
        if let evaluator = evaluationRules[nutrientKey] {
            let (nutrientPros, nutrientCons) = evaluator(percentageOfRDA)
            pros.append(contentsOf: nutrientPros)
            cons.append(contentsOf: nutrientCons)
        }
    }
    
    // Fallback messages
    if pros.isEmpty {
        pros.append(NutrientFeedback(summaryPoint: "Contains some nutrients", value: 0, message: "help meet your daily needs"))
        if let energy = product.nutrition.first(where: { $0.name.lowercased() == "energy" }),
           let energyRDA = rda["energy"] {
            let percentage = calculatePercentage(nutrient: energy, rdaValue: energyRDA)
            if percentage >= 20 {
                pros.append(NutrientFeedback(summaryPoint: "Provides a high amount of energy", value: (Int(percentage)), message: "great for a boost"))
            }
        }
    }
    if cons.isEmpty {
        cons.append(NutrientFeedback(summaryPoint: "No major concerns detected", value: 0, message: "for your profile"))
        if let sodium = product.nutrition.first(where: { $0.name.lowercased() == "sodium" }),
           let sodiumRDA = rda["sodium"] {
            let percentage = calculatePercentage(nutrient: sodium, rdaValue: sodiumRDA)
            if percentage > 20 {
                cons.append(NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: (Int(percentage)), message: "use with caution if frequent"))
            }
        }
    }
    
    return ProductAnalysis(pros: pros, cons: cons)
}
func generateProsAndCons(product: ProductData, user: Users) -> ProductAnalysis {
    let rda = getRDA(for: user)
    var pros: [NutrientFeedback] = []
    var cons: [NutrientFeedback] = []
    
    // Helper function to calculate percentage of DV/RDA
    func calculatePercentage(nutrient: Nutrition, rdaValue: Double) -> Double {
        var value = Double(nutrient.value)
        switch nutrient.unit.lowercased() {
        case "mg":
            if ["calcium", "magnesium", "iron", "zinc", "sodium", "potassium", "phosphorus", "vitamin c", "thiamine", "riboflavin", "niacin", "vitamin b6", "vitamin e"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000
            }
        case "mcg", "μg":
            if ["iodine", "vitamin a", "vitamin d", "folate", "vitamin b12", "selenium", "copper"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000
            }
        case "g":
            if ["protein", "total fat", "saturated fat", "carbohydrates", "fiber", "sugars"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value *= 1000
            }
        case "kcal":
            break
        default:
            break
        }
        return (value / rdaValue) * 100
    }
    
    // Dictionary mapping nutrient names to evaluation closures with only low and high thresholds
    let evaluationRules: [String: (Double) -> ([NutrientFeedback], [NutrientFeedback])] = [
        "energy": { percentage in
            if percentage >= 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of calories", value: (Int(percentage)), message: "may be too energy-dense for a snack")])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of calories", value: (Int(percentage)), message: "light option but may not sustain you")])
            }
            return ([], [])
        },
        "protein": { percentage in
            if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a low amount of protein", value: (Int(percentage)), message: "may not sustain energy")])
            } else if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in protein", value: (Int(percentage)), message: "supports muscle health")], [])
            }
            return ([], [])
        },
        "total fat": { percentage in
            if percentage >= 25 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of fat", value: (Int(percentage)), message: "consider moderation")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Has a low amount of fat", value: (Int(percentage)), message: "heart-healthy but may lack richness")], [])
            }
            return ([], [])
        },
        "saturated fat": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of saturated fat", value: (Int(percentage)), message: "limit intake")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Low in saturated fat", value: (Int(percentage)), message: "heart-friendly")], [])
            }
            return ([], [])
        },
        "carbohydrates": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in carbohydrates", value: (Int(percentage)), message: "provides energy")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of carbs", value: (Int(percentage)), message: "may lack energy")])
            }
            return ([], [])
        },
        "fiber": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in fiber", value: (Int(percentage)), message: "aids digestion")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in fiber", value: (Int(percentage)), message: "may not support digestion")])
            }
            return ([], [])
        },
        "sugars": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sugar", value: (Int(percentage)), message: "limit consumption")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Low in sugar", value: (Int(percentage)), message: "suits your goals")], [])
            }
            return ([], [])
        },
        "sodium": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: (Int(percentage)), message: "watch intake")])
            } else if percentage < 5 && percentage > 0 {
                return ([NutrientFeedback(summaryPoint: "Low in sodium", value: (Int(percentage)), message: "heart-friendly")], [])
            }
            return ([], [])
        },
        "calcium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in calcium", value: (Int(percentage)), message: "supports bones")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in calcium", value: (Int(percentage)), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "magnesium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in magnesium", value: (Int(percentage)), message: "aids muscle function")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in magnesium", value: (Int(percentage)), message: "may impact energy")])
            }
            return ([], [])
        },
        "iron": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in iron", value: (Int(percentage)), message: "supports blood health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iron", value: (Int(percentage)), message: "may impact oxygen transport")])
            }
            return ([], [])
        },
        "zinc": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in zinc", value: (Int(percentage)), message: "boosts immunity")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in zinc", value: (Int(percentage)), message: "may weaken immune function")])
            }
            return ([], [])
        },
        "iodine": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in iodine", value: (Int(percentage)), message: "supports thyroid function")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iodine", value: (Int(percentage)), message: "may affect thyroid function")])
            }
            return ([], [])
        },
        "potassium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in potassium", value: (Int(percentage)), message: "supports blood pressure")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in potassium", value: (Int(percentage)), message: "may affect muscle function")])
            }
            return ([], [])
        },
        "phosphorus": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in phosphorus", value: (Int(percentage)), message: "supports bone health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in phosphorus", value: (Int(percentage)), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "copper": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in copper", value: (Int(percentage)), message: "supports metabolism")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in copper", value: (Int(percentage)), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "selenium": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in selenium", value: (Int(percentage)), message: "offers antioxidant benefits")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in selenium", value: (Int(percentage)), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "vitamin a": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin A", value: (Int(percentage)), message: "aids vision")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin A", value: (Int(percentage)), message: "may affect vision")])
            }
            return ([], [])
        },
        "vitamin c": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin C", value: (Int(percentage)), message: "boosts immunity")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin C", value: (Int(percentage)), message: "limited immune support")])
            }
            return ([], [])
        },
        "vitamin d": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin D", value: (Int(percentage)), message: "supports bones")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin D", value: (Int(percentage)), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "vitamin e": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin E", value: (Int(percentage)), message: "offers antioxidant benefits")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin E", value: (Int(percentage)), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "thiamine": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in thiamine", value: (Int(percentage)), message: "supports energy metabolism")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in thiamine", value: (Int(percentage)), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "riboflavin": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in riboflavin", value: (Int(percentage)), message: "aids metabolism")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in riboflavin", value: (Int(percentage)), message: "may impact energy")])
            }
            return ([], [])
        },
        "niacin": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in niacin", value: (Int(percentage)), message: "supports digestion")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in niacin", value: (Int(percentage)), message: "may affect digestion")])
            }
            return ([], [])
        },
        "vitamin b6": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B6", value: (Int(percentage)), message: "aids brain health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B6", value: (Int(percentage)), message: "may impact mood")])
            }
            return ([], [])
        },
        "folate": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in folate", value: (Int(percentage)), message: "supports cell growth")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in folate", value: (Int(percentage)), message: "may affect cell function")])
            }
            return ([], [])
        },
        "vitamin b12": { percentage in
            if percentage >= 20 {
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B12", value: (Int(percentage)), message: "supports nerve health")], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B12", value: (Int(percentage)), message: "may affect nerve health")])
            }
            return ([], [])
        }
    ]
    
    // Process each nutrient in the product
    for nutrient in product.nutritionInfo {
        let nutrientKey = nutrient.name.lowercased()
        guard let rdaValue = rda[nutrientKey] else { continue }
        let percentageOfRDA = calculatePercentage(nutrient: nutrient, rdaValue: rdaValue)
        
        if let evaluator = evaluationRules[nutrientKey] {
            let (nutrientPros, nutrientCons) = evaluator(percentageOfRDA)
            pros.append(contentsOf: nutrientPros)
            cons.append(contentsOf: nutrientCons)
        }
    }
    
    // Fallback messages
    if pros.isEmpty {
        pros.append(NutrientFeedback(summaryPoint: "Contains some nutrients", value: 0, message: "help meet your daily needs"))
        if let energy = product.nutritionInfo.first(where: { $0.name.lowercased() == "energy" }),
           let energyRDA = rda["energy"] {
            let percentage = calculatePercentage(nutrient: energy, rdaValue: energyRDA)
            if percentage >= 20 {
                pros.append(NutrientFeedback(summaryPoint: "Provides a high amount of energy", value: (Int(percentage)), message: "great for a boost"))
            }
        }
    }
    if cons.isEmpty {
        cons.append(NutrientFeedback(summaryPoint: "No major concerns detected", value: 0, message: "for your profile"))
        if let sodium = product.nutritionInfo.first(where: { $0.name.lowercased() == "sodium" }),
           let sodiumRDA = rda["sodium"] {
            let percentage = calculatePercentage(nutrient: sodium, rdaValue: sodiumRDA)
            if percentage > 20 {
                cons.append(NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: (Int(percentage)), message: "use with caution if frequent"))
            }
        }
    }
    
    return ProductAnalysis(pros: pros, cons: cons)
}
 func fetchUserData(completion: @escaping (Users?) -> Void) {
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(Users.self, from: userData)
                completion(user)
                return
            } catch {
                print("Error decoding user from UserDefaults: \(error.localizedDescription)")
            }
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(nil)
                return
            }
            
            let user = Users(
                name: data["name"] as? String ?? "",
                dietaryRestrictions: data["dietaryRestrictions"] as? [String] ?? [],
                allergies: data["allergies"] as? [String] ?? [],
                gender: data["gender"] as? String ?? "",
                age: data["age"] as? Int ?? 0,
                weight: data["weight"] as? Double ?? 0.0,
                height: data["height"] as? Double ?? 0.0,
                activityLevel: data["activityLevel"] as? String ?? ""
            )
            
            do {
                let encoder = JSONEncoder()
                let encodedUser = try encoder.encode(user)
                UserDefaults.standard.set(encodedUser, forKey: "currentUser")
            } catch {
                print("Error encoding user to UserDefaults: \(error.localizedDescription)")
            }
            
            completion(user)
        }
    }

// New function to calculate RDA percentages for all nutrients
func getRDAPercentages(product: ProductResponse, user: Users) -> [String: Double] {
    let rda = getRDA(for: user)
    var percentages: [String: Double] = [:]
    
    // Helper function to calculate percentage of DV/RDA (reused from your code)
    func calculatePercentage(nutrient: Nutrition, rdaValue: Double) -> Double {
        var value = Double(nutrient.value)
        switch nutrient.unit.lowercased() {
        case "mg":
            if ["calcium", "magnesium", "iron", "zinc", "sodium", "potassium", "phosphorus", "vitamin c", "thiamine", "riboflavin", "niacin", "vitamin b6", "vitamin e"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000 // Convert to grams if not in expected mg units
            }
        case "mcg", "μg":
            if ["iodine", "vitamin a", "vitamin d", "folate", "vitamin b12", "selenium", "copper"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000 // Convert to mg if not in expected mcg units
            }
        case "g":
            if ["protein", "total fat", "saturated fat", "carbohydrates", "fiber", "sugars"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value *= 1000 // Convert to mg if not in expected g units
            }
        case "kcal":
            break
        default:
            break
        }
        return (value / rdaValue) * 100
    }
    
    // Process each nutrient in the product
    for nutrient in product.nutrition {
        let nutrientKey = nutrient.name.lowercased()
        if let rdaValue = rda[nutrientKey] {
            let percentage = calculatePercentage(nutrient: nutrient, rdaValue: rdaValue)
            percentages[nutrientKey] = percentage
        }
    }
    
    return percentages
}

// Overloaded version for ProductData
func getRDAPercentages(product: ProductData, user: Users) -> [String: Double] {
    let rda = getRDA(for: user)
    var percentages: [String: Double] = [:]
    
    // Helper function to calculate percentage of DV/RDA (reused from your code)
    func calculatePercentage(nutrient: Nutrition, rdaValue: Double) -> Double {
        var value = Double(nutrient.value)
        switch nutrient.unit.lowercased() {
        case "mg":
            if ["calcium", "magnesium", "iron", "zinc", "sodium", "potassium", "phosphorus", "vitamin c", "thiamine", "riboflavin", "niacin", "vitamin b6", "vitamin e"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000
            }
        case "mcg", "μg":
            if ["iodine", "vitamin a", "vitamin d", "folate", "vitamin b12", "selenium", "copper"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value /= 1000
            }
        case "g":
            if ["protein", "total fat", "saturated fat", "carbohydrates", "fiber", "sugars"].contains(nutrient.name.lowercased()) {
                break
            } else {
                value *= 1000
            }
        case "kcal":
            break
        default:
            break
        }
        return (value / rdaValue) * 100
    }
    
    // Process each nutrient in the product
    for nutrient in product.nutritionInfo {
        let nutrientKey = nutrient.name.lowercased()
        if let rdaValue = rda[nutrientKey] {
            let percentage = calculatePercentage(nutrient: nutrient, rdaValue: rdaValue)
            percentages[nutrientKey] = percentage
        }
    }
    
    return percentages
}
