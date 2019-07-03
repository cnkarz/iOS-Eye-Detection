//
//  AuthenticationViewController.swift
//  EyeV
//
//  Created by Cenk Arioz on 28.01.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class AuthenticationViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    //MARK: Enums
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    enum ViewMode {
        case logIn
        case signUp
    }
    
    //MARK: Properties
    private let isDebugMode = false
    var viewMode: ViewMode = .logIn
    var userTCKN = ""
    
    // Capture session variables
    private let captureSession = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var setupResult: SessionSetupResult  = .success
    
    // View outlets
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var eyeCircleView: EyeCircleView!
    @IBOutlet weak var progressView: UIProgressView!
    
    // Model objects
    private let fileHandler = FileHandlerModel()
    private let httpConn = HTTPConnectionModel()
    private let imageProcessor = ImageProcessorModel()
    
    // Store existing brightness level
    private var brightness: CGFloat = 0.0
    
    // Local variables and constants
    private var photosCaptured: Int = 0
    private var photosRequired: Int = 0
    private let LOGIN_PHOTO_QUANTITY: Int = 2
    private let SIGNUP_PHOTO_QUANTITY: Int = 30
    
    private let SIGN_UP_URL = URL(string: "http://192.168.34.53:5000/signup")!
    private let LOG_IN_URL = URL(string: "http://192.168.34.53:5000/login")!
