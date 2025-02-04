import UIKit
import AVFoundation
import Vision
import FirebaseAuth
import FirebaseFirestore

class BarcodeScannerViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var scanningFrameView: UIView!
    @IBOutlet weak var SwitchScanButton: UIButton!
    @IBOutlet weak var TorchIcon: UIBarButtonItem!
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var isTorchOn = false
   
    override func viewDidLoad() {
        super.viewDidLoad()
        configureScanningFrame()
        self.tabBarController?.tabBar.isHidden = true
      
        setupCamera()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        if let captureSession = captureSession, !captureSession.isRunning {
               DispatchQueue.global(qos: .background).async {
                   captureSession.startRunning()
               }
           }
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
    private func configureScanningFrame() {
        scanningFrameView.layer.masksToBounds = true
        scanningFrameView.layer.borderWidth = 1.5
        scanningFrameView.clipsToBounds = true
        scanningFrameView.layer.borderColor = UIColor.systemOrange.cgColor
        SwitchScanButton.layer.cornerRadius=8
        SwitchScanButton.layer.masksToBounds = true
        SwitchScanButton.layer.borderWidth = 1.5
        SwitchScanButton.clipsToBounds = true
        SwitchScanButton.layer.borderColor = UIColor.white.cgColor
    }
    
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error: Unable to initialize camera input - \(error)")
            return
        }
        
        if (captureSession?.canAddInput(videoInput) == true) {
            captureSession?.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession?.canAddOutput(metadataOutput) == true) {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                    .aztec,
                    .code39,
                    .code39Mod43,
                    .code93,
                    .code128,
                    .dataMatrix,
                    .ean8,
                    .ean13,
                    .interleaved2of5,
                    .itf14,
                    .pdf417,
                    .qr,
                    .upce
                ] // Set barcode types
        }
        
     
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        cameraPreviewView.layer.addSublayer(previewLayer!)
        
       
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            
            guard let image = info[.originalImage] as? UIImage else {
                print("No image found")
                return
            }
            
            
            guard let cgImage = image.cgImage else {
                print("Could not get CGImage")
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
           
            let request = VNDetectBarcodesRequest { [weak self] request, error in
                if let error = error {
                    print("Error detecting barcode: \(error)")
                    return
                }
                
              
                if let observations = request.results as? [VNBarcodeObservation] {
                    DispatchQueue.main.async {
                        self?.processDetectedBarcodes(observations)
                    }
                }
            }
            
            // Perform the request
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("Error performing barcode detection: \(error)")
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        // MARK: - Process Detected Barcodes
        private func processDetectedBarcodes(_ observations: [VNBarcodeObservation]) {
            guard !observations.isEmpty else {
                let alert = UIAlertController(title: "No Barcode Found",
                                            message: "No barcode was detected in the selected image.",
                                            preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            
           
            if let firstBarcode = observations.first,
               let payloadString = firstBarcode.payloadStringValue {
                displayResult(with: payloadString)
                
            }
        }
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

    
    // MARK: - Overlay Mask Creation
    private func createOverlayMask() {
        
        let overlayPath = UIBezierPath(rect: overlayView.bounds)
        
       
        let scanFrameInOverlay = overlayView.convert(scanningFrameView.frame, from: scanningFrameView.superview)
        
       
        let holePath = UIBezierPath(rect: scanFrameInOverlay)
        overlayPath.append(holePath.reversing())
        
       
        let maskLayer = CAShapeLayer()
        maskLayer.path = overlayPath.cgPath
        overlayView.layer.mask = maskLayer
       
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for metadata in metadataObjects {
            guard let readableObject = metadata as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { continue }
            
            // Barcode detected, stop running the session
            captureSession?.stopRunning()
            
            // Show result in an alert
            displayResult(with: stringValue)
            break
        }
    }
    
   // MARK: - Display Alert with Barcode Result
    private func displayResult(with barcode: String) {
        // Fetch the product ID from Firebase based on the scanned barcode.
        fetchProductIdFromFirebase(barcode: barcode) { [weak self] productId in
            guard let self = self else { return }
            
            if let productId = productId {
                print("Fetched Product ID from Firebase: \(productId)")
                
                // Save the product ID to recent scans.
                self.saveToRecentScans(productId: productId) { success in
                    // Regardless of whether saving succeeded, navigate to the details screen.
                    DispatchQueue.main.async {
                        self.navigateToProductDetails(with: productId)
                    }
                }
            } else {
                print("No Product ID found for the given barcode in Firebase")
                // If no product ID is found for the scanned barcode, show an alert.
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Product Not Found",
                                                  message: "The scanned barcode does not match any products in the database.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        DispatchQueue.global(qos: .background).async {
                            self.captureSession?.startRunning()
                        }
                    }))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func navigateToProductDetails(with productId: String) {
        // Instantiate the ProductDetailsViewController from the storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let productDetailsVC = storyboard.instantiateViewController(withIdentifier: "ProductDetailsViewController") as? ProductDetailsViewController {
            
            // Pass the product ID to the ProductDetailsViewController.
            productDetailsVC.productId = productId
            
            // Navigate to the ProductDetailsViewController.
            navigationController?.pushViewController(productDetailsVC, animated: true)
        }
    }


 
    @IBAction func TorchTapped(_ sender: Any) {
        toggleFlashlight()
    }
    @IBAction func GalleryButtonTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
                present(imagePicker, animated: true)
    }
    private func saveToRecentScans(productId: String, completion: @escaping (Bool) -> Void) {
        if let userId = Auth.auth().currentUser?.uid {
            // User is logged in, save to Firestore
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(userId)
            
            userRef.getDocument { document, error in
                if let error = error {
                    print("Error fetching user document: \(error)")
                    completion(false)
                    return
                }
                
                // Ensure the document exists
                guard let document = document, document.exists else {
                    print("User document does not exist.")
                    completion(false)
                    return
                }
                
                // Get current recent scans
                if var recentScans = document.data()?["recentScans"] as? [String] {
                    // Check if the productId already exists in the array
                    if recentScans.contains(productId) {
                        print("Product ID already exists in recent scans.")
                        completion(true)  // Return early here to prevent further execution
                        return
                    }else{
                        
                        // Add productId to the recentScans array
                        recentScans.append(productId)
                        userRef.updateData([
                            "recentScans": recentScans
                        ]) { error in
                            if let error = error {
                                print("Error updating recent scans: \(error)")
                                completion(false)
                            } else {
                                print("Product ID successfully saved to recent scans.")
                                completion(true)
                            }
                        }
                    }
                }
            }
        } else {
            // User is not logged in, save locally
            saveScanLocally(productId: productId)
            completion(true)
        }
    }


    private func saveScanLocally(productId: String) {
        let defaults = UserDefaults.standard
        
        var localScans = defaults.array(forKey: "localRecentScans") as? [String] ?? []
        if !localScans.contains(productId) {
            localScans.append(productId)
            defaults.set(localScans, forKey: "localRecentScans")
            print("Saved scan locally: \(productId)")
        } else {
            print("Product ID already exists in local recent scans.")
        }
    }


    private func fetchProductIdFromFirebase(barcode: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("products")
            .whereField("barcodes", arrayContains: barcode) // 🔍 Search in array
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching product ID: \(error)")
                    completion(nil)
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    completion(nil)
                    return
                }
                
                let productId = document.documentID
                completion(productId)
            }
    }

}
