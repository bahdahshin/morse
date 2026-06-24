import AVFoundation
import SwiftUI
import UIKit

struct TouchScreenView: UIViewRepresentable {
    func makeUIView(context: Context) -> TouchSurfaceView {
        TouchSurfaceView()
    }

    func updateUIView(_ uiView: TouchSurfaceView, context: Context) {}
}

final class TouchSurfaceView: UIView {
    private var activeTouches = Set<UITouch>()
    private let torchController = TorchController()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        torchController.setEnabled(false)
    }

    private func configure() {
        backgroundColor = .black
        isMultipleTouchEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.formUnion(touches)
        updateState()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.subtract(touches)
        updateState()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.subtract(touches)
        updateState()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            reset()
        }
    }

    @objc private func appWillResignActive() {
        reset()
    }

    private func reset() {
        activeTouches.removeAll()
        updateState()
    }

    private func updateState() {
        let isTouching = !activeTouches.isEmpty
        backgroundColor = isTouching ? .white : .black
        torchController.setEnabled(isTouching)
    }
}

private final class TorchController {
    private let queue = DispatchQueue(label: "com.bahdahshin.morse.touchflash.torch")
    private let device = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera],
        mediaType: .video,
        position: .back
    ).devices.first(where: \.hasTorch)

    func setEnabled(_ enabled: Bool) {
        queue.async { [device] in
            guard let device, device.isTorchAvailable else { return }

            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }

                if enabled {
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }
            } catch {
                // The torch is unavailable in Simulator and can be temporarily
                // unavailable on a device; the screen behavior still works.
            }
        }
    }
}