//    private let TEST_URL = URL(string: "http://192.168.34.53:5000/test")!

    private var serverResponse: ServerResponse? = nil
        
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isDebugMode { NSLog("DEBUG: AVC / viewDidLoad") }

        if viewMode == .logIn {
            self.title = "Giriş"
        } else if viewMode == .signUp {
            self.title = "Kayıt"
        }
        
        // Store existing brightness setting to adjust back to after photo capture
        UIApplication.shared.isIdleTimerDisabled = true
        brightness = UIScreen.main.brightness
        DispatchQueue.main.async {
            self.startCaptureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isDebugMode { NSLog("DEBUG: AVC / viewWillAppear") }
        
        UIScreen.main.brightness = CGFloat(1.0)
        progressView.progressViewStyle = .bar
        progressView.progress = 0
        photosRequired = viewMode == .logIn ? LOGIN_PHOTO_QUANTITY : SIGNUP_PHOTO_QUANTITY
        
        DispatchQueue.main.async {
            self.checkCameraAuthorization()
            self.showToast(message: "Gözleriniz görüntüye girecek şekilde telefonu dik konumda yaklaştırıp uzaklaştırın.", duration: 2.0)
            if self.isDebugMode { NSLog("DEBUG: AVC/viewWillAppear/ 1st photo capture") }
            
            self.perform(#selector(self.takePhoto), with: nil, afterDelay: 2)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DispatchQueue.main.async {
            if self.setupResult == .success {
                self.captureSession.stopRunning()
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
        UIScreen.main.brightness = brightness
        UIApplication.shared.isIdleTimerDisabled = false

        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Session Management
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    private let photoOutput = AVCapturePhotoOutput()
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        captureSession.beginConfiguration()
        
        // Set output quality
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        addVideoInputToSession()
        addPhotoOutputToSession()
        
    }
    
    // Only called by configureSession() method
    private func addVideoInputToSession() {
        do {
            var frontCamera: AVCaptureDevice? {
                let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:[.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front)
                let devices = discoverySession.devices
                
                guard !devices.isEmpty else {
                    setupResult = .configurationFailed
                    captureSession.commitConfiguration()
                    fatalError("Could not find front camera")
                }
                
                return devices.first(where: { device in device.position == AVCaptureDevice.Position.front })
            }
            
            // Set exposure POI to the center of eyeCircleView
            do {
                try frontCamera?.lockForConfiguration()
                if frontCamera!.isExposurePointOfInterestSupported {
                    let poi = CGPoint(x: eyeCircleView.frame.midX, y: eyeCircleView.frame.midY)
                    frontCamera?.exposurePointOfInterest = poi
                }
                frontCamera?.unlockForConfiguration()
            } catch {
                print("Exposure POI could not be set")
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: frontCamera!)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = .portrait
                }
            } else {
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                fatalError("Could not add video device input to session")
            }
        } catch {
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            fatalError("Could not create video device input: \(error)")
        }
    }
    
    // Only called by configureSession() method
    private func addPhotoOutputToSession() {
        do {
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                
                photoOutput.isHighResolutionCaptureEnabled = true
                if #available(iOS 12.0, *) {
                    photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
                }
            } else {
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                fatalError("Couldn't add photo output to session")
            }
            captureSession.commitConfiguration()
        }
    }
    
    // Configure capture session
    private func startCaptureSession() {
        previewView.session = captureSession
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video){
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            setupResult = .notAuthorized
        }
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    // Check if app is granted camera permission
    private func checkCameraAuthorization() {
        sessionQueue.async {
            
            switch self.setupResult {
            case .success:
                DispatchQueue.main.async {
                    self.captureSession.startRunning()
                    self.isSessionRunning = self.captureSession.isRunning
                }
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "You need to grant permission to use cameras in order to use this app, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when user has denied access to cameras")
                    let alertController = UIAlertController(title: "Eye-V", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .default, handler: { _ in UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,options: [:], completionHandler: nil)}))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Camera could not be configured"
                    let message = NSLocalizedString("Unable to use camera", comment: alertMsg)
                    let alertController = UIAlertController(title: "Eye-V", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    
                    self.present(alertController,animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK: Photo Capture Action
    @objc private func takePhoto() {
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: AVMediaType.video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()
            
            if  self.photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType(rawValue: AVVideoCodecJPEG)) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .auto
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            DispatchQueue.main.async {
                self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
            
        }
    }
    
    // Callback function when photo capture is completed
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer!)
            let capturedPhoto = UIImage(data: photoData!)!
            
            DispatchQueue.main.async {
                let result = self.imageProcessor.storeOrRejectImage(image: capturedPhoto, mainView: self.view, circleView: self.eyeCircleView, fileHandler: self.fileHandler)
                if result == .success {
                    self.photosCaptured += 1
                    let progress = Float(self.photosCaptured) / Float(self.photosRequired)
                    self.progressView.setProgress(progress, animated: true)
                }
                self.displayInstructionToast(message: result)

                if self.photosCaptured == self.photosRequired {
                    let postURL = self.viewMode == .logIn ? self.LOG_IN_URL : self.SIGN_UP_URL
                    let zipURL = self.fileHandler.getZippedImagesURL(tckn: self.userTCKN)
                    
                    self.httpConn.post(url: postURL, zipFile: zipURL!, completion: { (response: ServerResponse?) in
                        if self.isDebugMode { NSLog("DEBUG: AVC/ Completion/response: \(String(describing: response))") }
                        self.serverResponse = response
                        self.fileHandler.deleteFiles()
                        UIScreen.main.brightness = self.brightness
                        
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "showResult", sender: self)
                        }

                    })

                } else {
                    self.takePhoto()
                }
            }
        
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let resultVC = segue.destination as? ResultViewController else {
            return
        }
        if self.isDebugMode { NSLog("DEBUG: AVC/ prepareForSegue/self.response: \(String(describing: self.serverResponse))") }

        if self.serverResponse == .success {
            resultVC.serverResponse = .success
            if self.isDebugMode { NSLog("DEBUG: AVC/ prepareForSegue/resultVC.response: \(resultVC.serverResponse)") }

            if viewMode == .logIn {
                resultVC.labelText = "Hoşgeldiniz!"
            } else {
                resultVC.labelText = "Resimleriniz başarıyla kaydedildi!"
            }
        } else {
            resultVC.serverResponse = .fail
            
            if viewMode == .logIn {
                resultVC.labelText = "Giriş onaylanmadı."
            } else {
                resultVC.labelText = "Kayıt işlemi başarısız oldu."
            }
        }
    }
    
    //MARK: Private Methods

    // Display appropriate instruction message according to the input from face recognition
    private func displayInstructionToast(message: InstructionMessage) {
        switch message {
        case .placeFace:
            showToast(message: "Gözleriniz görüntüye girecek şekilde telefonu dik konumda yaklaştırıp uzaklaştırın.")
        case .bringCloser:
            showToast(message: "Telefonu yüzünüze yaklaştırın.")
        case .multipleFaces:
            showToast(message: "Birden fazla kişi tespit edildi. Tekrar deneniyor.")
        case .eyesClosed:
            showToast(message: "Gözünüz kapalı çıktı. Tekrar deneniyor.")
        case .eyesOutsideCircles:
            showToast(message: "Gözlerinizi daireler içerisine getirin.")
        case .success:
            showToast(message: "Görüntü başarılı")
        }
    }
    
    // Display toast message to give instructions to user
    private func showToast(message : String, duration: TimeInterval = 1.0) {
        
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        
        let x = width * CGFloat(0.1)
        let y = height * CGFloat(0.1)
        let w = width * 0.8
        let h = height * 0.15
        
        let toastLabel = UILabel(frame: CGRect(x: x, y: y, width: w, height: h))
        toastLabel.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.black
        toastLabel.textAlignment = .center;
        toastLabel.lineBreakMode = .byWordWrapping
        toastLabel.numberOfLines = 0
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: duration, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
//    Display captured photo if it passes face recognition rules
//    private func insertPhotoPreviewView(rect: CGRect) {
//
//        UIGraphicsBeginImageContextWithOptions(capturedPhoto.size, false, capturedPhoto.scale)
//
//        capturedPhoto.draw(at: CGPoint.zero)
//        UIColor.red.setStroke()
//        UIRectFrame(rect)
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//
//        UIGraphicsEndImageContext()
//
//        let imageView = UIImageView(frame: CGRect(x: view.bounds.minX, y: view.bounds.minY, width: view.bounds.width, height: view.bounds.height))
//
//        imageView.image = newImage
//
//        view.insertSubview(imageView, at: 0)
//    }
    
}

