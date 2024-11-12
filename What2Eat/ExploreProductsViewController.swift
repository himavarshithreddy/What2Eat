//
//  ExploreProductsViewController.swift
//  What2Eat
//
//  Created by admin20 on 05/11/24.
//

import UIKit

class ExploreProductsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
   
    var category: Category?
    var filteredProducts: [Product] = []
    
    @IBOutlet weak var ExploreProductsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

     ExploreProductsTableView.delegate = self
     ExploreProductsTableView.dataSource = self
       
        if let category = category {
                   self.navigationItem.title = category.name  // Set title based on category
                   // Filter ExploreProductslist based on selected category
                   filteredProducts = sampleProducts.filter { $0.categoryId == category.id }
               }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreProductsCell", for: indexPath) as! ExploreProductsCell
        let product = filteredProducts[indexPath.row]
        if product.healthScore < 40 {
                   cell.ExploreScoreCircle.layer.backgroundColor = UIColor.systemRed.cgColor
                }
                else if product.healthScore < 75 {
                
                    cell.ExploreScoreCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
                }
                else if product.healthScore < 100 {
                    cell.ExploreScoreCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
                }
        
        cell.ExploreProductsName.text = product.name
        cell.ExploreProductsImage.image = UIImage(named: product.imageURL)
        cell.ExploreScoreCircle.layer.cornerRadius = 20
        cell.ExploreScoretext.text = String(product.healthScore)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let selectedProduct = filteredProducts[indexPath.row]
            performSegue(withIdentifier: "showProductDetails", sender: selectedProduct)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showProductDetails",
               let destinationVC = segue.destination as? ProductDetailsViewController,
               let selectedProduct = sender as? Product {
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
