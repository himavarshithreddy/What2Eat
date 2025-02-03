//
//  SearchResultsViewController.swift
//  What2Eat
//
//  Created by admin68 on 15/12/24.
//

import UIKit

class SearchResultsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
  
    var searchResults: [Product] = []
    @IBOutlet var SearchResultsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        SearchResultsTableView.delegate = self
        SearchResultsTableView.dataSource = self
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsTableViewCell", for: indexPath) as! SearchResultsTableViewCell
        let product = searchResults[indexPath.row]
        
        if product.healthScore < 40 {
           
            cell.ProductCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        }
        else if product.healthScore < 75 {
        
            cell.ProductCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        }
        else if product.healthScore < 100 {
            cell.ProductCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        cell.ProductName.text = product.name
        cell.ProductImage.image = UIImage(named: product.imageURL)
        cell.ProductScore.text = String(product.healthScore)
        cell.ProductCircle.layer.cornerRadius = 20
        return cell
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = searchResults[indexPath.row]
            performSegue(withIdentifier: "showproductfromresults", sender: selectedProduct)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showproductfromresults",
               let destinationVC = segue.destination as? ProductDetailsViewController,
               let selectedProduct = sender as? Product {
                destinationVC.products = selectedProduct
            }
        }

    
}
