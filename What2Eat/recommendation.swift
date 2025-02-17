import Foundation

class RecommendationManager {
    static let shared = RecommendationManager()
    private let defaults = UserDefaults.standard
    private var previousRecentScans: [[String: Any]] = []
    
    private init() {
        // Initialize with the current value
        previousRecentScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] ?? []
        // Observe changes in UserDefaults
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(defaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: defaults)
    }
    
    @objc private func defaultsChanged(_ notification: Notification) {
        // Get the current value for "localRecentScans"
        let currentRecentScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] ?? []
        
        // Compare the current value with the previous value.
        // Here, we use JSON serialization to compare; you can use another method if you prefer.
        if !areEqual(previousRecentScans, currentRecentScans) {
            // Update the stored value
            previousRecentScans = currentRecentScans
            // Call the API to update recommendations
            makeRecommendationAPICall()
        }
    }
    
    /// Helper function to compare two arrays of dictionaries
    private func areEqual(_ lhs: [[String: Any]], _ rhs: [[String: Any]]) -> Bool {
        guard let lhsData = try? JSONSerialization.data(withJSONObject: lhs, options: []),
              let rhsData = try? JSONSerialization.data(withJSONObject: rhs, options: []) else {
            return false
        }
        return lhsData == rhsData
    }
    
    func makeRecommendationAPICall() {
        // Fetch the recent scans from UserDefaults and extract product IDs.
        let recentScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] ?? []
        let userScannedProductIds = recentScans.prefix(5).compactMap { $0["productId"] as? String } // Taking top 5
        
        // Fetch the allergens (stored under "userAllergens")
        let userAllergens = defaults.array(forKey: "userAllergens") as? [String] ?? []
        
        // Construct the JSON payload for the API call.
        let requestBody: [String: Any] = [
            "user_scanned_product_ids": userScannedProductIds,
            "user_allergens": userAllergens,
            "top_n": 8
        ]
      
        
        guard let url = URL(string: "https://what2eat-recommender-745594998609.asia-south1.run.app/recommend/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Error encoding JSON: \(error)")
            return
        }
        
        // Perform the API call.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error making API call: \(error)")
                return
            }
            
            if let data = data {
                do {
                    // Assume the response is an array of dictionaries.
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        // Extract product IDs from the response.
                        let recommendedProductIds = jsonArray.compactMap { $0["id"] as? String }
                        
                        // Replace the old recommendations with the new ones.
                        self.defaults.set(recommendedProductIds, forKey: "recommendations")
                        print("Updated Recommendations: \(recommendedProductIds)")
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
        }
        
        task.resume()
    }
}
