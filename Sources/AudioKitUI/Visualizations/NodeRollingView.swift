// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import AVFoundation
import SwiftUI
import MetalKit

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
    private let rollingData: RollingViewData
    private let constants: FragmentConstants

    public init(_ node: Node,
                color: Color = .gray,
                backgroundColor: Color = .clear,
                isCentered: Bool = false,
                isFilled: Bool = false,
                bufferSize: UInt32 = 1024) {
        constants = FragmentConstants(foregroundColor: color.simd,
                                      backgroundColor: backgroundColor.simd,
                                      isFFT: false,
                                      isCentered: isCentered,
                                      isFilled: isFilled)
        nodeTap = RawDataTap(node, bufferSize: bufferSize, callbackQueue: .main)
        rollingData = RollingViewData(bufferSize: bufferSize)
    }

    public func makeCoordinator() -> FloatPlotCoordinator {
        nodeTap.start()

        let plot = FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), constants: constants) {
            rollingData.calculate(nodeTap)
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

