import UIKit
import FirebaseFirestore

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var searchResults: [(id: String, name: String)] = []  // Holds search results (Product ID & Name)
    var recentSearches: [RecentItem] = [] // Holds recent searches and products

    var isSearching = false
    var searchIcon: String = "clock.arrow.trianglehead.counterclockwise.rotate.90"
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var searchTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchTableView.delegate = self
        searchTableView.dataSource = self
        
        loadRecentSearches() // Load recent searches on launch
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
        searchTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - TableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : recentSearches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchTableViewCell
        
        if isSearching {
            // Display live search results
            let product = searchResults[indexPath.row]
            cell.SearchLabels.text = product.name
            cell.SearchItemIcon.image = UIImage(systemName: searchIcon)
        } else {
            // Display recent items
            let recentItem = recentSearches[indexPath.row]
            cell.SearchLabels.text = recentItem.name
            
            // Use different icons based on type, if desired.
            switch recentItem.type {
            case .query:
                cell.SearchItemIcon.image = UIImage(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            case .product:
                cell.SearchItemIcon.image = UIImage(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90") // Or any product-related icon
            }
        }
        
        return cell
    }
    
    // MARK: - Searching Logic
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchIcon = "clock.arrow.trianglehead.counterclockwise.rotate.90"
            isSearching = false
            searchResults = []
        } else {
            searchIcon = "magnifyingglass"
            isSearching = true
            fetchProductsFromFirebase(query: searchText)
        }
        
        searchTableView.reloadData()
    }
    
    // Fetch product IDs & names from Firestore for live search (no completion)
    func fetchProductsFromFirebase(query: String) {
        let db = Firestore.firestore()
        
        db.collection("products")
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThanOrEqualTo: query + "\u{f8ff}") // Firebase search trick
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching products: \(error.localizedDescription)")
                    return
                }
                
                self.searchResults = snapshot?.documents.compactMap { doc in
                    let id = doc.documentID
                    let name = doc.data()["name"] as? String ?? "Unknown"
                    return (id, name)
                } ?? []
                
                DispatchQueue.main.async {
                    self.searchTableView.reloadData()
                }
            }
    }
    
    // Fetch product IDs only (with completion) for recent search queries
    func fetchProductsFromFirebase(query: String, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("products")
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThanOrEqualTo: query + "\u{f8ff}")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching products: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let productIDs = snapshot?.documents.map { $0.documentID } ?? []
                completion(productIDs)
            }
    }
    
    // MARK: - Selecting a Product or Recent Item
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearching {
            // When in active search mode, tapping a result is a product.
            let selectedProduct = searchResults[indexPath.row]
            addProductToRecentSearches(product: selectedProduct)
            performSegue(withIdentifier: "showProductDetailFromSearch", sender: selectedProduct.id)
        } else {
            // Tapped on a recent item.
            let recentItem = recentSearches[indexPath.row]
            switch recentItem.type {
            case .query:
                // For recent queries, use the query string to fetch products.
                searchBar.text = recentItem.name
                fetchProductsFromFirebase(query: recentItem.name) { productIDs in
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "showSearchResults", sender: productIDs)
                    }
                }
            case .product:
                // For recent products, go directly to the product details.
                performSegue(withIdentifier: "showProductDetailFromSearch", sender: recentItem.id)
            }
        }
    }
    
    // MARK: - Recent Searches Handling
    func addProductToRecentSearches(product: (id: String, name: String)) {
        // Remove if already exists to avoid duplicates
        recentSearches.removeAll { $0.id == product.id }
        
        // Add the product with type .product to the beginning of the list
        let item = RecentItem(id: product.id, name: product.name, type: .product)
        recentSearches.insert(item, at: 0)
        
        // Limit to the last 10 items
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }
        
        saveRecentSearches()
    }
    
    func addSearchQueryToRecentSearches(query: String) {
        // Remove the query if it's already in the list to avoid duplicates
        recentSearches.removeAll { $0.name.lowercased() == query.lowercased() && $0.type == .query }
        
        // Add the search query with type .query to the beginning of the list
        let item = RecentItem(id: UUID().uuidString, name: query, type: .query)
        recentSearches.insert(item, at: 0)
        
        // Limit to the last 10 items
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }

        saveRecentSearches()
    }
    
    func saveRecentSearches() {
        let defaults = UserDefaults.standard
        // Since RecentItem conforms to Codable, we can encode it
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            defaults.set(encoded, forKey: "RecentSearches")
        }
    }
    
    func loadRecentSearches() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "RecentSearches"),
           let items = try? JSONDecoder().decode([RecentItem].self, from: data) {
            recentSearches = items
        }
        searchTableView.reloadData()
    }
    
    // MARK: - Searching on Button Click
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        let searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !searchText.isEmpty else { return }
        // Save the search query as a recent item of type .query
        addSearchQueryToRecentSearches(query: searchText)
        fetchProductsFromFirebase(query: searchText) { productIDs in
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showSearchResults", sender: productIDs)
            }
        }
    }
    
    // MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProductDetailFromSearch",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let productID = sender as? String {
            destinationVC.productId = productID  // Pass product ID
        }
        else if segue.identifier == "showSearchResults",
                let destinationVC = segue.destination as? SearchResultsViewController,
                let productIDs = sender as? [String] {
            destinationVC.productIDs = productIDs  // Pass list of product IDs
        }
    }
}
