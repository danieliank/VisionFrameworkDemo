import Vision

class FacePoseDetector {
    
    /* TASK 2.5 - you can adjust what features you want to use by change the boolean value to true/false */
    var useRoll = true
    var useYaw = true
    var usePitch = true
    
    private var step = 0
    
    private var steps: [String] {
        var result = ["Center your face in the middle of the screen"]
        
        if useYaw {
            result += ["Look Left", "Look Right"]
        }
        
        if usePitch {
            result += ["Look Up", "Look Down"]
        }
        
        if useRoll {
            result += ["Tilt Left", "Tilt Right"]
        }
        
        return result
    }
    
    var currentStep: String {
        step < steps.count ? steps[step] : "Done"
    }
    
    var isFinished: Bool {
        step >= steps.count
    }
    
    func reset() {
        step = 0
    }
    
    func train(_ face: VNFaceObservation) -> Bool {
        
        let yaw = (face.yaw?.doubleValue ?? 0) * -1.0
        let pitch = face.pitch?.doubleValue ?? 0
        let roll = face.roll?.doubleValue ?? 0
        
        
        let passed: Bool
        
        switch currentStep {
            
        case "Center your face in the middle of the screen":
            passed =
            abs(face.boundingBox.midX - 0.5) < 0.12 &&
            abs(face.boundingBox.midY - 0.5) < 0.12
            
        case "Look Left":
            passed = yaw < -0.25
            
        case "Look Right":
            passed = yaw > 0.25
            
        case "Look Up":
            passed = pitch < -0.20
            
        case "Look Down":
            passed = pitch > -0.20
            
        case "Tilt Left":
            passed = roll < -0.20
            
        case "Tilt Right":
            passed = roll > 0.20
            
        default:
            passed = false
        }
        
        if passed {
            step += 1
        }
        
        return passed
    }
}



