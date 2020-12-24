// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import AVFoundation
import SwiftUI

public struct NodeOutputView: ViewRepresentable {
    var nodeTap: RawDataTap
    var metalFragment: FragmentBuilder
    let bufferSampleCount: UInt32 = 1024

    public init(_ node: Node, color: CrossPlatformColor = CrossPlatformColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)) {

        metalFragment = FragmentBuilder(foregroundColor: color.cgColor,
                                        backgroundColor: CrossPlatformColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,
                                        isCentered: true,
                                        isFilled: false)

        nodeTap = RawDataTap(node, bufferSize: bufferSampleCount)
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
