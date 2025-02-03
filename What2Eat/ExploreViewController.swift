import UIKit
import FirebaseFirestore
import SDWebImage // Assuming you're using SDWebImage for loading images from URLs

class ExploreViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    let db = Firestore.firestore()
    var categories: [category] = []

    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var CollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let flowLayout = CollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = .zero
        }
        
        CollectionView.delegate = self
        CollectionView.dataSource = self
        SearchBar.delegate = self
        listenForCategoryUpdates()
        fetchCategoriesFromFirebase()
    }

    func fetchCategoriesFromFirebase() {
        db.collection("categories")
            .getDocuments(source: .cache) { (querySnapshot, error) in // First, try cache
                if let error = error {
                    print("Error fetching categories from cache: \(error.localizedDescription)")
                    self.fetchCategoriesFromServer() // If cache fails, fetch from Firestore
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    print("Loaded categories from cache ✅")
                    self.processCategories(documents: documents)
                } else {
                    print("Cache empty, fetching from server...")
                    self.fetchCategoriesFromServer() // If cache is empty, fetch from Firestore
                }
            }
    }

    // Fetch from Firestore (if cache is empty or outdated)
    func fetchCategoriesFromServer() {
        db.collection("categories")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching categories from Firestore: \(error.localizedDescription)")
                    return
                }
                
                if let documents = querySnapshot?.documents {
                    print("Fetched categories from Firestore 🌍")
                    self.processCategories(documents: documents)
                }
            }
    }
    func listenForCategoryUpdates() {
        // Set up a listener for the categories collection to listen for real-time updates
        db.collection("categories").addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error listening for category updates: \(error.localizedDescription)")
                return
            }
            
            // If new data comes in, process it
            if let documents = querySnapshot?.documents {
                print("Received updated categories in real-time 🔄")
                self.processCategories(documents: documents)
            }
        }
    }

    // Process fetched categories into the array
    func processCategories(documents: [QueryDocumentSnapshot]) {
        self.categories = []

        documents.forEach { document in
            let data = document.data()
            if let name = data["name"] as? String,
               let imageUrl = data["imageUrl"] as? String {
                let id = Int(document.documentID) ?? 0
                let category = category(id: id, name: name, imageName: imageUrl)
                self.categories.append(category)
            }
        }
        self.categories.sort { $0.id < $1.id }

        DispatchQueue.main.async {
            self.CollectionView.reloadData()
        }
    }


    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
        cell.layer.cornerRadius = 8
        
        let category = categories[indexPath.item]
        
        if let CategoryCell = cell as? CategoryCollectionViewCell {
            CategoryCell.CategoryName.text = category.name
            
            if let imageUrl = URL(string: category.imageName) {
                        CategoryCell.CategoryImage.sd_setImage(
                            with: imageUrl,
                            placeholderImage: UIImage(named: "placeholder"),
                            options: [.continueInBackground, .highPriority]
                        )
                    }
                }

        return cell
    }

    // MARK: - Header View for CollectionView
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ExploreHeaderView", for: indexPath) as! ExploreHeaderView
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 25) // Adjust height as needed
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 20) / 3
        return CGSize(width: width, height: 165)
    }

    // MARK: - DidSelectItem Action
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCategory = categories[indexPath.item]
        performSegue(withIdentifier: "showExploreProducts", sender: selectedCategory)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showExploreProducts",
           let destination = segue.destination as? ExploreProductsViewController,
           let selectedCategory = sender as? category {
                   destination.categoryId = String(selectedCategory.id) 
               }
    }

    // MARK: - Search Bar Action
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        performSegue(withIdentifier: "showsearch", sender: nil)
        return false
    }
}
