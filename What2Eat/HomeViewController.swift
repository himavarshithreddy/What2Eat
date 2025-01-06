//
//  HomeViewController.swift
//  What2Eat
//
//  Created by admin68 on 19/11/24.
//

import UIKit
import WebKit
import FirebaseAuth

class HomeViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UITableViewDelegate,UITableViewDataSource {
    
    
    @IBOutlet var HomeHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet var UserName: UILabel!
    @IBOutlet var RecentScansTableView: UITableView!
   
    
    
    @IBOutlet var HomeImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        HomeImage.transform = CGAffineTransform(rotationAngle: .pi*1.833)
        collectionView.delegate = self
        RecentScansTableView.delegate = self
        RecentScansTableView.dataSource = self
        
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
      
        HomeHeight.constant = CGFloat((sampleUser.recentlyViewedProducts.count * 85)+800)
        updateUserName()
       
        // Do any additional setup after loading the view.
    }
    func updateUserName() {
            if let user = Auth.auth().currentUser {
                UserName.text = "Hi, \(user.displayName ?? "Guest")"
            } else {
                UserName.text = "Hi, Guest"
            }
        }
   
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            let accessoryView = UIButton()
            let image = UIImage(named:"profile")

            accessoryView.setImage(image, for: .normal)
            accessoryView.frame.size = CGSize(width: 34, height: 34)
            let largeTitleView = navigationController?.navigationBar.subviews.first { subview in
                return String(describing: type(of: subview)) == "_UINavigationBarLargeTitleView"
            }
            largeTitleView?.perform (Selector(("setAccessoryView:")), with: accessoryView)
            largeTitleView?.perform (Selector(("setAlignAccessoryViewToTitleBaseline:")), with: nil)
            largeTitleView?.perform(Selector (("updateContent") ))
        }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sampleUser.picksforyou.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickforyouCell", for: indexPath) as! HomePickForYouCell
        let pick = sampleUser.picksforyou[indexPath.row]
        cell.pickImage.image = UIImage(named: pick.imageURL)
        cell.picktitle.text = pick.name
        cell.pickcategory.text = getCategoryName(for: pick.categoryId)
        
        cell.pickscoreLabel.text = "\(pick.healthScore)"
        
        cell.pickview.layer.cornerRadius = cell.pickview.frame.height/2
        
        if pick.healthScore < 40 {
            cell.pickview.layer.backgroundColor = UIColor.systemRed.cgColor
                }
        else if pick.healthScore < 75 {
                
            cell.pickview.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
                }
        else if pick.healthScore <= 100 {
            cell.pickview.layer.backgroundColor = UIColor.systemGreen.cgColor
                }
        cell.layer.cornerRadius = 14
        return cell
        
    }
    
    
    func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {(section,env)->NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.6), heightDimension: .absolute(300))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
          
            let section = NSCollectionLayoutSection(group: group)
          
            section.orthogonalScrollingBehavior = .continuous
            return section
            
            
        }
        
        return layout
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sampleUser.recentlyViewedProducts.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentScansCell", for: indexPath) as! RecentScansCell
        let product = sampleUser.recentlyViewedProducts[indexPath.row]
        cell.ProductImage.image = UIImage(named: product.imageURL)
        cell.ProductName.text = product.name
        cell.ProductScore.text = "\(product.healthScore)"
        cell.ProductScoreView.layer.cornerRadius = cell.ProductScoreView.frame.height/2
        
        if product.healthScore < 40 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemRed.cgColor
                }
        else if product.healthScore < 75 {
                
            cell.ProductScoreView.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
                }
        else if product.healthScore <= 100 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemGreen.cgColor
                }
        cell.layer.cornerRadius = 8
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    // MARK: - Table View Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        let selectedProduct = sampleUser.recentlyViewedProducts[indexPath.row]
     
        performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct)
    }
   
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        let verticalPadding: CGFloat = 4
        let maskLayer = CALayer()
        maskLayer.cornerRadius = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: 0, dy: verticalPadding/2)
        cell.layer.mask = maskLayer
    }
    
    
    func getCategoryName(for categoryId: UUID) -> String {
            if let category = Categories.first(where: { $0.id == categoryId }) {
                return category.name
            }
            return "Unknown Category"
        }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showproductdetailsfromhome",
               let destinationVC = segue.destination as? ProductDetailsViewController,
               let selectedProduct = sender as? Product {
                destinationVC.product = selectedProduct
            }
    
        }

        // MARK: - Collection View Methods
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let selectedProduct = sampleUser.picksforyou[indexPath.row]
           
            performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct)
        }

      
    
    @IBAction func ProfileButton(_ sender: Any) {
        
    }
   
        
}
