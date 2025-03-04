import UIKit

class ScoringMethodologyViewController: UIViewController {
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 25
        stack.alignment = .fill
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Scoring Methodology"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()
    
    private let introLabel: UILabel = {
        let label = UILabel()
        label.text = "In the What2Eat app, we use the NutriScore system to help you understand the nutritional quality of food. Each product gets a score from 0 to 100—higher scores mean healthier choices."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let howCalculatedLabel: UILabel = {
        let label = UILabel()
        label.text = "The score is calculated by balancing the ‘less healthy’ and ‘more healthy’ parts of a food:\n\n- **Less Healthy Factors**: We look at calories, sugars, saturated fat, and sodium. Foods with higher amounts of these get more negative points.\n\n- **More Healthy Factors**: We check fiber, protein, and the amount of fruits, vegetables, and nuts. These add positive points.\n\nThe final score comes from subtracting the positive points from the negative ones, then turning it into a simple 0-100 number."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let understandingLabel: UILabel = {
        let label = UILabel()
        label.text = "Here’s what the scores mean:\n- **0 to 40**: Red - Less healthy options\n- **40 to 70**: Yellow - Moderate options\n- **70 to 100**: Green - Healthier options\nWe use colors so you can quickly see how a food stacks up!"
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let factorsLabel: UILabel = {
        let label = UILabel()
        label.text = "These are the key things we look at:\n- Calories (energy)\n- Sugars\n- Saturated fat\n- Sodium (salt)\n- Fiber\n- Protein\n- Fruits, vegetables, and nuts\nEach one plays a role in deciding if a food is more or less healthy."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "The score is just a guide to help you choose—it’s not a replacement for advice from a doctor or nutritionist."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    private let scoreRangeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        return view
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6 // Light gray background for a modern look
        setupScoreRangeView()
        setupStackView()
        setupScrollView()
    }
    
    // MARK: - Setup Methods
    
    private func setupScoreRangeView() {
        // Gradient background for the score range
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.red.cgColor, UIColor.yellow.cgColor, UIColor.green.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 40) // Adjusted later via constraint
        gradientLayer.cornerRadius = 10
        scoreRangeView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Range labels
        let redLabel = UILabel()
        redLabel.text = "0-40"
        redLabel.textAlignment = .center
        redLabel.font = .systemFont(ofSize: 14, weight: .medium)
        redLabel.textColor = .darkGray
        
        let yellowLabel = UILabel()
        yellowLabel.text = "40-70"
        yellowLabel.textAlignment = .center
        yellowLabel.font = .systemFont(ofSize: 14, weight: .medium)
        yellowLabel.textColor = .darkGray
        
        let greenLabel = UILabel()
        greenLabel.text = "70-100"
        greenLabel.textAlignment = .center
        greenLabel.font = .systemFont(ofSize: 14, weight: .medium)
        greenLabel.textColor = .darkGray
        
        // Stack for labels
        let labelStack = UIStackView(arrangedSubviews: [redLabel, yellowLabel, greenLabel])
        labelStack.axis = .horizontal
        labelStack.distribution = .fillEqually
        labelStack.spacing = 10
        
        // Add to scoreRangeView
        scoreRangeView.addSubview(labelStack)
        
        // Constraints
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelStack.centerXAnchor.constraint(equalTo: scoreRangeView.centerXAnchor),
            labelStack.centerYAnchor.constraint(equalTo: scoreRangeView.centerYAnchor),
            labelStack.widthAnchor.constraint(equalTo: scoreRangeView.widthAnchor, multiplier: 0.9)
        ])
        
        // Update gradient frame after layout
        DispatchQueue.main.async {
            gradientLayer.frame = self.scoreRangeView.bounds
        }
    }
    
    private func setupStackView() {
        // Add subtle card-like background to content sections
        [introLabel, howCalculatedLabel, understandingLabel, factorsLabel].forEach { label in
            let container = UIView()
            container.backgroundColor = .white
            container.layer.cornerRadius = 12
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.05
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.layer.shadowRadius = 4
            container.addSubview(label)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 15),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -15)
            ])
            stackView.addArrangedSubview(container)
        }
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(introLabel.superview!) // Add intro container
        stackView.addArrangedSubview(howCalculatedLabel.superview!) // Add how calculated container
        stackView.addArrangedSubview(understandingLabel.superview!) // Add understanding container
        stackView.addArrangedSubview(scoreRangeView)
        stackView.addArrangedSubview(factorsLabel.superview!) // Add factors container
        stackView.addArrangedSubview(disclaimerLabel)
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        // Scroll view constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content view constraints
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Stack view constraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            scoreRangeView.heightAnchor.constraint(equalToConstant: 60) // Fixed height for score range
        ])
    }
}
