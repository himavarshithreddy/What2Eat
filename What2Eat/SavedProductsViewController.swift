//
//  SavedProductsViewController.swift
//  What2Eat
//
//  Created by sumanaswi on 05/11/24.
//

import UIKit

class SavedProductsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
   
    @IBOutlet weak var SavedProductsTableView: UITableView!
   
    var selectedList: SavedList?
    override func viewDidLoad() {
        super.viewDidLoad()
     
        SavedProductsTableView.delegate = self
        SavedProductsTableView.dataSource = self
        if let selectedList = selectedList {
                    self.navigationItem.title = selectedList.name
                }
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleProductChange(_:)),
                name: Notification.Name("ProductUnsaved"),
                object: nil
            )

    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedList?.products.count ?? 0
    }
    @objc func handleProductChange(_ notification: Notification) {
        guard let unsavedProduct = notification.object as? ProductData else { return }
        selectedList?.products.removeAll { $0.id == unsavedProduct.id }
        SavedProductsTableView.reloadData()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedProductsCell", for: indexPath) as! SavedProductsCell
        let product = selectedList?.products[indexPath.row]
        
        if product!.healthScore < 40 {
           
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        }
        else if product!.healthScore < 75 {
        
            cell.ScoreCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        }
        else if product!.healthScore < 100 {
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        cell.SavedProductsName.text = product!.name

        if let url = URL(string: product!.imageURL) {
            cell.SavedProductsImage.sd_setImage(with: url, placeholderImage: UIImage(named: product!.imageURL))
        } else {
            cell.SavedProductsImage.image = UIImage(named: "placeholder_product")
        }
        cell.Scoretext.text = String(Int(product!.healthScore))
        cell.ScoreCircle.layer.cornerRadius = 20
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = selectedList?.products[indexPath.row]
            performSegue(withIdentifier: "showProductDetailsfromSaved", sender: selectedProduct)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showProductDetailsfromSaved",
               let destinationVC = segue.destination as? ProductDetailsViewController,
               let selectedProduct = sender as? ProductData {
                destinationVC.product = selectedProduct
            }
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
