// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import AVFoundation
import SwiftUI

public class RollingViewData {
    let bufferSampleCount = 1024
    var history = [Float](repeating: 0.0, count: 1024)
    var framesToRMS = 256

    func calculate(_ nodeTap: NodeTap) -> [Float] {
        var framesToTransform = [Float]()

        if let buf = nodeTap.dataBuffer {
            let data = Array(UnsafeBufferPointer(start: buf.floatChannelData![0],
                                                 count: Int(nodeTap.bufferSize)))

            if data.count < 2 || data.count < framesToRMS {
                return []
            }

            let signal = data

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

        } else {
            return []
        }
    }
}

public struct NodeRollingView: ViewRepresentable {
    var nodeTap: NodeTap
    var rollingData = RollingViewData()

    public init(_ node: Node) {
        nodeTap = NodeTap(node)
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

