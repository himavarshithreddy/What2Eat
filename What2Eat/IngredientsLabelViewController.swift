//
//  IngredientsLabelViewController.swift
//  What2Eat
//
//  Created by admin20 on 20/02/25.
//

import UIKit
import Lottie
import Firebase
import FirebaseVertexAI
class IngredientsLabelViewController:UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    var ingredients: [String] = []
    struct IngredientDetailFromVertex: Codable {
        let description: String
        let potentialConcern: String
        let regulatoryStatus: String
        let riskLevel: String
    }
    @IBOutlet var ingredientsLabelTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ingredientsLabelTableView.delegate = self
                ingredientsLabelTableView.dataSource = self
                
             
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ingredientsLabelTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return ingredients.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientsLabelCell", for: indexPath) as? IngredientsLabelCell else {
                return UITableViewCell()
            }
            
            let ingredient = ingredients[indexPath.row]
            cell.ingredientLabel.text = ingredient
            cell.minHeight = 60

            cell.accessoryType = .detailButton
            
            return cell
        }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let verticalPadding: CGFloat = 8
        let maskLayer = CALayer()
        maskLayer.cornerRadius = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(
            x: cell.bounds.origin.x,
            y: cell.bounds.origin.y,
            width: cell.bounds.width,
            height: cell.bounds.height
        ).insetBy(dx: 0, dy: verticalPadding / 2)
        cell.layer.mask = maskLayer
    }
        // Helper function to map risk level strings to display values and colors
        func riskLevelDisplayAndColor(for riskLevel: String) -> (displayText: String, color: UIColor) {
            switch riskLevel.lowercased() {
            case "risk-free":
                return ("Risk-free", UIColor.systemGreen)
            case "low":
                return ("Low Risk", UIColor(red: 152/255, green: 168/255, blue: 124/255, alpha: 1))
            case "medium":
                return ("Medium Risk", UIColor(red: 204/255, green: 85/255, blue: 0/255, alpha: 1))
            case "high":
                return ("High Risk", UIColor.red)
            default:
                return (riskLevel, UIColor.black)
            }
        }
    
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           // Deselect the row if needed
           tableView.deselectRow(at: indexPath, animated: true)
       }
       
       // When tapping the accessory (detail) button, present details in a popup.
       func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
           let ingredient = ingredients[indexPath.row]
           
           fetchIngredientDetails(ingredient)
       }
       
       // MARK: - Presenting Ingredient Details
       
       func presentIngredientDetails(_ detail: IngredientDetail) {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let ingredientDetailVC = storyboard.instantiateViewController(withIdentifier: "IngredientDetailViewController") as? IngredientDetailViewController {
               
               ingredientDetailVC.ingredientName = detail.name
               let mapping = riskLevelDisplayAndColor(for: detail.riskLevel)
               ingredientDetailVC.riskLevelText = mapping.displayText
               ingredientDetailVC.riskLevelColor = mapping.color
               ingredientDetailVC.descriptionText = detail.description
               ingredientDetailVC.potentialConcernsText = detail.potentialConcern
               ingredientDetailVC.regulatoryStatus = detail.regulatoryStatus
               
               ingredientDetailVC.modalPresentationStyle = .pageSheet
               if let sheet = ingredientDetailVC.sheetPresentationController {
                   let customDetent = UISheetPresentationController.Detent.custom { _ in
                       return 350
                   }
                   sheet.detents = [customDetent]
                   sheet.prefersGrabberVisible = true
                   sheet.preferredCornerRadius = 22
               }
               
               present(ingredientDetailVC, animated: true, completion: nil)
           }
       }
    func fetchIngredientDetails(_ ingredientName: String) {
        showLoading()
        let db = Firestore.firestore()
        let formattedName = ingredientName.lowercased()
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("ingredients").document(formattedName).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching details for \(ingredientName): \(error.localizedDescription)")
                // Fallback to Vertex AI if there's an error.
                self?.fetchIngredientDetailsUsingVertex(for: ingredientName) { detail in
                    self?.hideLoading()
                    if let detail = detail {
                        DispatchQueue.main.async {
                            self?.presentIngredientDetails(detail)
                        }
                    }
                }
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("No document found for \(formattedName)")
                // Fallback to Vertex AI if document is not found.
                self?.fetchIngredientDetailsUsingVertex(for: ingredientName) { detail in
                    self?.hideLoading()
                    if let detail = detail {
                        DispatchQueue.main.async {
                            self?.presentIngredientDetails(detail)
                        }
                    }
                }
                return
            }
            
            // If document exists, create the IngredientDetail from Firestore data.
            self?.hideLoading()
            let details = IngredientDetail(
                name: ingredientName,
                description: data["Description"] as? String ?? "No description",
                potentialConcern: data["PotentialConcern"] as? String ?? "No concerns",
                regulatoryStatus: data["RegulatoryInfo"] as? String ?? "No info",
                riskLevel: data["RiskLevel"] as? String ?? "N/A"
            )
            
            DispatchQueue.main.async {
                self?.presentIngredientDetails(details)
            }
        }
    }

    func updateIngredients(with ingredients: [String]) {
           self.ingredients = ingredients
           DispatchQueue.main.async {
               self.ingredientsLabelTableView.reloadData()
           }
       }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        60
