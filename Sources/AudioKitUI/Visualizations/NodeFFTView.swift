// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import AVFoundation
import SwiftUI

public struct NodeFFTView: ViewRepresentable {
    var nodeTap: FFTTap
    let bufferSampleCount = 128

    let foregroundColorAddress = 0
    let backgroundColorAddress = 1

    public init(_ node: Node) {
        nodeTap = FFTTap(node, bufferSize: UInt32(bufferSampleCount)) { _ in }
    }

    internal var plot: FloatPlot {
        nodeTap.start()

        let metalFragmentOrig = """
        float sample = waveform.sample(s, (pow(10, in.t.x) - 1.0) / 9.0).x;

        half4 backgroundColor = half4(colorParameters[1]);
        half4 foregroundColor = half4(colorParameters[0]);

        float y = (in.t.y - 1);
        bool isFilled = parameters[0] != 0;
        float d = isFilled ? fmax(fabs(y) - fabs(sample), 0) : fabs(y - sample);
        float alpha = fabs(1/(50 * d));
        return { mix(foregroundColor, backgroundColor, alpha) };
        """

        let plot = FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), fragment: metalFragmentOrig) {
            return nodeTap.fftData
        }

        plot.setParameter(address: 0, value: 1)
        plot.setColorParameter(address: foregroundColorAddress, value: SIMD4<Float>(1, 1, 0, 1))
        plot.setColorParameter(address: backgroundColorAddress, value: SIMD4<Float>(0, 0, 0, 1))

        return plot
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> FloatPlot { return plot }
    public func updateNSView(_ nsView: FloatPlot, context: Context) {}
    #else
    public func makeUIView(context: Context) -> FloatPlot { return plot }
    public func updateUIView(_ uiView: FloatPlot, context: Context) {}
    #endif
}
