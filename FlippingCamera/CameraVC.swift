//
//  CameraVC.swift
//  FlippingCamera
//
//  Created by Majid on 29/04/2023.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

extension UIView{
    func rotate() {
        let scale : CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 0.6
        scale.autoreverses = true
        scale.duration = 0.3
        self.layer.add(scale, forKey: "scaleAnimation")
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
        rotation.fromValue = 0.0
        rotation.toValue = 0.5
        rotation.duration = 0.3
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}


class CameraVC: UIViewController {
    
    var captureSession = AVCaptureSession()
    var previewView = PreviewView()
    var mediaType: AVMediaType = .video
    var cameraType: AVCaptureDevice.DeviceType = .builtInDualCamera
    var cameraPosition: AVCaptureDevice.Position = .back
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewView.frame = view.bounds
        view.addSubview(previewView)
        setup()
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.setImage(.init(systemName: "camera"), for: .normal)
        button.addTarget(self, action: #selector(changeCamera), for: .touchUpInside)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 10
        button.layer.zPosition = 1000
        view.addSubview(button)
        button.center = view.center
    }
    
    @objc private func changeCamera() {
        captureSession.stopRunning()
        captureSession.beginConfiguration()
        guard let currentCameraOutput = captureSession.inputs.last else {
            return
        }
        captureSession.removeInput(currentCameraOutput)
        cameraPosition = cameraPosition == .back ? .front : .back
        cameraType = cameraType == .builtInDualCamera ? .builtInWideAngleCamera : .builtInDualCamera
        guard let newCamera = AVCaptureDevice.default(cameraType, for: .video, position: cameraPosition),
              let deviceInput = try? AVCaptureDeviceInput(device: newCamera),
              captureSession.canAddInput(deviceInput) else {
            return
        }
        UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseInOut) { [weak self] in
            self?.previewView.rotate()
        } completion: { [weak self] isSucceeded in
            if isSucceeded {
                self?.captureSession.addInput(deviceInput)
                self?.captureSession.commitConfiguration()
                self?.captureSession.startRunning()
            }
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setup() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        grantAccess(for: .audio) { [weak self] isGranted in
            guard isGranted, let self else { return }
            guard let audioDevice = AVCaptureDevice.default(for: .audio),
                  let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
                  self.captureSession.canAddInput(audioDeviceInput) else { return }
            self.captureSession.addInput(audioDeviceInput)
        }
        grantAccess(for: .video) { [weak self] isGranted in
            guard isGranted, let self else { return }
            guard let videoDevice = AVCaptureDevice.default(self.cameraType, for: self.mediaType, position: self.cameraPosition),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoDeviceInput) else {
                return
            }
            self.captureSession.addInput(videoDeviceInput)
        }
        previewView.videoPreviewLayer.session = captureSession
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    func grantAccess(for mediaType: AVMediaType, completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: mediaType, completionHandler: completion)
    }
    
    func changeSessionPreset(with newPreset: AVCaptureSession.Preset) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = newPreset
        captureSession.commitConfiguration()
    }
    
    func changeSessionInput(with newInput: AVCaptureInput) {
        captureSession.beginConfiguration()
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        }
        captureSession.commitConfiguration()
    }
}
