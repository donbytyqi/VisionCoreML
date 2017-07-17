//
//  ViewController.swift
//  Object
//
//  Created by Don Bytyqi on 7/16/17.
//  Copyright © 2017 Don Bytyqi. All rights reserved.
//

import UIKit
import AVKit
import Vision

class CameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession = AVCaptureSession()
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var speechUtterance : AVSpeechUtterance?
    
    let label: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configAndStartCamera()
        setupLabel()
        
    }
    
    func setupLabel() {
        view.addSubview(label)
        
        label.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        label.heightAnchor.constraint(equalToConstant: 100).isActive = true
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func configAndStartCamera() {
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        captureSession.addInput(deviceInput)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "dataOutput"))
        captureSession.addOutput(dataOutput)
        
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        detectObject(sampleBuffer)
        
    }
    
    func detectObject(_ cv: CMSampleBuffer) {
        
        guard let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(cv) else {
            return
        }
        
        let model = MLModel() //Inceptionv3().model // your model here
        
        guard let coremlModel = try? VNCoreMLModel(for: model) else {
            return
        }
        
        let request = VNCoreMLRequest(model: coremlModel) { (request, error) in
            
            if error != nil {
                print(error ?? "Something went wrong")
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                return
            }
            
            guard let classifications = results.first else {
                return
            }
            
            print(classifications.identifier, classifications.confidence)
            
            
            DispatchQueue.main.async {
                
                let confidence = classifications.confidence * 100
                let confidenceString = String(format: "%.0f%%", confidence)
                self.label.text = classifications.identifier + " " + confidenceString
                
                guard let textToSpeak = self.label.text else {
                    return
                }
                
                self.speechUtterance = AVSpeechUtterance(string: textToSpeak)
                
                if let sU = self.speechUtterance {
                    
                    if confidence > 50 {
                        
                        self.speechSynthesizer.speak(sU)
                        
                    }
                }
                
            }
            
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
}

