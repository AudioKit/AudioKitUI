// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import AVFoundation
import SwiftUI

public struct NodeFFTView: ViewRepresentable {
    var nodeTap: FFTTap
    let bufferSampleCount = 128

    public init(_ node: Node) {
        nodeTap = FFTTap(node, bufferSize: UInt32(bufferSampleCount), callbackQueue: .main) { _ in }
    }

    internal var plot: FloatPlot {
        nodeTap.start()

        let constants = FragmentConstants(foregroundColor: Color.yellow.simd,
                                          backgroundColor: Color.black.simd,
                                          isFFT: true,
                                          isCentered: false,
                                          isFilled: true)

        let plot = FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), constants: constants) {
            nodeTap.fftData
        }

        return plot
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> FloatPlot { return plot }
    public func updateNSView(_ nsView: FloatPlot, context: Context) {}
    #else
    public func makeUIView(context: Context) -> FloatPlot { return plot }
    public func updateUIView(_ uiView: FloatPlot, context: Context) {}
    #endif
}
