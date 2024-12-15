//
//  SearchViewController.swift
//  What2Eat
//
//  Created by admin68 on 15/12/24.
//

import UIKit

class SearchViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
  
    
    var searchResults: [Product] = []
    var isSearching = false
    var searchicon : String = "clock.arrow.trianglehead.counterclockwise.rotate.90"
    @IBOutlet var SearchBar: UISearchBar!
    @IBOutlet var SearchTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SearchBar.delegate = self
        SearchTableView.delegate = self
        SearchTableView.dataSource = self
        searchResults = recentSearch.products
        SearchTableView.reloadData()

        
    }
    override func viewDidAppear(_ animated: Bool) {
          super.viewDidAppear(animated)
          SearchBar.becomeFirstResponder()
      }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
          searchBar.resignFirstResponder()
        navigationController?.popViewController(animated: true)
        
      }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchTableViewCell
               
               let product = searchResults[indexPath.row]
                cell.SearchLabels.text = product.name
                cell.SearchItemIcon.image = UIImage(systemName:searchicon)
               
               return cell
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.isEmpty {
               searchicon = "clock.arrow.trianglehead.counterclockwise.rotate.90"
                isSearching = false
                searchResults = recentSearch.products
            } else {
                searchicon="magnifyingglass"
                isSearching = true
                searchResults = sampleProducts.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            }
            
        
        SearchTableView.reloadData()
        }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = searchResults[indexPath.row]
        performSegue(withIdentifier: "showProductDetailFromSearch", sender: selectedProduct)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProductDetailFromSearch" {
            if let destinationVC = segue.destination as? ProductDetailsViewController {
                if let product = sender as? Product {
                    destinationVC.product = product
                }
            }
        }
    }

        
}
