//
//  HomeViewController.swift
//  What2Eat
//
//  Created by admin20 on 27/10/24.
//

import UIKit




class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome, Human"
        label.font = .systemFont(ofSize: 24, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let forYouLabel: UILabel = {
        let label = UILabel()
        label.text = "For you"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let forYouArrow: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let forYouCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 160, height: 200)
        layout.minimumLineSpacing = 15
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let historyLabel: UILabel = {
        let label = UILabel()
        label.text = "History"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let historyArrow: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let historyCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 160, height: 200)
        layout.minimumLineSpacing = 15
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionViews()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(welcomeLabel)
        contentView.addSubview(profileImageView)
        contentView.addSubview(forYouLabel)
        contentView.addSubview(forYouArrow)
        contentView.addSubview(forYouCollectionView)
        contentView.addSubview(historyLabel)
        contentView.addSubview(historyArrow)
        contentView.addSubview(historyCollectionView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Welcome Label
            welcomeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Profile Image
            profileImageView.centerYAnchor.constraint(equalTo: welcomeLabel.centerYAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            profileImageView.widthAnchor.constraint(equalToConstant: 30),
            profileImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // For You Label
            forYouLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 30),
            forYouLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // For You Arrow
            forYouArrow.centerYAnchor.constraint(equalTo: forYouLabel.centerYAnchor),
            forYouArrow.leadingAnchor.constraint(equalTo: forYouLabel.trailingAnchor, constant: 8),
            
            // For You Collection View
            forYouCollectionView.topAnchor.constraint(equalTo: forYouLabel.bottomAnchor, constant: 15),
            forYouCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            forYouCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            forYouCollectionView.heightAnchor.constraint(equalToConstant: 200),
            
            // History Label
            historyLabel.topAnchor.constraint(equalTo: forYouCollectionView.bottomAnchor, constant: 30),
            historyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // History Arrow
            historyArrow.centerYAnchor.constraint(equalTo: historyLabel.centerYAnchor),
            historyArrow.leadingAnchor.constraint(equalTo: historyLabel.trailingAnchor, constant: 8),
            
            // History Collection View
            historyCollectionView.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 15),
            historyCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            historyCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            historyCollectionView.heightAnchor.constraint(equalToConstant: 200),
            historyCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupCollectionViews() {
        // Register cells
        forYouCollectionView.register(FoodItemCell.self, forCellWithReuseIdentifier: "FoodItemCell")
        historyCollectionView.register(FoodItemCell.self, forCellWithReuseIdentifier: "FoodItemCell")
        
        // Set delegates
        forYouCollectionView.delegate = self
        forYouCollectionView.dataSource = self
        historyCollectionView.delegate = self
        historyCollectionView.dataSource = self
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // Replace with actual data count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodItemCell", for: indexPath) as! FoodItemCell
        // Configure cell
        return cell
    }
}

// MARK: - FoodItemCell
class FoodItemCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
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
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(scoreView)
        scoreView.addSubview(scoreLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            scoreView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            scoreView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            scoreView.widthAnchor.constraint(equalToConstant: 30),
            scoreView.heightAnchor.constraint(equalToConstant: 30),
            
            scoreLabel.centerXAnchor.constraint(equalTo: scoreView.centerXAnchor),
            scoreLabel.centerYAnchor.constraint(equalTo: scoreView.centerYAnchor)
        ])
    }
    
    func configure(with title: String, score: Int, image: UIImage?) {
        titleLabel.text = title
        scoreLabel.text = "\(score)"
        imageView.image = image
    }
}
