import UIKit

class ScoringMethodologyViewController: UIViewController {
    // MARK: - UI Components
    
    private lazy var navigationBar: UINavigationBar = {
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        navBar.barTintColor = .white
        navBar.isTranslucent = false
        
        let navItem = UINavigationItem(title: "Health Scoring")
        navItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(dismissViewController)
        )
        navBar.items = [navItem]
        
        return navBar
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.backgroundColor = .clear
        return scroll
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        return stackView
    }()
    
    // Scoring Overview Section
    private lazy var scoringOverviewCard = createInformationCard(
        title: "Health Scoring Overview",
        description: "Our innovative scoring system transforms complex nutritional information into a simple, intuitive 0-100 scale. This helps you quickly understand the nutritional value of your food choices."
    )
    
    // Calculation Method Section
    private lazy var calculationMethodCard = createInformationCard(
        title: "How We Calculate the Score",
        description: "We analyze multiple nutritional factors:\n\n• Negative Factors (Deduct Points)\n- Calories\n- Sugar Content\n- Saturated Fat\n- Sodium Levels\n\n• Positive Factors (Add Points)\n- Dietary Fiber\n- Protein\n- Fruits & Vegetables\n- Nuts & Healthy Ingredients"
    )
    
    // Score Interpretation Section
    private lazy var scoreInterpretationCard = createScoreInterpretationView()
    
    // Disclaimer Section
    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "Nutrition Scoring is a guide. Always consult with a healthcare professional for personalized dietary advice."
        label.textColor = .gray
        label.font = .systemFont(ofSize: 12, weight: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1)
        
        // Add subviews
        view.addSubview(navigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // Add content to stack view
        [
            scoringOverviewCard,
            calculationMethodCard,
            scoreInterpretationCard,
            disclaimerLabel
        ].forEach { contentStackView.addArrangedSubview($0) }
        
        // Setup Constraints
        setupConstraints()
    }
    
    private func setupConstraints() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Navigation Bar
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content Stack View
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func createInformationCard(title: String, description: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 15
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.1
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        return containerView
    }
    
    private func createScoreInterpretationView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 15
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.1
        
        let titleLabel = UILabel()
        titleLabel.text = "Score Interpretation"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        
        let scoreRangeStackView = UIStackView()
        scoreRangeStackView.axis = .horizontal
        scoreRangeStackView.distribution = .fillEqually
        scoreRangeStackView.spacing = 10
        
        let ranges = [
            (range: "0-40", color: UIColor.systemRed, description: "Low Nutritional Value"),
            (range: "40-70", color: UIColor.systemYellow, description: "Moderate Nutrition"),
            (range: "70-100", color: UIColor.systemGreen, description: "High Nutritional Quality")
        ]
        
        ranges.forEach { rangeData in
            let rangeView = createScoreRangeView(range: rangeData.range, color: rangeData.color, description: rangeData.description)
            scoreRangeStackView.addArrangedSubview(rangeView)
        }
        
        let mainStackView = UIStackView(arrangedSubviews: [titleLabel, scoreRangeStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 15
        
        containerView.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        return containerView
    }
    
    private func createScoreRangeView(range: String, color: UIColor, description: String) -> UIView {
        let containerView = UIView()
        
        let colorView = UIView()
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 10
        
        let rangeLabel = UILabel()
        rangeLabel.text = range
        rangeLabel.textAlignment = .center
        rangeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        rangeLabel.textColor = .white
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [colorView, rangeLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            colorView.heightAnchor.constraint(equalToConstant: 50),
            colorView.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        return containerView
    }
    
    // MARK: - Action Methods
    
    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}