//    }
    
    func fetchIngredientDetailsUsingVertex(for ingredientName: String, completion: @escaping (IngredientDetail?) -> Void) {
        // Define the JSON schema for the expected Vertex response.
        let jsonSchema = Schema.object(
            properties: [
                "description": Schema.string(),
                "potentialConcern": Schema.string(),
                "regulatoryStatus": Schema.string(),
                "riskLevel": Schema.string()
            ]
        )
        
        let systemInstruction = """
        You are an AI assistant that provides very concise information about food ingredients. Given an ingredient name, return a JSON object with keys "description", "potentialConcern", "regulatoryStatus", and "riskLevel": One of the following values only: Low, Medium, High, or Risk Free. If no information is available, use defaults such as "No description", "No concerns", "Not regulated", and "N/A".
        """
        
        let generationConfig = GenerationConfig(
            temperature: 0.2,
            topP: 0.95,
            maxOutputTokens: 2000,
            responseMIMEType: "application/json",
            responseSchema: jsonSchema
        )
        
        let vertex = VertexAI.vertexAI()
        let model = vertex.generativeModel(
            modelName: "gemini-1.5-flash-002",
            generationConfig: generationConfig,
            systemInstruction: ModelContent(role: "system", parts: systemInstruction)
        )
        
        let prompt = "Provide concise information about the ingredient: \(ingredientName)"
        
        Task {
            do {
                // Assuming generateContent supports text prompts when no image is provided.
                let response = try await model.generateContent(prompt)
                if let jsonResponse = response.text,
                   let jsonData = jsonResponse.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    let vertexDetails = try decoder.decode(IngredientDetailFromVertex.self, from: jsonData)
                    // Map the Vertex response to our IngredientDetail model.
                    let detail = IngredientDetail(
                        name: ingredientName,
                        description: vertexDetails.description,
                        potentialConcern: vertexDetails.potentialConcern,
                        regulatoryStatus: vertexDetails.regulatoryStatus,
                        riskLevel: vertexDetails.riskLevel
                    )
                    completion(detail)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error calling Vertex for ingredient details: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
private var loadingView: UIView?
    
    // MARK: - Loading Animation
    private func showLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create container view
            let containerView = UIView(frame: self.view.bounds)
            containerView.backgroundColor = UIColor.clear
            containerView.tag = 1001
            
            // Create animation view
            let animationView = LottieAnimationView(name: "loading_ingredients4")
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = .loop
            animationView.play()
            
            
            
            // Stack view for vertical layout
            let stackView = UIStackView(arrangedSubviews: [animationView])
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 20
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(stackView)
            
            // Center constraints
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                animationView.widthAnchor.constraint(equalToConstant: 150),
                animationView.heightAnchor.constraint(equalToConstant: 150)
            ])
            
            // Add to view and animate
            self.view.addSubview(containerView)
            containerView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                containerView.alpha = 1
            }
        }
    }

    private func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let container = self.view.viewWithTag(1001) {
                UIView.animate(withDuration: 0.2, animations: {
                    container.alpha = 0
                }, completion: { _ in
                    container.removeFromSuperview()
                })
            }
        }
    }
   }

    


