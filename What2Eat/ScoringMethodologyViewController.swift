import UIKit

class ScoringMethodologyViewController: UIViewController {
    // MARK: - UI Components
    
    private lazy var navigationBar: UINavigationBar = {
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        navBar.barTintColor = .white
        navBar.isTranslucent = false
        
        let navItem = UINavigationItem(title: "Scoring and Nutrition Guide")
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
        description: NSAttributedString(string: "Our innovative scoring system transforms complex nutritional information into a simple, intuitive 0-100 scale. This helps you quickly understand the nutritional value of your food choices.")
    )
    
    // Calculation Method Section
    private lazy var calculationMethodCard = createInformationCard(
        title: "How We Calculate the Score",
        description: createCalculationMethodDescription()
    )
    
    // Personalized Nutrition Section
    private lazy var personalizedNutritionCard = createInformationCard(
        title: "Personalized Nutrition Calculation",
        description: createPersonalizedNutritionDescription()
    )
    
    // Score Interpretation Section
    private lazy var scoreInterpretationCard = createScoreInterpretationView()
    
    // References Section
    private lazy var referencesCard = createInformationCard(
        title: "Citations and References",
        description: createReferencesDescription()
    )
    
    // Disclaimer Section
    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "Nutrition Scoring and Recommended Dietery Allowances (RDAs) is a guide. Always consult with a healthcare professional for personalized dietary advice."
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
        
        view.addSubview(navigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        [
            scoringOverviewCard,
            calculationMethodCard,
            personalizedNutritionCard,
            scoreInterpretationCard,
            referencesCard,
            disclaimerLabel
        ].forEach { contentStackView.addArrangedSubview($0) }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func createInformationCard(title: String, description: NSAttributedString) -> UIView {
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
        
        let descriptionTextView = UITextView()
        descriptionTextView.isEditable = false
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.attributedText = description
        descriptionTextView.textColor = .darkGray
        descriptionTextView.font = .systemFont(ofSize: 16, weight: .medium)
        descriptionTextView.textContainerInset = .zero
        descriptionTextView.textContainer.lineFragmentPadding = 0
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionTextView])
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
    
    private func createCalculationMethodDescription() -> NSAttributedString {
        let plainText = "We analyze multiple nutritional factors:\n\n• Negative Factors (Deduct Points)\n- Calories\n- Sugar Content\n- Saturated Fat\n- Sodium Levels\n\n• Positive Factors (Add Points)\n- Dietary Fiber\n- Protein\n- Fruits & Vegetables\n- Nuts & Healthy Ingredients\n\nOur scoring system is inspired by the Nutri Score labeling system, which rates food products on a scale from A to E based on their nutritional quality. "
        let linkText = "Learn more about Nutri-Score"
        let url = "https://pmc.ncbi.nlm.nih.gov/articles/PMC9421047/"
        
        let attributedString = NSMutableAttributedString(string: plainText)
        let linkAttributedString = NSAttributedString(
            string: linkText,
            attributes: [.link: URL(string: url)!]
        )
        attributedString.append(linkAttributedString)
        
        return attributedString
    }
    
    private func createPersonalizedNutritionDescription() -> NSAttributedString {
        let plainText = "Recommended Dietary Allowance (RDA) is calculated based on individual factors such as gender, age, weight, height, and activity level to provide personalized nutrition recommendations. This calculation follows the guidelines set by the Indian Council of Medical Research (ICMR). "
        let linkText = "ICMR Dietary Guidelines"
        let url = "https://www.nin.res.in/rdabook/brief_note.pdf"
        
        let attributedString = NSMutableAttributedString(string: plainText)
        let linkAttributedString = NSAttributedString(
            string: linkText,
            attributes: [.link: URL(string: url)!]
        )
        attributedString.append(linkAttributedString)
        
        return attributedString
    }
    
    private func createReferencesDescription() -> NSAttributedString {
        let references = [
            ("Nutri Score: A labeling system rating food products based on nutritional quality.", "https://pmc.ncbi.nlm.nih.gov/articles/PMC9421047/"),
            ("ICMR Dietary Guidelines: Recommended Dietary Allowances for the Indian population.", "https://www.nin.res.in/rdabook/brief_note.pdf")
        ]
        
        let attributedString = NSMutableAttributedString()
        for (index, (desc, url)) in references.enumerated() {
            let refText = "\(index + 1). \(desc) "
            let linkText = "(\(url))\n\n"
            
            attributedString.append(NSAttributedString(string: refText))
            attributedString.append(NSAttributedString(
                string: linkText,
                attributes: [.link: URL(string: url)!]
            ))
        }
        
        return attributedString
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
