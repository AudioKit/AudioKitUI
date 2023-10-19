// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import AVFoundation
import SwiftUI

public struct NodeOutputView: ViewRepresentable {
    private var nodeTap: RawDataTap
    private var metalFragment: FragmentBuilder

    public init(_ node: Node, color: Color = .gray, backgroundColor: Color = .clear, bufferSize: Int = 1024) {
        metalFragment = FragmentBuilder(foregroundColor: color.cg,
                                        backgroundColor: backgroundColor.cg,
                                        isCentered: true,
                                        isFilled: false)
        nodeTap = RawDataTap(node, bufferSize: UInt32(bufferSize), callbackQueue: .main)
    }

    var plot: FloatPlot {
        nodeTap.start()

        return FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), fragment: metalFragment.stringValue) {
            return nodeTap.data
        }
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> FloatPlot { return plot }
    public func updateNSView(_ nsView: FloatPlot, context: Context) {}
    #else
    public func makeUIView(context: Context) -> FloatPlot { return plot }
    public func updateUIView(_ uiView: FloatPlot, context: Context) {}
    #endif
}
