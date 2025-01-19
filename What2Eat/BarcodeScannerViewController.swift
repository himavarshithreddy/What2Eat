import UIKit
import AVFoundation
import Vision

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
        if let matchingProduct = sampleProducts.first(where: { $0.barcode == barcode }) {
                // If a matching product is found, navigate to the ProductDetailsViewController
                navigateToProductDetails(with: matchingProduct)
            } else {
                // If no matching product is found, show an alert
                let alert = UIAlertController(title: "Product Not Found",
                                              message: "The scanned barcode does not match any products in the database.\(barcode)",
                                              preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                    DispatchQueue.global(qos: .background).async {
                        self?.captureSession?.startRunning()
                    }
                }))
                present(alert, animated: true)
            }        }
    private func navigateToProductDetails(with product: Product) {
        // Instantiate the ProductDetailsViewController from the storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let productDetailsVC = storyboard.instantiateViewController(withIdentifier: "ProductDetailsViewController") as? ProductDetailsViewController {
            
            // Pass the product to the ProductDetailsViewController
            productDetailsVC.product = product
            
            // Navigate to the ProductDetailsViewController
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
}
