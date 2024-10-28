//
//  ScanViewController.swift
//  What2Eat
//
//  Created by admin20 on 28/10/24.
//

import UIKit
import AVFoundation

// MARK: - ScanViewController
class ScanViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Scan Type"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let barcodeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Scan With Barcode", for: .normal)
        button.backgroundColor = .systemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let ingredientsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Scan With Ingredients", for: .normal)
        button.backgroundColor = .systemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(barcodeButton)
        view.addSubview(ingredientsButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            barcodeButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            barcodeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            barcodeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            barcodeButton.heightAnchor.constraint(equalToConstant: 56),
            
            ingredientsButton.topAnchor.constraint(equalTo: barcodeButton.bottomAnchor, constant: 20),
            ingredientsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ingredientsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            ingredientsButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        barcodeButton.addTarget(self, action: #selector(openBarcodeScan), for: .touchUpInside)
        ingredientsButton.addTarget(self, action: #selector(openIngredientsScan), for: .touchUpInside)
    }
    
    @objc private func openBarcodeScan() {
        let scanVC = ScanCameraViewController(scanType: .barcode)
        navigationController?.pushViewController(scanVC, animated: true)
    }
    
    @objc private func openIngredientsScan() {
        let scanVC = ScanCameraViewController(scanType: .ingredients)
        navigationController?.pushViewController(scanVC, animated: true)
    }
}

// MARK: - ScanCameraViewController
class ScanCameraViewController: UIViewController {
    
    enum ScanType {
        case barcode
        case ingredients
        
        var title: String {
            switch self {
            case .barcode: return "Find a barcode to scan"
            case .ingredients: return "Find Ingredients to scan"
            }
        }
    }
    
    private let scanType: ScanType
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let scanFrameView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let uploadButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .black
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let toggleFlashButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .black
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let switchScanButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(scanType: ScanType) {
        self.scanType = scanType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        navigationItem.title = scanType.title
        navigationController?.navigationBar.tintColor = .white
        
        view.addSubview(scanFrameView)
        view.addSubview(instructionLabel)
        view.addSubview(uploadButton)
        view.addSubview(toggleFlashButton)
        view.addSubview(switchScanButton)
        
        switchScanButton.setTitle(scanType == .barcode ? "Scan With Ingredients" : "Scan with Barcode", for: .normal)
        instructionLabel.text = scanType.title
        
        NSLayoutConstraint.activate([
            scanFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanFrameView.widthAnchor.constraint(equalToConstant: 250),
            scanFrameView.heightAnchor.constraint(equalToConstant: 250),
            
            instructionLabel.bottomAnchor.constraint(equalTo: scanFrameView.topAnchor, constant: -20),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.heightAnchor.constraint(equalToConstant: 40),
            
            uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButton.widthAnchor.constraint(equalToConstant: 50),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            toggleFlashButton.centerYAnchor.constraint(equalTo: scanFrameView.centerYAnchor),
            toggleFlashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            toggleFlashButton.widthAnchor.constraint(equalToConstant: 50),
            toggleFlashButton.heightAnchor.constraint(equalToConstant: 50),
            
            switchScanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            switchScanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchScanButton.widthAnchor.constraint(equalToConstant: 200),
            switchScanButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        toggleFlashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        switchScanButton.addTarget(self, action: #selector(switchScanType), for: .touchUpInside)
    }
    
    private func setupCamera() {
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    self?.initializeCameraSession()
                }
            } else {
                self?.showCameraPermissionAlert()
            }
        }
    }
    
    private func initializeCameraSession() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession,
              let backCamera = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.layer.bounds
            
            if let previewLayer = previewLayer {
                view.layer.insertSublayer(previewLayer, at: 0)
            }
            
            captureSession.startRunning()
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please allow camera access to use the scanner",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func uploadButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    @objc private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        try? device.lockForConfiguration()
        
        if device.torchMode == .off {
            try? device.setTorchModeOn(level: 1.0)
            toggleFlashButton.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal)
        } else {
            device.torchMode = .off
            toggleFlashButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
        }
        
        device.unlockForConfiguration()
    }
    
    @objc private func switchScanType() {
        let newScanType: ScanType = scanType == .barcode ? .ingredients : .barcode
        let scanVC = ScanCameraViewController(scanType: newScanType)
        navigationController?.setViewControllers([scanVC], animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ScanCameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            // Handle the selected image here
            // You can process it for barcode or ingredients based on scanType
            print("Image selected")
        }
        
        picker.dismiss(animated: true)
    }
}
