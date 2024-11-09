import UIKit
import AVFoundation
import Vision

class BarcodeScannerViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var scanningFrameView: UIView!
    var isTorchOn = false
    @IBOutlet weak var TorchIcon: UIBarButtonItem!
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
   
    @IBAction func ScannerSwitcherButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
          if let scanViewController = storyboard.instantiateViewController(withIdentifier: "ScanwithLabel") as? ScanwithLabelViewController {
              navigationController?.setViewControllers([scanViewController], animated: true)
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
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        scanningFrameView.layer.masksToBounds = true
        scanningFrameView.layer.borderWidth = 1.5
        scanningFrameView.clipsToBounds = true
        scanningFrameView.layer.borderColor = UIColor.systemOrange.cgColor
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
            navigationItem.leftBarButtonItem = backButton
        setupCamera()
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
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417] // Set barcode types
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
                displayAlert(with: payloadString)
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
}

// MARK: - Barcode Detection
extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for metadata in metadataObjects {
            guard let readableObject = metadata as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { continue }
            
            // Barcode detected, stop running the session
            captureSession?.stopRunning()
            
            // Show result in an alert
            displayAlert(with: stringValue)
            break
        }
    }
    
    // MARK: - Display Alert with Barcode Result
    private func displayAlert(with barcode: String) {
            let alert = UIAlertController(title: "Barcode Detected",
                                        message: "Value: \(barcode)",
                                        preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                DispatchQueue.global(qos: .background).async {
                    self?.captureSession?.startRunning()
                }
            }))
            present(alert, animated: true)
        }
    
    @objc func backButtonTapped() {
       
        tabBarController?.selectedIndex = 0

    }
    
}
