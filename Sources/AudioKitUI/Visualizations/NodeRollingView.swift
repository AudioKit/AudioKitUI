// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import AVFoundation
import SwiftUI

public class RollingViewData {
    let bufferSampleCount = 128
    var history = [Float](repeating: 0.0, count: 1024)
    var framesToRMS = 128

    func calculate(_ nodeTap: RawDataTap) -> [Float] {
        var framesToTransform = [Float]()

        let signal = nodeTap.data

        for j in 0 ..< bufferSampleCount / framesToRMS {
            for i in 0 ..< framesToRMS {
                framesToTransform.append(signal[i + j * framesToRMS])
            }

            var rms: Float = 0.0
            vDSP_rmsqv(signal, 1, &rms, vDSP_Length(framesToRMS))
            history.reverse()
            _ = history.popLast()
            history.reverse()
            history.append(rms)
        }
        return history

    }
}

public struct NodeRollingView: ViewRepresentable {
    var nodeTap: RawDataTap
    var rollingData = RollingViewData()

    public init(_ node: Node) {
        nodeTap = RawDataTap(node, bufferSize: 128)
    }

    let metalFragment = FragmentBuilder(foregroundColor: CrossPlatformColor(red: 0.5, green: 1, blue: 0.5, alpha: 1).cgColor,
                                        backgroundColor: CrossPlatformColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor,
                                        isCentered: true,
                                        isFilled: true)
    var plot: FloatPlot {
        nodeTap.start()

        return FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), fragment: metalFragment.stringValue) {
            rollingData.calculate(nodeTap)
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

