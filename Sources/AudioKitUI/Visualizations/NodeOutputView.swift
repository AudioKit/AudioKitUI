// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import AVFoundation
import SwiftUI

public struct NodeOutputView: ViewRepresentable {
    var nodeTap: RawDataTap
    let bufferSampleCount = 128

    public init(_ node: Node) {
        nodeTap = RawDataTap(node, bufferSize: UInt32(bufferSampleCount)) { _ in }
    }

    let metalFragment = FragmentBuilder(foregroundColor: CrossPlatformColor(red: 0.5, green: 0.5, blue: 1, alpha: 1).cgColor,
                                        backgroundColor: CrossPlatformColor(red: 0.1, green: 0.3, blue: 0.2, alpha: 1).cgColor,
                                        isCentered: true,
                                        isFilled: false)

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
