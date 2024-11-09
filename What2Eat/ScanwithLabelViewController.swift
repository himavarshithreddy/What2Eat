//
//  ScanwithLabelViewController.swift
//  What2Eat
//
//  Created by admin68 on 08/11/24.
//

import UIKit
import AVFoundation
import Vision

class ScanwithLabelViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var isTorchOn = false
    @IBOutlet weak var TorchIcon: UIBarButtonItem!
    @IBOutlet weak var scanningFrameView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var cameraPreviewView: UIView!
    private var captureSession: AVCaptureSession!
        private var previewLayer: AVCaptureVideoPreviewLayer!
        private var capturePhotoOutput: AVCapturePhotoOutput!

    @IBAction func TorchTapped(_ sender: Any) {
        toggleFlashlight()
    }
    @IBAction func GalleryButtonTapped(_ sender: Any) {
        
    }
    @IBAction func ScannerSwitcherButton(_ sender: UIButton) {
        takePhoto()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()

        
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
           
           if captureSession?.canAddInput(videoInput) == true {
               captureSession?.addInput(videoInput)
           }
           
           previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
           previewLayer?.videoGravity = .resizeAspectFill
           cameraPreviewView.layer.addSublayer(previewLayer!)
           
           DispatchQueue.global(qos: .background).async {
               self.captureSession?.startRunning()
           }
       }
       
       // MARK: - Take Photo and Process for Text Recognition
       private func takePhoto() {
           let settings = AVCapturePhotoSettings()
           let photoOutput = AVCapturePhotoOutput()
           
           if captureSession?.canAddOutput(photoOutput) == true {
               captureSession?.addOutput(photoOutput)
               photoOutput.capturePhoto(with: settings, delegate: self)
           }
       }
       
       // MARK: - Process Captured Photo for Text Recognition
       private func processCapturedPhoto(_ photo: AVCapturePhoto) {
           guard let imageData = photo.fileDataRepresentation(),
                 let image = UIImage(data: imageData) else {
               print("Error: Could not capture photo data.")
               return
           }
           
           guard let croppedImage = cropImageToScanFrame(image) else {
               print("Error: Could not crop image to scanning frame.")
               return
           }
           
           recognizeText(in: croppedImage)
       }
       
       // MARK: - Crop Image to Scanning Frame
       private func cropImageToScanFrame(_ image: UIImage) -> UIImage? {
           let scale = image.size.width / cameraPreviewView.bounds.width
           
           let scanFrameInPreview = cameraPreviewView.convert(scanningFrameView.frame, from: scanningFrameView.superview)
           let cropRect = CGRect(
               x: scanFrameInPreview.origin.x * scale,
               y: scanFrameInPreview.origin.y * scale,
               width: scanFrameInPreview.width * scale,
               height: scanFrameInPreview.height * scale
           )
           
           guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
           return UIImage(cgImage: cgImage)
       }
       
       // MARK: - Text Recognition with Vision
       private func recognizeText(in image: UIImage) {
           guard let cgImage = image.cgImage else { return }
           
           let request = VNRecognizeTextRequest { [weak self] request, error in
               guard let self = self else { return }
               if let error = error {
                   print("Text recognition error: \(error)")
                   return
               }
               
               let recognizedText = request.results?
                   .compactMap { $0 as? VNRecognizedTextObservation }
                   .compactMap { $0.topCandidates(1).first?.string }
                   .joined(separator: "\n") ?? "No text found"
               
               DispatchQueue.main.async {
                   self.displayAlert(with: recognizedText)
               }
           }
           
           let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
           DispatchQueue.global(qos: .userInitiated).async {
               do {
                   try requestHandler.perform([request])
               } catch {
                   print("Error performing text recognition: \(error)")
               }
           }
       }
       
       // MARK: - Display Recognized Text in Alert
       private func displayAlert(with text: String) {
           let alert = UIAlertController(title: "Recognized Text", message: text, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default))
           present(alert, animated: true)
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
       
       // MARK: - Flashlight Toggle
       @objc func toggleFlashlight() {
           guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
           do {
               try device.lockForConfiguration()
               device.torchMode = isTorchOn ? .off : .on
               TorchIcon.image = UIImage(systemName: isTorchOn ? "flashlight.off.fill" : "flashlight.on.fill")
               isTorchOn.toggle()
               device.unlockForConfiguration()
           } catch {
               print("Error: Unable to toggle flashlight - \(error)")
           }
       }
   }

   extension ScanwithLabelViewController: AVCapturePhotoCaptureDelegate {
       func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
           if let error = error {
               print("Error capturing photo: \(error)")
               return
           }
           
           if let photoData = photo.fileDataRepresentation() {
               processCapturedPhoto(photo)
           }
       }
   }
