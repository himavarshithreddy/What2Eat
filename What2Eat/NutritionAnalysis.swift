import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Struct to hold split components of pros and cons
struct NutrientFeedback:Codable,Equatable {
    let summaryPoint: String
    let value: Float
    let message: String
}

struct ProductAnalysis:Codable {
    let pros: [NutrientFeedback]
    let cons: [NutrientFeedback]
}
func fetchAndComputeRDAWithUnits(completion: @escaping ([String: (value: Double, unit: String)]?) -> Void) {
    let nutrientUnits: [String: String] = [
        "energy": "kcal",
        "protein": "g",
        "total fat": "g",
        "saturated fat": "g",
        "carbohydrates": "g",
        "fiber": "g",
        "sugars": "g",
        "calcium": "mg",
        "magnesium": "mg",
        "iron": "mg",
        "zinc": "mg",
        "iodine": "mcg",
        "sodium": "mg",
        "potassium": "mg",
        "phosphorus": "mg",
        "copper": "mcg",
        "selenium": "mcg",
        "vitamin a": "mcg",
        "vitamin c": "mg",
        "vitamin d": "mcg",
        "thiamine": "mg",
        "riboflavin": "mg",
        "niacin": "mg",
        "vitamin b6": "mg",
        "folate": "mcg",
        "vitamin b12": "mcg",
        "vitamin e": "mg"
    ]
    
    fetchUserData { user in
        guard let user = user else {
            completion(nil) // Return nil if user data couldn't be fetched
            return
        }
        
        let rdaValues = getRDA(for: user)
        var rdaWithUnits: [String: (value: Double, unit: String)] = [:]
        
        for (key, value) in rdaValues {
            let unit = nutrientUnits[key] ?? ""
            rdaWithUnits[key] = (value, unit)
        }
        
        completion(rdaWithUnits)
    }
}


