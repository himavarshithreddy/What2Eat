import UIKit
import AVFoundation
import Vision
import FirebaseVertexAI
import Firebase
import FirebaseAuth

class ScanWithLabelViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    // Outlets connected in storyboard
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var scanningFrameView: UIView!
    
    @IBOutlet weak var SwitchLabelButton: UIButton!
    @IBOutlet weak var ScanningViewFrameHeight: NSLayoutConstraint!
    @IBOutlet weak var TorchIcon: UIBarButtonItem!
    @IBOutlet weak var CaptureButton: UIButton!
    var capturedImage: UIImage?
    private var captureSession: AVCaptureSession?
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var isTorchOn = false
    
    // Activity Indicator Components
    private var loadingContainerView: UIView!
    private var loadingIndicatorView: UIActivityIndicatorView!
    private var loadingLabel: UILabel!
    private var cancelButton: UIButton!
    private var blurEffectView: UIVisualEffectView!
    private var pulsingAnimationLayer: CALayer!
    
    // Processing state tracking
    private var isProcessing = false
    var productModel: ProductResponse?
    var computedHealthScore: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        self.tabBarController?.tabBar.isHidden = true
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
        configureScanningFrame()
        setupLoadingIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraPreviewView.bounds
        createOverlayMask()
    }
    
    // MARK: - Loading Indicator Setup
    private func setupLoadingIndicator() {
        // Create blur effect for background
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0.9
        
        // Create container view for loading components
        loadingContainerView = UIView()
        loadingContainerView.translatesAutoresizingMaskIntoConstraints = false
        loadingContainerView.backgroundColor = UIColor(white: 0.1, alpha: 0.7)
        loadingContainerView.layer.cornerRadius = 20
        loadingContainerView.clipsToBounds = true
        
        // Create pulsing background effect
        pulsingAnimationLayer = CALayer()
        pulsingAnimationLayer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
        pulsingAnimationLayer.cornerRadius = 20
        pulsingAnimationLayer.frame = CGRect(x: 0, y: 0, width: 220, height: 180)
        
        // Create modern activity indicator
        loadingIndicatorView = UIActivityIndicatorView(style: .large)
        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicatorView.color = .white
        loadingIndicatorView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        // Create loading text label
        loadingLabel = UILabel()
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = "Getting things ready..."
        loadingLabel.textColor = .white
        loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textAlignment = .center
        
        // Create cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        cancelButton.layer.cornerRadius = 15
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(cancelProcessing), for: .touchUpInside)
    }
    
    private func showLoadingIndicator() {
        guard !isProcessing else { return }
        isProcessing = true
        
        // Add blur effect to the view
        view.addSubview(blurEffectView)
        
        // Add pulsing animation layer to container
        loadingContainerView.layer.addSublayer(pulsingAnimationLayer)
        
        // Add loading components to container
        loadingContainerView.addSubview(loadingIndicatorView)
        loadingContainerView.addSubview(loadingLabel)
        loadingContainerView.addSubview(cancelButton)
        
        // Add container to view
        view.addSubview(loadingContainerView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            loadingContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingContainerView.widthAnchor.constraint(equalToConstant: 220),
            loadingContainerView.heightAnchor.constraint(equalToConstant: 180),
            
            loadingIndicatorView.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            loadingIndicatorView.topAnchor.constraint(equalTo: loadingContainerView.topAnchor, constant: 30),
            
            loadingLabel.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicatorView.bottomAnchor, constant: 15),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingContainerView.leadingAnchor, constant: 10),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingContainerView.trailingAnchor, constant: -10),
            
            cancelButton.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: loadingContainerView.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Start the activity indicator animation
        loadingIndicatorView.startAnimating()
        
        // Create pulsing animation
        createPulsingAnimation()
        
        // Animate container appearance
        loadingContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        loadingContainerView.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.loadingContainerView.alpha = 1
            self.loadingContainerView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.loadingContainerView.alpha = 0
                self.blurEffectView.alpha = 0
            }, completion: { _ in
                self.pulsingAnimationLayer.removeFromSuperlayer()
                self.loadingContainerView.removeFromSuperview()
                self.blurEffectView.removeFromSuperview()
                self.loadingIndicatorView.stopAnimating()
                self.isProcessing = false
            })
        }
    }
    private func createPulsingAnimation() {
        // Remove any existing animations
        pulsingAnimationLayer.removeAllAnimations()
        
        // Setup pulsing animation
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 0.2
        pulseAnimation.toValue = 0.6
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = Float.infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Apply animation
        pulsingAnimationLayer.add(pulseAnimation, forKey: "pulseAnimation")
    }
    
    @objc private func cancelProcessing() {
        // Create a flag to track cancellation
        hideLoadingIndicator()
        isProcessing = false
        
        // Stop any ongoing API tasks or processing tasks
        // This cancels the Task that would be running sendImageToGemini
        Task {
            // Cancel any running tasks
            Task.cancelAll()
        }
        
        // Hide the loading indicator
        
        // Give haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        // Reset UI state
        UIView.animate(withDuration: 0.3) {
            self.CaptureButton.isEnabled = true
            self.CaptureButton.alpha = 1.0
        }
        
        // Show a toast or small notification that the process was canceled
        showCanceledToast()
    }
    private func showCanceledToast() {
        let toastView = UIView()
        toastView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.9)
        toastView.layer.cornerRadius = 10
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        let toastLabel = UILabel()
        toastLabel.text = "Scanning canceled"
        toastLabel.textColor = .white
        toastLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        toastView.addSubview(toastLabel)
        view.addSubview(toastView)
        
        NSLayoutConstraint.activate([
            toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastView.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            toastView.heightAnchor.constraint(equalToConstant: 40),
            
            toastLabel.centerXAnchor.constraint(equalTo: toastView.centerXAnchor),
            toastLabel.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
            toastLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 15),
            toastLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -15)
        ])
        
        // Animate toast appearance and disappearance
        toastView.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                toastView.alpha = 0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        })
    }
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            print("Failed to create capture session.")
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // Camera input
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Error accessing the camera.")
            return
        }
        
        // Enable continuous auto focus if supported
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
        } catch {
            print("Error setting focus mode: \(error)")
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            cameraPreviewView.layer.addSublayer(previewLayer)
        }
        
        // Start session on a background thread
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
    
    // MARK: - Overlay Mask Creation
    private func createOverlayMask() {
        guard let overlayBounds = overlayView?.bounds else { return }
        
        let overlayPath = UIBezierPath(rect: overlayBounds)
        let scanFrameInOverlay = overlayView.convert(scanningFrameView.frame, from: scanningFrameView.superview)
        
        // Create transparent hole in overlay
        let holePath = UIBezierPath(rect: scanFrameInOverlay)
        overlayPath.append(holePath.reversing())
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = overlayPath.cgPath
        overlayView.layer.mask = maskLayer
    }
    
    private func configureScanningFrame() {
        scanningFrameView.layer.masksToBounds = true
        scanningFrameView.layer.borderWidth = 1.5
        scanningFrameView.clipsToBounds = true
        scanningFrameView.layer.borderColor = UIColor.systemOrange.cgColor
        CaptureButton.layer.cornerRadius = 35
        
        let cameraPreviewHeight = cameraPreviewView.bounds.height
        let scanningFrameHeight = CGFloat(cameraPreviewHeight * 0.7)
        ScanningViewFrameHeight.constant = scanningFrameHeight
        
        SwitchLabelButton.layer.cornerRadius = 8
        SwitchLabelButton.layer.masksToBounds = true
        SwitchLabelButton.layer.borderWidth = 1.5
        SwitchLabelButton.clipsToBounds = true
        SwitchLabelButton.layer.borderColor = UIColor.white.cgColor
    }
    
    // MARK: - Capture and Process Image
    @IBAction func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Show loading indicator
        showLoadingIndicator()
        
        // Start simulated progress updates
        startProgressUpdates()
    }
    
    private func startProgressUpdates() {
        var currentStep = 0
   let steps = [
            "Detecting edges...",
            "Analyzing label...",
            "Generating health score...",
            "Finalizing analysis...",
            "Almost done..."
          ];

        
        // Create a timer to update the loading message
        Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { [weak self] timer in
            guard let self = self, self.isProcessing else {
                timer.invalidate()
                return
            }
            
            if currentStep < steps.count {
                UIView.transition(with: self.loadingLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self.loadingLabel.text = steps[currentStep]
                }, completion: nil)
                currentStep += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let fullImage = UIImage(data: imageData) else {
            print("Failed to capture photo data.")
            hideLoadingIndicator()
            return
        }
        self.capturedImage = fullImage
        // First attempt auto edge detection
        detectEdges(in: fullImage) { detectedImage in
            if let autoCroppedImage = detectedImage {
                // Use auto-detected edges
                Task {
                    await self.sendImageToGemini(image: autoCroppedImage)
                }
            } else if let croppedImage = self.cropImageToHighlightedArea(fullImage) {
                // Fallback to cropping using the scanning frame
                Task {
                    await self.sendImageToGemini(image: croppedImage)
                }
                
            } else {
                print("Failed to obtain a valid image for text recognition.")
                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                }
            }
        }
    }
    
    /// Fallback cropping using the defined scanning frame overlay
    private func cropImageToHighlightedArea(_ image: UIImage) -> UIImage? {
        guard let previewLayer = previewLayer else { return nil }
        
        let previewRect = previewLayer.metadataOutputRectConverted(fromLayerRect: scanningFrameView.frame)
        let imageWidth = CGFloat(image.cgImage!.width)
        let imageHeight = CGFloat(image.cgImage!.height)
        
        let cropRect = CGRect(
            x: previewRect.origin.x * imageWidth,
            y: previewRect.origin.y * imageHeight,
            width: previewRect.size.width * imageWidth,
            height: previewRect.size.height * imageHeight
        )
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
    // MARK: - Auto Edge Detection using Vision
    private func detectEdges(in image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectRectanglesRequest { (request, error) in
            if let error = error {
                print("Rectangle detection error: \(error)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRectangleObservation],
                  let rectangle = observations.first else {
                completion(nil)
                return
            }
            
            // Convert normalized coordinates to image coordinates.
            let boundingBox = rectangle.boundingBox
            let imageRect = CGRect(
                x: boundingBox.origin.x * CGFloat(cgImage.width),
                y: (1 - boundingBox.origin.y - boundingBox.size.height) * CGFloat(cgImage.height),
                width: boundingBox.size.width * CGFloat(cgImage.width),
                height: boundingBox.size.height * CGFloat(cgImage.height)
            )
            
            if let croppedCGImage = cgImage.cropping(to: imageRect) {
                let croppedImage = UIImage(cgImage: croppedCGImage)
                completion(croppedImage)
            } else {
                completion(nil)
            }
        }
        
        // Configure detection parameters (adjust as needed)
        request.maximumObservations = 1
        request.minimumConfidence = 0.8
        request.minimumAspectRatio = 0.3
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform edge detection: \(error)")
                completion(nil)
            }
        }
    }
    
    @objc func backButtonTapped() {
        if let homeVC = navigationController?.viewControllers.first(where: { $0 is HomeViewController }) {
            navigationController?.popToViewController(homeVC, animated: true)
        }
    }
    
    // MARK: - Flashlight Control
    @objc func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            if isTorchOn {
                device.torchMode = .off
                TorchIcon.image = UIImage(systemName: "flashlight.off.fill")
            } else {
                try device.setTorchModeOn(level: 1.0)
                TorchIcon.image = UIImage(systemName: "flashlight.on.fill")
            }
            isTorchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Error: Unable to toggle flashlight - \(error)")
        }
    }
    
    @IBAction func TorchTapped(_ sender: Any) {
        toggleFlashlight()
    }
    
    // MARK: - Gallery and Barcode Switching
    @IBAction func GalleryButtonTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        // Show loading indicator when processing gallery image
        showLoadingIndicator()
        startProgressUpdates()
        
        Task {
            await self.sendImageToGemini(image: image)
        }
    }
    
    @IBAction func SwitchToBarcode(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func sendImageToGemini(image: UIImage) async {
        if !isProcessing {
                return
            }
        // Define JSON Schema with an extra "healthscore" field as strings
        let jsonSchema = Schema.object(
            properties: [
                "name":Schema.string(),
                "ingredients": Schema.array(items: .string()),
                "nutrition": Schema.array(
                    items: .object(
                        properties: [
                            "name": .string(),
                            "value": .float(), // nutrition values remain numeric
                            "unit": .string()
                        ]
                    )
                ),
                "healthscore": Schema.object(
                    properties: [
                        "Energy": .string(),
                        "Sugars": .string(),
                        "Sodium": .string(),
                        "Protein": .string(),
                        "Fiber": .string(),
                        "FruitsVegetablesNuts": .string(),
                        "SaturatedFat": .string()
                    ]
                )
            ]
        )
        
        let systemInstruction = """
        You are an advanced AI assistant specialized in extracting structured data from images of food packaging. Your task is to extract key details from the image, including ingredients, nutritional information, and a healthscore.

        Instructions:
        Name Extraction:
        - Analyse the Name of the product from the Given image
        - If cant find, analyse what could the name be.
        - The Name should be short and simple and should not contain more than 2 words.
        - It should represent the product
        
        Ingredients Extraction:
        - Identify the section labeled "Ingredients" or similar.
        - Extract the full list of ingredients while preserving their order.
        - Remove values and percentages from ingredient names (e.g., "Wheat Flour (63%)" should become "Wheat Flour").
        - Remove content inside brackets (e.g., "MILK PRODUCTS [WHEY POWDER & MILK SOLIDS]" should become "MILK PRODUCTS").
        - Retain food additive codes like "Emulsifier (E322)" or "Raising Agent (INS 500(ii))".
        - Ignore unnecessary words or unrelated text.

        Nutritional Information Extraction:
                - Identify the section labeled "Nutrition Information" or "Nutritional Facts".
                - Extract key nutrient names, values, and units (e.g., "Protein: 9.1 g").
                - Standardize nutrient names to match the following expected format (case-insensitive):
                  • "Energy" (instead of "Calories", "kcal", etc.)
                  • "Protein"
                  • "Total Fat" (instead of "Fat", "Total Fats", etc.)
                  • "Saturated Fat" (instead of "Saturated Fatty Acids", "Sat Fat", etc.)
                  • "Carbohydrates" (instead of "Total Carbohydrates", "Carbs", etc.)
                  • "Fiber" (instead of "Dietary Fiber", etc.)
                  • "Sugars"
                  • "Calcium"
                  • "Magnesium"
                  • "Iron"
                  • "Zinc"
                  • "Iodine"
                  • "Sodium"
                  • "Potassium"
                  • "Phosphorus"
                  • "Copper"
                  • "Selenium"
                  • "Vitamin A"
                  • "Vitamin C"
                  • "Vitamin D"
                  • "Vitamin E"
                  • "Thiamine" (instead of "Vitamin B1")
                  • "Riboflavin" (instead of "Vitamin B2")
                  • "Niacin" (instead of "Vitamin B3")
                  • "Vitamin B6"
                  • "Folate" (instead of "Vitamin B9", "Folic Acid")
                  • "Vitamin B12"
                - If a nutrient name does not match the above list, include it as-is.
                
        Healthscore Extraction:
        - From the nutritional data, extract only the following:
          • Energy
          • Sugars
          • Sodium
          • Protein
          • Fiber
          • FruitsVegetablesNuts (as a percentage)
          • SaturatedFat
        - Output these values as strings including their units (e.g., "481 kcal", "9.1 g").
        - If any value is missing, set it to "0".

        Handling OCR Noise & Inconsistencies:
        - Correct common OCR errors (e.g., ‘0’ misread as ‘O’, ‘l’ misread as ‘1’).
        - Use contextual understanding to extract accurate data even from messy text.
        - Ensure data is structured properly, avoiding missing or misclassified information.

        Output Format:
        - Return the extracted data in a structured JSON format with three keys:
          • "name": a string
          • "ingredients": an array of ingredient strings.
          • "nutrition": an array of objects (each with "name", "value", and "unit").
          • "healthscore": an object containing keys "Energy", "Sugars", "Sodium", "Protein", "Fiber", "FruitsVegetablesNuts", and "SaturatedFat", where each value is a string including the unit.
        - If any section is missing or unclear, return "ingredients": [] or "nutrition": [] or "healthscore": {}.

        Final Requirement:
        - Extract information as accurately as possible while handling formatting issues and OCR inconsistencies.
        - If the image does not appear to be a valid food product label or if the contents do not contain recognizable ingredients or nutritional information, return a JSON object with an "error" field containing a simple error message (e.g., "Invalid product label") and empty values for "ingredients", "nutrition", and "healthscore".
        """

        
        // Configure the generation parameters
        let generationConfig = GenerationConfig(
            temperature: 0.2,
            topP: 0.95,
            topK: 1,
            maxOutputTokens: 8100,
            responseMIMEType: "application/json",
            responseSchema: jsonSchema
        )
        
        // Initialize the generative model with Firebase Vertex AI using our system instruction
        let vertex = VertexAI.vertexAI()
        let model = vertex.generativeModel(
            modelName: "gemini-1.5-flash-002",
            generationConfig: generationConfig,
            systemInstruction: ModelContent(role: "system", parts: systemInstruction)
        )
        
        do {
            if !isProcessing {
                      return
                  }
            let prompt = "Extract the ingredients, nutritional information, and healthscore from this food label image and analyse what could be the name of the product."
            let response = try await model.generateContent(image, prompt)
            if !isProcessing {
                        return
                    }
            if let jsonResponse = response.text {
                print("Extracted JSON: \(jsonResponse)")
                DispatchQueue.main.async {
                    // Only proceed if not cancelled
                                   if self.isProcessing {
                                       // Hide loading indicator before navigating
                                       self.hideLoadingIndicator()
                                       self.capturedImage=image
                                       self.handleVertexResponse(jsonResponse)
                                   }
                }
            } else {
                if self.isProcessing {
                               print("No structured output received.")
                               DispatchQueue.main.async {
                                   self.hideLoadingIndicator()
                                   self.showErrorAlert(message: "Failed to analyze the image. Please try again.")
                               }
                           }
            }
        } catch {
            if self.isProcessing {
                        print("Error calling Gemini AI: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.hideLoadingIndicator()
                            self.showErrorAlert(message: "Error analyzing image: \(error.localizedDescription)")
                        }
                    }
                }    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Analysis Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToDetailsViewController(analysis: ProductAnalysis) {
            guard let detailsVC = storyboard?.instantiateViewController(withIdentifier: "LabelScanDetailsVC") as? LabelScanDetailsViewController else {
                print("LabelScanDetailsViewController not found")
                return
            }
            
            detailsVC.capturedImage = self.capturedImage
            detailsVC.productModel = self.productModel
            detailsVC.healthScore = self.computedHealthScore
            detailsVC.productAnalysis = analysis
            
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(detailsVC, animated: true)
            }
        }
    func handleVertexResponse(_ jsonResponse: String) {
        guard let jsonData = jsonResponse.data(using: .utf8) else {
            print("Error converting response to Data")
            showErrorAlert(message: "Failed to process the image data. Please try again.")
            return
        }

        do {
            let decodedProduct = try JSONDecoder().decode(ProductResponse.self, from: jsonData)
            
            // Check if both ingredients and nutrition arrays are empty
            if decodedProduct.ingredients.isEmpty && decodedProduct.nutrition.isEmpty {
                // Show error alert instead of proceeding
                showErrorAlert(message: "Could not detect any ingredients or nutritional information. Please try again with a clearer image.")
                return
            }
            
            self.productModel = decodedProduct
            fetchUserData { user in
                            guard let user = user else {
                                self.showErrorAlert(message: "Unable to fetch user data.")
                                return
                            }
                            
                            let analysis = generateProsAndCons(product: decodedProduct, user: user)
                            print(user)
                            
                            self.fetchHealthScore(from: decodedProduct.healthscore) { [weak self] score in
                                DispatchQueue.main.async {
                                    self?.computedHealthScore = score
                                    self?.navigateToDetailsViewController(analysis: analysis)
                                }
                            }
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                        showErrorAlert(message: "Error analyzing the product label. Please try again.")
                    }
                }
    
    
    
    private func fetchHealthScore(from healthscore: HealthScore, completion: @escaping (Int) -> Void) {
            let url = URL(string: "https://calculatehealthscore-ujjjq2ceua-uc.a.run.app")!
            
            let requestBody: [String: Any] = [
                "nutrition": [
                    "energy": healthscore.Energy,
                    "sugars": healthscore.Sugars,
                    "sodium": healthscore.Sodium,
                    "protein": healthscore.Protein,
                    "fiber": healthscore.Fiber,
                    "fruitsVegetablesNuts": healthscore.FruitsVegetablesNuts,
                    "saturatedFat": healthscore.SaturatedFat
                ]
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print("Failed to serialize request body")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error making request: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    let healthScoreResponse = try JSONDecoder().decode(HealthScoreResponse.self, from: data)
                    completion(healthScoreResponse.healthScore)
                } catch {
                    print("Error decoding health score response: \(error)")
                }
            }
            
            task.resume()
        }
    
}
extension Task where Success == Never, Failure == Never {
    static func cancelAll() {
       
    }
}
