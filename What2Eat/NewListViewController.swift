import UIKit
import FirebaseFirestore
import FirebaseAuth

class NewListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var productId:String?
    var selectedIcon: String?
    
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var PreviewIcon: UIImageView!
    @IBOutlet weak var SelectIconCV: UICollectionView!
    @IBOutlet weak var ListNameText: UITextField!
    
    let db = Firestore.firestore()
    var userId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        SelectIconCV.delegate = self
        SelectIconCV.dataSource = self
        saveButton.isEnabled = false
        ListNameText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Get logged-in user ID
        if let currentUser = Auth.auth().currentUser {
            userId = currentUser.uid
        } else {
            print("User not logged in")
        }
    }
    
    @objc func textFieldDidChange() {
        saveButton.isEnabled = !(ListNameText.text?.isEmpty ?? true) && selectedIcon != nil
    }

    // CollectionView: Number of items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedlistImages.count
    }

    // CollectionView: Cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }

    // CollectionView: Configure cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewListIconCell", for: indexPath) as! NewListIconCell
        let imageName = savedlistImages[indexPath.row]
        
        cell.IconImage.image = UIImage(systemName: imageName)
        
        // Highlight selected icon
        cell.contentView.backgroundColor = (selectedIcon == imageName) ? UIColor.systemOrange : UIColor.clear
        return cell
    }

    // CollectionView: Handle selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIcon = savedlistImages[indexPath.row]
        PreviewIcon.image = UIImage(systemName: selectedIcon!)
        collectionView.reloadData()
        textFieldDidChange()
    }

    // 🔥 Save new list to Firestore
    @IBAction func saveList(_ sender: Any) {
          guard let userId = userId else {
              print("User ID not found")
              return
          }
          guard let name = ListNameText.text, !name.isEmpty, let icon = selectedIcon else {
              return
          }
          
          let newListId = UUID().uuidString
          
          // Initialize the products array.
          // If a product is passed from the Product Details screen, add its ID.
          var productsArray: [String] = []
        if let product = productId {
              productsArray.append(product)
          }
          
          let newList: [String: Any] = [
              "listId": newListId,
              "name": name,
              "iconName": icon,
              "products": productsArray
          ]
          
          // Add the new list to the user's savedLists field.
          db.collection("users").document(userId).updateData([
              "savedLists": FieldValue.arrayUnion([newList])
          ]) { error in
              if let error = error {
                  print("Error saving list: \(error)")
              } else {
                  print("List saved successfully")
                  
                  // Post a notification so that the Product Details screen can update its bookmark icon.
                  // You can also pass the new list ID if needed.
                  NotificationCenter.default.post(name: Notification.Name("NewListCreated"), object: nil, userInfo: [
                      "listId": newListId,
                      "productSaved": true
                  ])
                  
                  self.dismiss(animated: true, completion: nil)
              }
          }
      }
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
