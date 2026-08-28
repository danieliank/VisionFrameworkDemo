import Observation
import AVFoundation
import Vision

@Observable
final class CameraController: NSObject {
    let session = AVCaptureSession()
    
    private(set) var faceDetected = false
    private(set) var prompt = "Tap Start to begin"
    private(set) var isRunning = false
    private(set) var isFinished = false
    
    private let detector = VisionFaceDetector()
    private let trainer = FacePoseDetector()
    
    private let sessionQueue = DispatchQueue(label: "camera.session")
    private let videoQueue = DispatchQueue(label: "camera.video")
    private let output = AVCaptureVideoDataOutput()
    private var isConfigured = false
    
    private var device: AVCaptureDevice?
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservers: [NSKeyValueObservation] = []
    
    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.configureIfNeeded() }
            }
        default:
            break
        }
    }
    
    func attach(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        setUpRotationCoordinator()
    }
    
    func startTraining() {
        trainer.reset()
        isRunning = true
        isFinished = false
        prompt = trainer.currentStep
    }
        
    private func configureIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !isConfigured {
                configureSession()
                isConfigured = true
            }
            if !session.isRunning { session.startRunning() }
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else { return }
        session.addInput(input)
        device = camera
        
        output.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        
        DispatchQueue.main.async { [weak self] in
            self?.setUpRotationCoordinator()
        }
    }
        
    private func setUpRotationCoordinator() {
        guard let device else { return }
        
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        
        applyRotations()
        
        rotationObservers = [
            coordinator.observe(\.videoRotationAngleForHorizonLevelPreview) { [weak self] _, _ in
                self?.applyRotations()
            },
            coordinator.observe(\.videoRotationAngleForHorizonLevelCapture) { [weak self] _, _ in
                self?.applyRotations()
            }
        ]
    }
    
    private func applyRotations() {
        guard let coordinator = rotationCoordinator else { return }
        
        if let preview = previewLayer?.connection {
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            if preview.isVideoRotationAngleSupported(angle) {
                preview.videoRotationAngle = angle
            }
        }
        
        if let capture = output.connection(with: .video) {
            let angle = coordinator.videoRotationAngleForHorizonLevelCapture
            if capture.isVideoRotationAngleSupported(angle) {
                capture.videoRotationAngle = angle
            }
        }
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        detector.detect(buffer) { [weak self] face in
            DispatchQueue.main.async { self?.handle(face) }
        }
    }
    
    private func handle(_ face: VNFaceObservation?) {
        faceDetected = face != nil
        
        guard isRunning, let face else { return }
        
        if trainer.train(face) {
            isFinished = trainer.isFinished
            prompt = isFinished ? "All done 🎉" : trainer.currentStep
        }
    }
}
