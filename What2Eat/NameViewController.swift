import UIKit

protocol NameViewControllerDelegate: AnyObject {
    func didEnterName(_ name: String)
}

class NameViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var enterLabel: UILabel!
    
    // MARK: - Delegate
    weak var delegate: NameViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

       
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
        }
    

    
    // MARK: - Actions
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please enter your name.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        delegate?.didEnterName(name)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Dismissal
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
