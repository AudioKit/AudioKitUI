// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import AVFoundation
import SwiftUI

public struct NodeOutputView: ViewRepresentable {
    private var nodeTap: RawDataTap
    private let constants: FragmentConstants

    public init(_ node: Node, color: Color = .gray, backgroundColor: Color = .clear, bufferSize: Int = 1024) {
        constants = FragmentConstants(foregroundColor: color.simd,
                                      backgroundColor: backgroundColor.simd,
                                      isFFT: false,
                                      isCentered: true,
                                      isFilled: false)
        nodeTap = RawDataTap(node, bufferSize: UInt32(bufferSize), callbackQueue: .main)
    }

    var plot: FloatPlot {
        nodeTap.start()

        let plot = FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), constants: constants) {
            return nodeTap.data
        }

        plot.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0)

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
