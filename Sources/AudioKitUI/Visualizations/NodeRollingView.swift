// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import AVFoundation
import SwiftUI

public class RollingViewData {
    let bufferSampleCount: UInt
    let framesToRMS: UInt

    private var history: [Float]

    public init(bufferSampleCount: UInt = 128,
                bufferSize: UInt32,
                framesToRMS: UInt = 128) {
        self.bufferSampleCount = bufferSampleCount
        self.framesToRMS = framesToRMS
        history = [Float](repeating: 0.0, count: Int(bufferSize))
    }

    public func calculate(_ nodeTap: RawDataTap) -> [Float] {
        var framesToTransform = [Float]()

        let signal = nodeTap.data

        for j in 0 ..< bufferSampleCount / framesToRMS {
            for i in 0 ..< framesToRMS {
                framesToTransform.append(signal[Int(i + j * framesToRMS)])
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
    private let nodeTap: RawDataTap
    private let metalFragment: FragmentBuilder
    private let rollingData: RollingViewData

    public init(_ node: Node,
                color: Color = .gray,
                backgroundColor: Color = .clear,
                isCentered: Bool = false,
                isFilled: Bool = false,
                bufferSize: UInt32 = 1024) {
        metalFragment = FragmentBuilder(foregroundColor: color.cg,
                                        backgroundColor: backgroundColor.cg,
                                        isCentered: isCentered,
                                        isFilled: isFilled)
        nodeTap = RawDataTap(node, bufferSize: bufferSize, callbackQueue: .main)
        rollingData = RollingViewData(bufferSize: bufferSize)
    }

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

