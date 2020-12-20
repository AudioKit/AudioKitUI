// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import SwiftUI

#if os(macOS)
public typealias ViewRepresentable = NSViewRepresentable
#else
public typealias ViewRepresentable = UIViewRepresentable
#endif

public struct NodeFFTView: ViewRepresentable {
    var node: Tappable
    let bufferSampleCount = 1024

    let foregroundColorAddress = 0
    let backgroundColorAddress = 1

    public init(node tappableNode: Tappable) {
        node = tappableNode
    }

    internal var plot: FloatPlot {
        node.installTap()

        let isFFT = false
        let isCentered = false
        let metalFragmentOrig = """
        float sample = waveform.sample(s, \(isFFT ? "(pow(10, in.t.x) - 1.0) / 9.0" : "in.t.x")).x;

        half4 backgroundColor = half4(colorParameters[1]);
        half4 foregroundColor = half4(colorParameters[0]);

        float y = (in.t.y - \(isCentered ? 0.5 : 1));
        bool isFilled = parameters[0] != 0;
        float d = isFilled ? fmax(fabs(y) - fabs(sample), 0) : fabs(y - sample);
        float alpha = \(isFFT ? "fabs(1/(50 * d))" : "smoothstep(0.01, 0.04, d)");
        return { mix(foregroundColor, backgroundColor, alpha) };
        """

        let plot = FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), fragment: metalFragmentOrig) {
            let data = node.getTapData(sampleCount: bufferSampleCount)

            if data.count < 2 || data[0].count < bufferSampleCount {
                return []
            }

            let signal = data[0]

            // The length of the input
            let length = vDSP_Length(signal.count)
            // The power of two of two times the length of the input.
            // Do not forget this factor 2.
            let log2n = vDSP_Length(ceil(log2(Float(length * 2))))
            // Create the instance of the FFT class which allow computing FFT of complex vector with length
            // up to `length`.
            let fftSetup = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)!

            // Input / Output arrays

            var forwardInputReal = [Float](signal) // Copy the signal here
            var forwardInputImag = [Float](repeating: 0, count: Int(length))
            var forwardOutputReal = [Float](repeating: 0, count: Int(length))
            var forwardOutputImag = [Float](repeating: 0, count: Int(length))

            var magnitudes = [Float](repeating: 0, count: Int(length))
            var normalizedMagnitudes = [Float](repeating: 0.0, count: Int(length))
            forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
                forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                    forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                        forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in
                            // Input
                            let forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!, imagp: forwardInputImagPtr.baseAddress!)
                            // Output
                            var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!, imagp: forwardOutputImagPtr.baseAddress!)

                            fftSetup.forward(input: forwardInput, output: &forwardOutput)
                            vDSP.absolute(forwardOutput, result: &magnitudes)
                            vDSP_vsmul(&magnitudes,
                                       1,
                                       [1.0 / (magnitudes.max() ?? 1.0)],
                                       &normalizedMagnitudes,
                                       1,
                                       length)
                        }
                    }
                }
            }

            normalizedMagnitudes = normalizedMagnitudes.dropLast(bufferSampleCount / 2)

            return normalizedMagnitudes
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
