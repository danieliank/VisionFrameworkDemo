import SwiftUI

struct ContentView: View {
    @State private var camera = CameraController()
    
    var body: some View {
        CameraPreview(session: camera.session)
            .ignoresSafeArea()
        
        /* Task 1 - Uncomment the line below to show what Vision framework can do (pro tip: SMILE!) */
//            .overlay(alignment: .top) { detectionIndicator }
        
        /* Task 2 - Uncomment the line below to show more capability of Vision framework (you might want to stretch your head) */
            .overlay(alignment: .bottom) { controls }
            .task { camera.start() }
    }
    
    private var detectionIndicator: some View {
        Label(
            camera.faceDetected ? "Face detected" : "No face",
            systemImage: camera.faceDetected ? "face.smiling" : "face.dashed"
        )
        .font(.subheadline.weight(.medium))
        .foregroundStyle(camera.faceDetected ? .green : .secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.2), value: camera.faceDetected)
    }
    
    private var controls: some View {
        VStack(spacing: 16) {
            Text(camera.prompt)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .shadow(radius: 4)
            
            Button(buttonTitle) {
                camera.startTraining()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(.tint, in: .rect(cornerRadius: 14))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private var buttonTitle: String {
        if camera.isFinished { return "Start again" }
        return camera.isRunning ? "Restart" : "Start posing"
    }
}

