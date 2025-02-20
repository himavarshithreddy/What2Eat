import UIKit
import AVFoundation
import Vision
import FirebaseVertexAI

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
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let fullImage = UIImage(data: imageData) else {
            print("Failed to capture photo data.")
            return
        }
        self.capturedImage = fullImage
        // First attempt auto edge detection
        detectEdges(in: fullImage) { detectedImage in
            if let autoCroppedImage = detectedImage {
                // Use auto-detected edges
                self.recognizeText(in: autoCroppedImage)
            } else if let croppedImage = self.cropImageToHighlightedArea(fullImage) {
                // Fallback to cropping using the scanning frame
                Task {
                    await self.sendExtractedTextToGemini(extractedText: croppedImage)
                       }
                self.recognizeText(in: croppedImage)
            } else {
                print("Failed to obtain a valid image for text recognition.")
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
    
    // MARK: - Text Recognition
    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var detectedText = ""
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    detectedText += "\(topCandidate.string)\n"
                }
            }
            
            // Send extracted text to Gemini API
                     
        }
        
        request.recognitionLevel = .accurate
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Text recognition failed: \(error)")
            }
        }
        DispatchQueue.main.async {
            self.navigateToLabelScanDetails()
        }
    }
    
    private func showTextAlert(_ text: String) {
        print(text)
        let alertController = UIAlertController(title: "Detected Text",
                                                message: text,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
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
        Task {
            await self.sendExtractedTextToGemini(extractedText: image)
               }
        recognizeText(in: image)
    }
    
    @IBAction func SwitchToBarcode(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    

    func sendExtractedTextToGemini(extractedText: UIImage) async {
        // Define JSON Schema with an extra "healthscore" field as strings
        let jsonSchema = Schema.object(
            properties: [
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
        - Ensure proper formatting and structure for readability.
        
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
        - If something is not present give 0.
        
        Handling OCR Noise & Inconsistencies:
        - Correct common OCR errors (e.g., ‘0’ misread as ‘O’, ‘l’ misread as ‘1’).
        - Use contextual understanding to extract accurate data even from messy text.
        - Ensure data is structured properly, avoiding missing or misclassified information.
        
        Output Format:
        - Return the extracted data in a structured JSON format with three keys:
          • "ingredients": an array of ingredient strings.
          • "nutrition": an array of objects (each with "name", "value", and "unit").
          • "healthscore": an object containing keys "Energy", "Sugars", "Sodium", "Protein", "Fiber", "FruitsVegetablesNuts", and "SaturatedFat", where each value is a string including the unit.
        - If any section is missing or unclear, return "ingredients": [] or "nutrition": [] or "healthscore": {}.
        
        Final Requirement:
        - Extract information as accurately as possible while handling formatting issues and OCR inconsistencies.
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
            let prompt = "Extract the ingredients, nutritional information, and healthscore from this food label image."
            let response = try await model.generateContent(extractedText, prompt)
            if let jsonResponse = response.text {
                print("Extracted JSON: \(jsonResponse)")
                DispatchQueue.main.async {
                    // For example, update your UI with the structured JSON output.
                }
            } else {
                print("No structured output received.")
            }
        } catch {
            print("Error calling Gemini AI: \(error.localizedDescription)")
        }
    }
    func navigateToLabelScanDetails() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let labelScanDetailsVC = mainStoryboard.instantiateViewController(withIdentifier: "LabelScanDetailsVC") as? LabelScanDetailsViewController {
            // Since you have no scanned data, you’re not setting any properties here.
            navigationController?.pushViewController(labelScanDetailsVC, animated: true)
        }
    }

}
