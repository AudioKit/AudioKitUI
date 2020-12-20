// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import SwiftUI

public struct NodeOutputView: ViewRepresentable {
    var node: Tappable
    let bufferSampleCount = 512

    public init(_ tappableNode: Tappable) {
        node = tappableNode
    }

    let metalFragment = FragmentBuilder(foregroundColor: CrossPlatformColor(red: 0.5, green: 0.5, blue: 1, alpha: 1).cgColor,
                                        backgroundColor: CrossPlatformColor(red: 0.1, green: 0.3, blue: 0.2, alpha: 1).cgColor,
                                        isCentered: true,
                                        isFilled: false)

    var plot: FloatPlot {
        node.installTap()
        return FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), fragment: metalFragment.stringValue) {
            let data = node.getTapData(sampleCount: 512)
            if data.count == 2, data[0].count == 512 {
                return data[0]
            } else {
                return []
            }
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
