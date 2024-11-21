//
//  NewListViewController.swift
//  What2Eat
//
//  Created by sumanaswi on 21/11/24.
//

import UIKit

class NewListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
        
    var selectedIcon: String?

    @IBOutlet weak var SelectIconCV: UICollectionView!
    @IBOutlet weak var ListNameText: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        SelectIconCV.delegate = self
        SelectIconCV.dataSource = self
        

        // Do any additional setup after loading the view.
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
                cell.contentView.backgroundColor = .systemOrange
            } else {
                cell.contentView.backgroundColor = UIColor.clear
            }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIcon = savedlistImages[indexPath.row]
        collectionView.reloadData()

        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = .systemOrange
            }

        for cell in collectionView.visibleCells {
            if let index = collectionView.indexPath(for: cell), index != indexPath {
                cell.contentView.backgroundColor = UIColor(red: 228/255 , green: 113/255, blue: 45/255, alpha: 1)
                
            }
        }

    }

    @IBAction func saveList(_ sender: Any) {
        guard let name = ListNameText.text, !name.isEmpty else {
                showAlert(message: "Please enter a list name.")
                return
            }
            
            guard let icon = selectedIcon else {
                showAlert(message: "Please select an icon.")
                return
            }
        NotificationCenter.default.post(name: Notification.Name("NewListCreated"), object: nil, userInfo: ["name": ListNameText.text!, "icon": icon])
        dismiss(animated: true, completion: nil)
    }
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        okAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }


    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
