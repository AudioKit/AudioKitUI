// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import AVFoundation
import SwiftUI
import MetalKit

public struct NodeFFTView: ViewRepresentable {
    var nodeTap: FFTTap
    let bufferSampleCount = 128

    public init(_ node: Node) {
        nodeTap = FFTTap(node, bufferSize: UInt32(bufferSampleCount), callbackQueue: .main) { _ in }
    }

    public func makeCoordinator() -> FloatPlotCoordinator {
        nodeTap.start()

        let constants = FragmentConstants(foregroundColor: Color.yellow.simd,
                                          backgroundColor: Color.black.simd,
                                          isFFT: true,
                                          isCentered: false,
                                          isFilled: true)

        let plot = FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), constants: constants) {
            nodeTap.fftData
        }

        return .init(renderer: plot)
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> NSView { return context.coordinator.view }
    public func updateNSView(_ nsView: NSView, context: Context) {}
    #else
    public func makeUIView(context: Context) -> UIView { return context.coordinator.view }
    public func updateUIView(_ uiView: UIView, context: Context) {}
    #endif
}
