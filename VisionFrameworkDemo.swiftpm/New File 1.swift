import Vision

final class VisionFaceDetector {
    func detect(
        _ image: CVPixelBuffer,
        completion: @escaping (VNFaceObservation?) -> Void
    ) {
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard error == nil else {
                completion(nil)
                return
            }
            completion(request.results?.first as? VNFaceObservation)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image)
        try? handler.perform([request])
    }
}

