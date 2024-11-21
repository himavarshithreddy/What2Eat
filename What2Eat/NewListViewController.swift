//
//  NewListViewController.swift
//  What2Eat
//
//  Created by sumanaswi on 21/11/24.
//

import UIKit

class NewListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    var product: Product?
    var selectedIcon: String?

    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var PreviewIcon: UIImageView!
    @IBOutlet weak var SelectIconCV: UICollectionView!
    @IBOutlet weak var ListNameText: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        SelectIconCV.delegate = self
        SelectIconCV.dataSource = self
        saveButton.isEnabled = false
        ListNameText.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
    }
    @objc func textFieldDidChange() {
            // Enable Save button if both List name and selected Icon are present
            if let name = ListNameText.text, !name.isEmpty, selectedIcon != nil {
                saveButton.isEnabled = true
            } else {
                saveButton.isEnabled = false
            }
        }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        savedlistImages.count
    }
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {                     return CGSize(width: 50, height:50)
                 }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewListIconCell", for: indexPath) as! NewListIconCell
        let image = savedlistImages[indexPath.row]
        cell.IconImage.image = UIImage(systemName: image)
        if selectedIcon == image {
            cell.layer.backgroundColor = UIColor.systemOrange.cgColor
            }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIcon = savedlistImages[indexPath.row]
        PreviewIcon.image = UIImage(systemName: selectedIcon!)
        collectionView.reloadData()

        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.layer.backgroundColor = UIColor.systemOrange.cgColor
            }

        for cell in collectionView.visibleCells {
            if let index = collectionView.indexPath(for: cell), index != indexPath {
                cell.contentView.backgroundColor = UIColor(red: 228/255 , green: 113/255, blue: 45/255, alpha: 1)
                
            }
        }
        textFieldDidChange()
    }

    @IBAction func saveList(_ sender: Any) {
        guard let name = ListNameText.text, !name.isEmpty else {
               
                return
            }
            
            guard let icon = selectedIcon else {
               
                return
            }
       
       
        let iconImage = UIImage(systemName: icon)!
        var newList = SavedList(id: UUID(), name: name, products: [], iconName: iconImage)
        if let product = product {
                    newList.products.append(product)
                }
        sampleLists.append(newList)
        NotificationCenter.default.post(
                name: Notification.Name("ProductSaved"),
                object: product, // Pass the product as the notification's object
                userInfo: ["listName": name] // Optionally include list details
            )
        NotificationCenter.default.post(name: Notification.Name("ProductSaved"), object: product,userInfo: nil)
           
        NotificationCenter.default.post(name: Notification.Name("NewListCreated"), object: nil, userInfo: nil)
       
        dismiss(animated: true, completion: nil)
    }
  

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
   

}
