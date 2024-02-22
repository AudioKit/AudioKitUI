// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import AVFoundation
import SwiftUI
import MetalKit

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

    public func makeCoordinator() -> FloatPlotCoordinator {
        nodeTap.start()

        let plot = FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), constants: constants) {
            nodeTap.data
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
