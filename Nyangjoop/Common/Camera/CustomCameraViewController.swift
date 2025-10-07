//
//  CustomCameraViewController.swift
//  Nyangjoop
//
//  Created by Lee on 10/2/25.
//

import UIKit
import AVFoundation
import SnapKit

protocol CustomCameraDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func didRequestRetake()
}

final class CustomCameraViewController: UIViewController {
    
    weak var delegate: CustomCameraDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentCamera: AVCaptureDevice?
    private var currentZoomFactor: CGFloat = 1.0
    private var isCapturing: Bool = false
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let bottomControlView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.systemOrange.cgColor
        button.layer.cornerRadius = 40
        return button
    }()
    
    private let innerCaptureButton: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray
        button.backgroundColor = .clear
        return button
    }()
    
    private let zoom1xButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1x", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let zoom2xButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("2x", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        return button
    }()
    
    private let focusIndicator: UIView = {
        let view = UIView()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemYellow.cgColor
        view.layer.cornerRadius = 4
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateZoomButtons()
        checkCameraPermission()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            if captureSession?.isRunning == false {
                startSession()
            }
        } else if status == .denied || status == .restricted {
            showPermissionDeniedAlert()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(previewView)
        view.addSubview(bottomControlView)
        view.addSubview(closeButton)
        view.addSubview(captureButton)
        captureButton.addSubview(innerCaptureButton)
        view.addSubview(switchCameraButton)
        view.addSubview(zoom1xButton)
        view.addSubview(zoom2xButton)
        view.addSubview(focusIndicator)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus))
        previewView.addGestureRecognizer(tapGesture)
        
        previewView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-180)
        }
        
        bottomControlView.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.size.equalTo(40)
        }
        
        captureButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.size.equalTo(80)
        }
        
        innerCaptureButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        switchCameraButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.centerY.equalTo(captureButton)
            make.size.equalTo(50)
        }
        
        zoom1xButton.snp.makeConstraints { make in
            make.bottom.equalTo(bottomControlView.snp.top).offset(-30)
            make.centerX.equalToSuperview().offset(-50)
            make.width.equalTo(60)
            make.height.equalTo(44)
        }
        
        zoom2xButton.snp.makeConstraints { make in
            make.bottom.equalTo(bottomControlView.snp.top).offset(-30)
            make.centerX.equalToSuperview().offset(50)
            make.width.equalTo(60)
            make.height.equalTo(44)
        }
        
        focusIndicator.snp.makeConstraints { make in
            make.size.equalTo(80)
        }
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        zoom1xButton.addTarget(self, action: #selector(zoom1xButtonTapped), for: .touchUpInside)
        zoom2xButton.addTarget(self, action: #selector(zoom2xButtonTapped), for: .touchUpInside)
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
            startSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                        self?.startSession()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
            
        case .denied, .restricted:
            showPermissionDeniedAlert()
            
        @unknown default:
            showPermissionDeniedAlert()
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "카메라 권한 필요",
            message: "카메라를 사용하려면 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        
        let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { [weak self] _ in
            self?.openSettings()
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else {
            dismiss(animated: true)
            return
        }
        
        UIApplication.shared.open(settingsURL) { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("카메라를 찾을 수 없습니다")
            return
        }
        
        currentCamera = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                photoOutput = output
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(previewLayer)
            
            videoPreviewLayer = previewLayer
            captureSession = session
            
        } catch {
            print("카메라 설정 오류: \(error)")
        }
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.bounds
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func captureButtonTapped() {
        guard let photoOutput = photoOutput else { return }
        guard !isCapturing else {
            print("이미 촬영 중입니다")
            return
        }
        
        isCapturing = true
        captureButton.isEnabled = false
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func switchCameraButtonTapped() {
        guard let session = captureSession else { return }
        
        session.beginConfiguration()
        
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else {
            session.commitConfiguration()
            return
        }
        
        session.removeInput(currentInput)
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentCamera = newCamera
            currentZoomFactor = 1.0
            updateZoomButtons()
        } else {
            session.addInput(currentInput)
        }
        
        session.commitConfiguration()
    }
    
    @objc private func zoom1xButtonTapped() {
        setZoom(1.0)
    }
    
    @objc private func zoom2xButtonTapped() {
        setZoom(2.0)
    }
    
    private func setZoom(_ factor: CGFloat) {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            
            let maxZoom = device.activeFormat.videoMaxZoomFactor
            let newZoom = min(max(factor, 1.0), maxZoom)
            
            device.videoZoomFactor = newZoom
            currentZoomFactor = newZoom
            
            device.unlockForConfiguration()
            
            updateZoomButtons()
        } catch {
            print("줌 설정 오류: \(error)")
        }
    }
    
    private func updateZoomButtons() {
        let is1x = abs(currentZoomFactor - 1.0) < 0.1
        let is2x = abs(currentZoomFactor - 2.0) < 0.1
        
        zoom1xButton.backgroundColor = is1x ? .systemOrange : UIColor.black.withAlphaComponent(0.3)
        zoom2xButton.backgroundColor = is2x ? .systemOrange : UIColor.black.withAlphaComponent(0.3)
    }
    
    @objc private func handleTapToFocus(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: previewView)
        
        guard let device = currentCamera else { return }
        
        let focusPoint = videoPreviewLayer?.captureDevicePointConverted(fromLayerPoint: location) ?? CGPoint(x: 0.5, y: 0.5)
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            showFocusIndicator(at: location)
        } catch {
            print("초점 설정 오류: \(error)")
        }
    }
    
    private func showFocusIndicator(at point: CGPoint) {
        focusIndicator.center = point
        focusIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        focusIndicator.alpha = 1
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.focusIndicator.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5) {
                self.focusIndicator.alpha = 0
            }
        }
    }
}

extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("사진 촬영 오류: \(error)")
            isCapturing = false
            captureButton.isEnabled = true
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("이미지 변환 실패")
            isCapturing = false
            captureButton.isEnabled = true
            return
        }
        
        showPhotoPreview(image: image)
    }
    
    private func showPhotoPreview(image: UIImage) {
        let previewVC = PhotoPreviewViewController(image: image)
        previewVC.delegate = self
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
}

extension CustomCameraViewController: PhotoPreviewDelegate {
    func didConfirmPhoto(_ image: UIImage) {
        delegate?.didCaptureImage(image)
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    func didCancelPhoto() {
        isCapturing = false
        captureButton.isEnabled = true
        delegate?.didRequestRetake()
    }
}