// Function to calculate RDA based on user profile
func getRDA(for user: Users) -> [String: Double] {
    let isMale = user.gender.lowercased() == "male"
    let age = user.age
    let weight = max(user.weight, 1.0)
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
    rda["carbohydrate"] = (rda["energy"]! * 0.60) / 4
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
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "provides a boost"
                return ([NutrientFeedback(summaryPoint: "High in energy", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of calories", value: Float(percentage), message: "light option but may not sustain you")])
            }
            return ([], [])
        },
        "protein": { percentage in
            if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a low amount of protein", value: Float(percentage), message: "may not sustain energy")])
            } else if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports muscle health"
                return ([NutrientFeedback(summaryPoint: "Rich in protein", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "total fat": { percentage in
            if percentage >= 25 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of fat", value: Float(percentage), message: "consider moderation")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "heart-healthy but may lack richness"
                return ([NutrientFeedback(summaryPoint: "Has a low amount of fat", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "saturated fat": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of saturated fat", value: Float(percentage), message: "limit intake")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "heart-friendly"
                return ([NutrientFeedback(summaryPoint: "Low in saturated fat", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "carbohydrates": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "provides energy"
                return ([NutrientFeedback(summaryPoint: "Rich in carbohydrates", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of carbs", value: Float(percentage), message: "may lack energy")])
            }
            return ([], [])
        },
        "fiber": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids digestion"
                return ([NutrientFeedback(summaryPoint: "Rich in fiber", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in fiber", value: Float(percentage), message: "may not support digestion")])
            }
            return ([], [])
        },
        "sugars": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sugar", value: Float(percentage), message: "limit consumption")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "suits your goals"
                return ([NutrientFeedback(summaryPoint: "Low in sugar", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "sodium": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: Float(percentage), message: "watch intake")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "heart-friendly"
                return ([NutrientFeedback(summaryPoint: "Low in sodium", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "calcium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports bones"
                return ([NutrientFeedback(summaryPoint: "Rich in calcium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in calcium", value: Float(percentage), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "magnesium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids muscle function"
                return ([NutrientFeedback(summaryPoint: "Rich in magnesium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in magnesium", value: Float(percentage), message: "may impact energy")])
            }
            return ([], [])
        },
        "iron": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports blood health"
                return ([NutrientFeedback(summaryPoint: "Rich in iron", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iron", value: Float(percentage), message: "may impact oxygen transport")])
            }
            return ([], [])
        },
        "zinc": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "boosts immunity"
                return ([NutrientFeedback(summaryPoint: "Rich in zinc", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in zinc", value: Float(percentage), message: "may weaken immune function")])
            }
            return ([], [])
        },
        "iodine": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports thyroid function"
                return ([NutrientFeedback(summaryPoint: "Rich in iodine", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iodine", value: Float(percentage), message: "may affect thyroid function")])
            }
            return ([], [])
        },
        "potassium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports blood pressure"
                return ([NutrientFeedback(summaryPoint: "Rich in potassium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in potassium", value: Float(percentage), message: "may affect muscle function")])
            }
            return ([], [])
        },
        "phosphorus": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports bone health"
                return ([NutrientFeedback(summaryPoint: "Rich in phosphorus", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in phosphorus", value: Float(percentage), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "copper": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports metabolism"
                return ([NutrientFeedback(summaryPoint: "Rich in copper", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in copper", value: Float(percentage), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "selenium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "offers antioxidant benefits"
                return ([NutrientFeedback(summaryPoint: "Rich in selenium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in selenium", value: Float(percentage), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "vitamin a": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids vision"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin A", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin A", value: Float(percentage), message: "may affect vision")])
            }
            return ([], [])
        },
        "vitamin c": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "boosts immunity"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin C", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin C", value: Float(percentage), message: "limited immune support")])
            }
            return ([], [])
        },
        "vitamin d": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports bones"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin D", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin D", value: Float(percentage), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "vitamin e": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "offers antioxidant benefits"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin E", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin E", value: Float(percentage), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "thiamine": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports energy metabolism"
                return ([NutrientFeedback(summaryPoint: "Rich in thiamine", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in thiamine", value: Float(percentage), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "riboflavin": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids metabolism"
                return ([NutrientFeedback(summaryPoint: "Rich in riboflavin", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in riboflavin", value: Float(percentage), message: "may impact energy")])
            }
            return ([], [])
        },
        "niacin": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports digestion"
                return ([NutrientFeedback(summaryPoint: "Rich in niacin", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in niacin", value: Float(percentage), message: "may affect digestion")])
            }
            return ([], [])
        },
        "vitamin b6": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids brain health"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B6", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B6", value: Float(percentage), message: "may impact mood")])
            }
            return ([], [])
        },
        "folate": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports cell growth"
                return ([NutrientFeedback(summaryPoint: "Rich in folate", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in folate", value: Float(percentage), message: "may affect cell function")])
            }
            return ([], [])
        },
        "vitamin b12": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports nerve health"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B12", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B12", value: Float(percentage), message: "may affect nerve health")])
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
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "great for a boost"
                pros.append(NutrientFeedback(summaryPoint: "Provides a high amount of energy", value: Float(percentage), message: message))
            }
        }
    }
    if cons.isEmpty {
        cons.append(NutrientFeedback(summaryPoint: "No major concerns detected", value: 0, message: "for your profile"))
        if let sodium = product.nutrition.first(where: { $0.name.lowercased() == "sodium" }),
           let sodiumRDA = rda["sodium"] {
            let percentage = calculatePercentage(nutrient: sodium, rdaValue: sodiumRDA)
            if percentage > 20 {
                cons.append(NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: Float(percentage), message: "use with caution if frequent"))
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
    
    // Dictionary mapping nutrient names to evaluation closures
    let evaluationRules: [String: (Double) -> ([NutrientFeedback], [NutrientFeedback])] = [
        "energy": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "provides a boost"
                return ([NutrientFeedback(summaryPoint: "High in energy", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of calories", value: Float(percentage), message: "light option but may not sustain you")])
            }
            return ([], [])
        },
        "protein": { percentage in
            if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a low amount of protein", value: Float(percentage), message: "may not sustain energy")])
            } else if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports muscle health"
                return ([NutrientFeedback(summaryPoint: "Rich in protein", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "total fat": { percentage in
            if percentage >= 25 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of fat", value: Float(percentage), message: "consider moderation")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "heart-healthy but may lack richness"
                return ([NutrientFeedback(summaryPoint: "Has a low amount of fat", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "saturated fat": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of saturated fat", value: Float(percentage), message: "limit intake")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "heart-friendly"
                return ([NutrientFeedback(summaryPoint: "Low in saturated fat", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "carbohydrates": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "provides energy"
                return ([NutrientFeedback(summaryPoint: "Rich in carbohydrates", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Has a low amount of carbs", value: Float(percentage), message: "may lack energy")])
            }
            return ([], [])
        },
        "fiber": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids digestion"
                return ([NutrientFeedback(summaryPoint: "Rich in fiber", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in fiber", value: Float(percentage), message: "may not support digestion")])
            }
            return ([], [])
        },
        "sugars": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sugar", value: Float(percentage), message: "limit consumption")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "suits your goals"
                return ([NutrientFeedback(summaryPoint: "Low in sugar", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "sodium": { percentage in
            if percentage > 20 {
                return ([], [NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: Float(percentage), message: "watch intake")])
            } else if percentage < 5 && percentage > 0 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "heart-friendly"
                return ([NutrientFeedback(summaryPoint: "Low in sodium", value: Float(percentage), message: message)], [])
            }
            return ([], [])
        },
        "calcium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports bones"
                return ([NutrientFeedback(summaryPoint: "Rich in calcium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in calcium", value: Float(percentage), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "magnesium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids muscle function"
                return ([NutrientFeedback(summaryPoint: "Rich in magnesium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in magnesium", value: Float(percentage), message: "may impact energy")])
            }
            return ([], [])
        },
        "iron": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports blood health"
                return ([NutrientFeedback(summaryPoint: "Rich in iron", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iron", value: Float(percentage), message: "may impact oxygen transport")])
            }
            return ([], [])
        },
        "zinc": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "boosts immunity"
                return ([NutrientFeedback(summaryPoint: "Rich in zinc", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in zinc", value: Float(percentage), message: "may weaken immune function")])
            }
            return ([], [])
        },
        "iodine": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports thyroid function"
                return ([NutrientFeedback(summaryPoint: "Rich in iodine", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in iodine", value: Float(percentage), message: "may affect thyroid function")])
            }
            return ([], [])
        },
        "potassium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports blood pressure"
                return ([NutrientFeedback(summaryPoint: "Rich in potassium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in potassium", value: Float(percentage), message: "may affect muscle function")])
            }
            return ([], [])
        },
        "phosphorus": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports bone health"
                return ([NutrientFeedback(summaryPoint: "Rich in phosphorus", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in phosphorus", value: Float(percentage), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "copper": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports metabolism"
                return ([NutrientFeedback(summaryPoint: "Rich in copper", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in copper", value: Float(percentage), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "selenium": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "offers antioxidant benefits"
                return ([NutrientFeedback(summaryPoint: "Rich in selenium", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in selenium", value: Float(percentage), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "vitamin a": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids vision"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin A", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin A", value: Float(percentage), message: "may affect vision")])
            }
            return ([], [])
        },
        "vitamin c": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "boosts immunity"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin C", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin C", value: Float(percentage), message: "limited immune support")])
            }
            return ([], [])
        },
        "vitamin d": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports bones"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin D", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin D", value: Float(percentage), message: "may affect bone strength")])
            }
            return ([], [])
        },
        "vitamin e": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "offers antioxidant benefits"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin E", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin E", value: Float(percentage), message: "limited antioxidant support")])
            }
            return ([], [])
        },
        "thiamine": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports energy metabolism"
                return ([NutrientFeedback(summaryPoint: "Rich in thiamine", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in thiamine", value: Float(percentage), message: "may affect energy levels")])
            }
            return ([], [])
        },
        "riboflavin": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids metabolism"
                return ([NutrientFeedback(summaryPoint: "Rich in riboflavin", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in riboflavin", value: Float(percentage), message: "may impact energy")])
            }
            return ([], [])
        },
        "niacin": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports digestion"
                return ([NutrientFeedback(summaryPoint: "Rich in niacin", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in niacin", value: Float(percentage), message: "may affect digestion")])
            }
            return ([], [])
        },
        "vitamin b6": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "aids brain health"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B6", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B6", value: Float(percentage), message: "may impact mood")])
            }
            return ([], [])
        },
        "folate": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports cell growth"
                return ([NutrientFeedback(summaryPoint: "Rich in folate", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in folate", value: Float(percentage), message: "may affect cell function")])
            }
            return ([], [])
        },
        "vitamin b12": { percentage in
            if percentage >= 20 {
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "supports nerve health"
                return ([NutrientFeedback(summaryPoint: "Rich in Vitamin B12", value: Float(percentage), message: message)], [])
            } else if percentage < 5 && percentage > 0 {
                return ([], [NutrientFeedback(summaryPoint: "Low in Vitamin B12", value: Float(percentage), message: "may affect nerve health")])
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
                let message = percentage > 85 ? "check serving size, may exceed your needs" : "great for a boost"
                pros.append(NutrientFeedback(summaryPoint: "Provides a high amount of energy", value: Float(percentage), message: message))
            }
        }
    }
    if cons.isEmpty {
        cons.append(NutrientFeedback(summaryPoint: "No major concerns detected", value: 0, message: "for your profile"))
        if let sodium = product.nutritionInfo.first(where: { $0.name.lowercased() == "sodium" }),
           let sodiumRDA = rda["sodium"] {
            let percentage = calculatePercentage(nutrient: sodium, rdaValue: sodiumRDA)
            if percentage > 20 {
                cons.append(NutrientFeedback(summaryPoint: "Contains a high amount of sodium", value: Float(percentage), message: "use with caution if frequent"))
            }
        }
    }
    
    return ProductAnalysis(pros: pros, cons: cons)
}
func fetchUserData(completion: @escaping (Users?) -> Void) {
    let defaults = UserDefaults.standard
    
    // Check UserDefaults for cached full user data (excluding allergies and dietary restrictions)
    if let userData = defaults.data(forKey: "currentUser") {
        do {
            let decoder = JSONDecoder()
            var user = try decoder.decode(Users.self, from: userData)
            // Override allergies and dietary restrictions with local-specific keys
            if let localAllergies = defaults.array(forKey: "localAllergies") as? [String], !localAllergies.isEmpty {
                user.allergies = localAllergies
            }
            if let localRestrictions = defaults.array(forKey: "localDietaryRestrictions") as? [String], !localRestrictions.isEmpty {
                user.dietaryRestrictions = localRestrictions
            }
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
        
        // Fetch allergies and dietary restrictions with local-first logic
        var allergies: [String] = []
        if let localAllergies = defaults.array(forKey: "localAllergies") as? [String], !localAllergies.isEmpty {
            allergies = localAllergies
        } else if let allergiesFromDB = data["allergies"] as? [String] {
            allergies = allergiesFromDB
            defaults.set(allergiesFromDB, forKey: "localAllergies") // Cache to UserDefaults
        }
        
        var dietaryRestrictions: [String] = []
        if let localRestrictions = defaults.array(forKey: "localDietaryRestrictions") as? [String], !localRestrictions.isEmpty {
            dietaryRestrictions = localRestrictions
        } else if let restrictionsFromDB = data["dietaryRestrictions"] as? [String] {
            dietaryRestrictions = restrictionsFromDB
            defaults.set(restrictionsFromDB, forKey: "localDietaryRestrictions") // Cache to UserDefaults
        }
        
        // Construct Users object with all fields
        let user = Users(
            name: data["name"] as? String ?? "",
            dietaryRestrictions: dietaryRestrictions,
            allergies: allergies,
            gender: data["gender"] as? String ?? "",
            age: data["age"] as? Int ?? 0,
            weight: data["weight"] as? Double ?? 0.0,
            height: data["height"] as? Double ?? 0.0,
            activityLevel: data["activityLevel"] as? String ?? ""
        )
        
        // Cache the full user object to "currentUser" (optional)
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
let standardNutrientNames: [String: String] = [
    "total fats": "total fat",
    "fat": "total fat",
    "saturated fats": "saturated fat",
    "sat fat": "saturated fat",
    "sat. fat": "saturated fat",
    "total carbohydrates": "carbohydrates",
    "carbohydrate": "carbohydrates",
    "carbs": "carbohydrates",
    "fibers": "fiber",
    "dietary fiber": "fiber",
    "sugars": "sugar",
    "energy (kcal)": "energy",
    "calories": "energy",
    "vitamin b1": "thiamine",
    "vitamin b2": "riboflavin",
    "vitamin b3": "niacin",
    "vitamin b6": "vitamin b6",
    "vitamin b9": "folate",
    "folic acid": "folate",
    "vitamin b12": "vitamin b12",
    "vitamin c (ascorbic acid)": "vitamin c",
    "vitamin d3": "vitamin d",
    "vitamin e (tocopherol)": "vitamin e",
    "sodium chloride": "sodium",
    "iodide": "iodine",
    "selenium (se)": "selenium",
    "copper (cu)": "copper",
    "iron (fe)": "iron",
    "zinc (zn)": "zinc",
    "potassium (k)": "potassium",
    "calcium (ca)": "calcium",
    "magnesium (mg)": "magnesium",
    "phosphorus (p)": "phosphorus"
]
func getRDAPercentages(product: ProductResponse, user: Users) -> [String: Double] {
    let rda = getRDA(for: user)
    var percentages: [String: Double] = [:]

    // **Mapping for inconsistent nutrient names (handles OCR errors, singular/plural mismatches, etc.)**
 

    // **Helper function to calculate RDA percentage**
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
    
    // **Process each nutrient**
    for nutrient in product.nutrition {
        let nutrientKey = nutrient.name.lowercased()
        
        // **Standardize the nutrient name before lookup**
        let correctedKey = standardNutrientNames[nutrientKey] ?? nutrientKey

        if let rdaValue = rda[correctedKey] {
            let percentage = calculatePercentage(nutrient: nutrient, rdaValue: rdaValue)
            percentages[correctedKey] = percentage
        }
    }
    print(percentages)
    return percentages
}


// Overloaded version for ProductData
func getRDAPercentages(product: ProductData, user: Users) -> [String: Double] {
    let rda = getRDA(for: user)
    var percentages: [String: Double] = [:]

    // **Mapping for inconsistent nutrient names (handles OCR errors, singular/plural mismatches, etc.)**
  
    // **Helper function to calculate RDA percentage**
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
    
    // **Process each nutrient**
    for nutrient in product.nutritionInfo {
        let nutrientKey = nutrient.name.lowercased()
        
        // **Standardize the nutrient name before lookup**
        let correctedKey = standardNutrientNames[nutrientKey] ?? nutrientKey

        if let rdaValue = rda[correctedKey] {
            let percentage = calculatePercentage(nutrient: nutrient, rdaValue: rdaValue)
            percentages[correctedKey] = percentage
        }
    }
    
    return percentages
}

let dietaryRestrictionRules: [DietaryRestriction: (ProductData) -> Bool] = [
    .lowSodium: { product in
        if let sodium = product.nutritionInfo.first(where: { $0.name.lowercased() == "sodium" || $0.name.lowercased() == "salt" }) {
            let sodiumInMg: Float
            switch sodium.unit.lowercased() {
            case "mg":
                sodiumInMg = sodium.value
            case "g":
                sodiumInMg = sodium.value * 1000
            case "mcg":
                        sodiumInMg = sodium.value / 1000// 1 gram = 1000 milligrams
            default:
                sodiumInMg = sodium.value
            }
            return sodiumInMg <= 120
        }
        return true
    },
        .vegan: { product in
            let nonVegan = [
                "milk", "egg", "fish", "meat", "honey", "gelatin", "cheese", "butter", "cream", "whey",
                "casein", "lactose", "albumin", "lard", "tallow", "collagen", "carmine", "isinglass",
                "shellac", "rennet", "peppered", "bone", "broth", "stock", "animal fat", "beef", "pork",
                "chicken", "turkey", "duck", "goose", "venison", "seafood", "shrimp", "crab", "lobster"
            ]
            let ingredientsViolate = product.ingredients.contains { ingredient in
                nonVegan.contains { ingredient.lowercased().contains($0.lowercased()) }
            }
            let allergensViolate = product.allergens?.contains { allergen in
                nonVegan.contains { allergen.lowercased().contains($0.lowercased()) }
            } ?? false
            let artificialViolate = product.artificialIngredients.contains { artificial in
                nonVegan.contains { artificial.lowercased().contains($0.lowercased()) }
            }
            return !ingredientsViolate && !allergensViolate && !artificialViolate
        },
        .vegetarian: { product in
            let nonVegetarian = [
                "meat", "fish", "chicken", "beef", "pork", "gelatin", "lard", "tallow", "broth", "stock",
                "animal fat", "turkey", "duck", "goose", "venison", "seafood", "shrimp", "crab", "lobster",
                "anchovy", "rennet", "bone", "suet", "pepperoni", "sausage", "bacon", "ham","egg"
            ]
            let ingredientsViolate = product.ingredients.contains { ingredient in
                nonVegetarian.contains { ingredient.lowercased().contains($0.lowercased()) }
            }
            let allergensViolate = product.allergens?.contains { allergen in
                nonVegetarian.contains { allergen.lowercased().contains($0.lowercased()) }
            } ?? false
            let artificialViolate = product.artificialIngredients.contains { artificial in
                nonVegetarian.contains { artificial.lowercased().contains($0.lowercased()) }
            }
            return !ingredientsViolate && !allergensViolate && !artificialViolate
        },
    .sugarFree: { product in
        if let sugar = product.nutritionInfo.first(where: { $0.name.lowercased() == "sugars" || $0.name.lowercased() == "total sugars" || $0.name.lowercased() == "total sugar" || $0.name.lowercased() == "sugar" }) {
            let sugarInGrams: Float
            switch sugar.unit.lowercased() {
            case "g":
                sugarInGrams = sugar.value
            case "mg":
                sugarInGrams = sugar.value / 1000 // Convert milligrams to grams
            default:
                sugarInGrams = sugar.value
            }
            return sugarInGrams <= 0.5
        }
        return true
    },
        .lowCalorie: { product in
            if let energy = product.nutritionInfo.first(where: { $0.name.lowercased() == "energy" || $0.name.lowercased() == "calories" }) {
                let energyInKcal: Float
                switch energy.unit.lowercased() {
                case "kj":
                    energyInKcal = energy.value / 4.184
                case "kcal":
                    energyInKcal = energy.value
                default:
                    // Handle other units or assume kcal if unit is unrecognized
                    energyInKcal = energy.value
                }
                return energyInKcal <= 40.0
            }
            return true
        },
//        .ketoDiet: { product in
//            if let carbs = product.nutritionInfo.first(where: { $0.name.lowercased() == "carbohydrates" || $0.name.lowercased() == "total carbohydrates" }),
//               let fat = product.nutritionInfo.first(where: { $0.name.lowercased() == "fat" || $0.name.lowercased() == "total fat" }) {
//                return carbs.value <= 5.0 && fat.value >= 10.0
//            }
//            return false
//        },
//        .paleoDiet: { product in
//            let nonPaleo = [
//                "wheat", "milk", "cheese", "sugar", "rice", "soy", "corn", "barley", "oats", "rye",
//                "peanut", "bean", "lentil", "chickpea", "soybean", "tofu", "tempeh", "lactose", "whey",
//                "casein", "cream", "butter", "syrup", "molasses", "artificial", "preservative", "coloring"
//            ]
//            let ingredientsViolate = product.ingredients.contains { ingredient in
//                nonPaleo.contains { ingredient.lowercased().contains($0.lowercased()) }
//            }
//            let allergensViolate = product.allergens?.contains { allergen in
//                nonPaleo.contains { allergen.lowercased().contains($0.lowercased()) }
//            } ?? false
//            let artificialViolate = !product.artificialIngredients.isEmpty
//            return !ingredientsViolate && !allergensViolate && !artificialViolate
//        },
       .lowSugar: { product in
            if let sugar = product.nutritionInfo.first(where: { $0.name.lowercased() == "sugar" || $0.name.lowercased() == "total sugars" || $0.name.lowercased() == "total sugar" || $0.name.lowercased() == "sugar" }) {
                let sugarInGrams: Float
                switch sugar.unit.lowercased() {
                case "mg":
                    sugarInGrams = sugar.value / 1000
                case "g":
                    sugarInGrams = sugar.value
                default:
                    // Handle other units or assume grams if unit is unrecognized
                    sugarInGrams = sugar.value
                }
                return sugarInGrams <= 5.0
            }
            return true
        },
        .lactoseFree: { product in
            let dairy = [
                "milk", "cheese", "butter", "cream", "lactose", "whey", "casein", "yogurt", "curd",
                "ghee", "custard", "ice cream", "sour cream", "half and half", "milk powder",
                "condensed milk", "evaporated milk", "buttermilk", "maltodextrin"
            ]
            let ingredientsViolate = product.ingredients.contains { ingredient in
                dairy.contains { ingredient.lowercased().contains($0.lowercased()) }
            }
            let allergensViolate = product.allergens?.contains { allergen in
                dairy.contains { allergen.lowercased().contains($0.lowercased()) }
            } ?? false
            let artificialViolate = product.artificialIngredients.contains { artificial in
                dairy.contains { artificial.lowercased().contains($0.lowercased()) }
            }
            return !ingredientsViolate && !allergensViolate && !artificialViolate
        },
        .glutenFree: { product in
            let gluten = [
                "wheat", "barley", "rye", "malt", "spelt", "kamut", "triticale", "farro", "durum",
                "semolina", "bulgur", "couscous", "maltodextrin", "gluten", "flour"
            ]
            let ingredientsViolate = product.ingredients.contains { ingredient in
                gluten.contains { ingredient.lowercased().contains($0.lowercased()) }
            }
            let allergensViolate = product.allergens?.contains { allergen in
                gluten.contains { allergen.lowercased().contains($0.lowercased()) }
            } ?? false
            let artificialViolate = product.artificialIngredients.contains { artificial in
                gluten.contains { artificial.lowercased().contains($0.lowercased()) }
            }
            return !ingredientsViolate && !allergensViolate && !artificialViolate
        },
        .eggetarian: { product in
                    // Allows eggs but excludes meat, fish, and their derivatives
                    let nonEggetarian = [
                        "meat", "fish", "chicken", "beef", "pork", "gelatin", "lard", "tallow", "broth", "stock",
                        "animal fat", "turkey", "duck", "goose", "venison", "seafood", "shrimp", "crab", "lobster",
                        "anchovy", "rennet", "bone", "suet", "pepperoni", "sausage", "bacon", "ham"
                    ]
                    let ingredientsViolate = product.ingredients.contains { ingredient in
                        nonEggetarian.contains { ingredient.lowercased().contains($0.lowercased()) }
                    }
                    let allergensViolate = product.allergens?.contains { allergen in
                        nonEggetarian.contains { allergen.lowercased().contains($0.lowercased()) }
                    } ?? false
                    let artificialViolate = product.artificialIngredients.contains { artificial in
                        nonEggetarian.contains { artificial.lowercased().contains($0.lowercased()) }
                    }
                    return !ingredientsViolate && !allergensViolate && !artificialViolate
                },
        .lowFat: { product in
                if let fat = product.nutritionInfo.first(where: { $0.name.lowercased() == "fat" || $0.name.lowercased() == "total fat" || $0.name.lowercased() == "fats" || $0.name.lowercased() == "total fats" }) {
                    let fatInGrams: Float
                    switch fat.unit.lowercased() {
                    case "mg":
                        fatInGrams = fat.value / 1000
                    case "g":
                        fatInGrams = fat.value
                    default:
                        // Handle other units or assume grams if unit is unrecognized
                        fatInGrams = fat.value
                    }
                    return fatInGrams <= 3.0
                }
                return true
            }
    

    ]
