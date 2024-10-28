//
//  ExploreViewController.swift
//  What2Eat
//
//  Created by admin20 on 28/10/24.
//
import UIKit

class ExploreViewController: UIViewController {
    
    // MARK: - Properties
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "What are you looking for?"
        searchBar.backgroundImage = UIImage()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Browse Categories"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Explore"
        
        view.addSubview(searchBar)
        view.addSubview(categoryLabel)
        view.addSubview(categoryCollectionView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            categoryLabel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            categoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            categoryCollectionView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            categoryCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCollectionView() {
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        
        // Calculate cell size based on collection view width
        if let layout = categoryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let width = (view.frame.width - 48) / 2 // 16 padding on each side and 16 spacing between items
            layout.itemSize = CGSize(width: width, height: width)
        }
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension ExploreViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8 // Number of categories
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        
        // Configure cell based on index
        let categories = ["Bakery", "Juices", "Dairy", "Breakfast Foods", "Frozen Food", "Cereal Bars", "Sauces", "Desserts"]
        cell.configure(with: categories[indexPath.item])
        
        return cell
    }
}

// MARK: - CategoryCell
class CategoryCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(imageView)
        imageView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}
