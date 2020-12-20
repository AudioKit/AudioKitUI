// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

#if os(macOS)

public struct FloatPlotView: NSViewRepresentable {
    var dataCallback: () -> [Float]
    var fragment = MetalFragment.mirror

    public init(dataCallback: @escaping () -> [Float]) {
        self.dataCallback = dataCallback
    }

    public func makeNSView(context: Context) -> FloatPlot {
        return FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), fragment: fragment.rawValue) {
            dataCallback()
        }
    }

    public func updateNSView(_ nsView: FloatPlot, context: Context) {
        // Do nothing.
    }
}

#endif
