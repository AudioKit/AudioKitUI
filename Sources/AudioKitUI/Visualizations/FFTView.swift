// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import SwiftUI

class FFTModel: ObservableObject {
    @Published var amplitudes: [Float?] = Array(repeating: nil, count: 50)
    var nodeTap: FFTTap!
    var node: Node?
    var numberOfBars: Int = 50
    var maxAmplitude: Float = 0.0
    var minAmplitude: Float = -70.0
    var referenceValueForFFT: Float = 12.0

    func updateNode(_ node: Node, fftValidBinCount: FFTValidBinCount? = nil) {
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node, fftValidBinCount: fftValidBinCount) { fftData in
                DispatchQueue.main.async {
                    self.updateAmplitudes(fftData)
                }
            }
            nodeTap.isNormalized = false
            nodeTap.start()
        }
    }

    func updateAmplitudes(_ fftFloats: [Float]) {
        var fftData = fftFloats
        for index in 0 ..< fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }

        var one = Float(1.0)
        var zero = Float(0.0)
        var decibelNormalizationFactor = Float(1.0 / (maxAmplitude - minAmplitude))
        var decibelNormalizationOffset = Float(-minAmplitude / (maxAmplitude - minAmplitude))

        var decibels = [Float](repeating: 0, count: fftData.count)
        vDSP_vdbcon(fftData, 1, &referenceValueForFFT, &decibels, 1, vDSP_Length(fftData.count), 0)

        vDSP_vsmsa(decibels,
                   1,
                   &decibelNormalizationFactor,
                   &decibelNormalizationOffset,
                   &decibels,
                   1,
                   vDSP_Length(decibels.count))

        vDSP_vclip(decibels, 1, &zero, &one, &decibels, 1, vDSP_Length(decibels.count))

        // swap the amplitude array
        DispatchQueue.main.async {
            self.amplitudes = decibels
        }
    }
}

public struct FFTView: View {
    @StateObject var fft = FFTModel()
    private var linearGradient: LinearGradient
    private var paddingFraction: CGFloat
    private var includeCaps: Bool
    private var node: Node
    private var barCount: Int
    private var fftValidBinCount: FFTValidBinCount?
    private var minAmplitude: Float
    private var maxAmplitude: Float
    private let defaultBarCount: Int = 64
    private let maxBarCount: Int = 128
    private var backgroundColor: Color

    public init(_ node: Node,
                linearGradient: LinearGradient = LinearGradient(gradient: Gradient(colors: [.red, .yellow, .green]),
                                                                startPoint: .top,
                                                                endPoint: .center),
                paddingFraction: CGFloat = 0.2,
                includeCaps: Bool = true,
                validBinCount: FFTValidBinCount? = nil,
                barCount: Int? = nil,
                maxAmplitude: Float = -10.0,
                minAmplitude: Float = -150.0,
                backgroundColor: Color = Color.black)
    {
        self.node = node
        self.linearGradient = linearGradient
        self.paddingFraction = paddingFraction
        self.includeCaps = includeCaps
        self.maxAmplitude = maxAmplitude
        self.minAmplitude = minAmplitude
        self.fftValidBinCount = validBinCount
        self.backgroundColor = backgroundColor

        if maxAmplitude < minAmplitude {
            fatalError("Maximum amplitude cannot be less than minimum amplitude")
        }
        if minAmplitude > 0.0 || maxAmplitude > 0.0 {
            fatalError("Amplitude values must be less than zero")
        }

        if let requestedBarCount = barCount {
            self.barCount = requestedBarCount
        } else {
            if let fftBinCount = fftValidBinCount {
                if Int(fftBinCount.rawValue) > maxBarCount - 1 {
                    self.barCount = maxBarCount
                } else {
                    self.barCount = Int(fftBinCount.rawValue)
                }
            } else {
                self.barCount = defaultBarCount
            }
        }
    }

    public var body: some View {
        HStack(spacing: 0.0) {
			ForEach(0 ..< barCount, id: \.self) {
                if $0 < fft.amplitudes.count {
                    if let amplitude = fft.amplitudes[$0] {
                        AmplitudeBar(amplitude: amplitude,
                                     linearGradient: linearGradient,
                                     paddingFraction: paddingFraction,
                                     includeCaps: includeCaps)
                    }
                } else {
                    AmplitudeBar(amplitude: 0.0,
                                 linearGradient: linearGradient,
                                 paddingFraction: paddingFraction,
                                 includeCaps: includeCaps,
                                 backgroundColor: backgroundColor)
                }
            }
        }.onAppear {
            fft.updateNode(node, fftValidBinCount: self.fftValidBinCount)
            fft.maxAmplitude = self.maxAmplitude
            fft.minAmplitude = self.minAmplitude
        }
        .drawingGroup() // Metal powered rendering
        .background(backgroundColor)
    }
}

struct FFTView_Previews: PreviewProvider {
    static var previews: some View {
        FFTView(Mixer())
    }
}

struct AmplitudeBar: View {
    var amplitude: Float
    var linearGradient: LinearGradient
    var paddingFraction: CGFloat = 0.2
    var includeCaps: Bool = true
    var backgroundColor: Color = Color.black

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Colored rectangle in back of ZStack
                Rectangle()
                    .fill(linearGradient)

                // Dynamic black mask padded from bottom in relation to the amplitude
                Rectangle()
                    .fill(backgroundColor)
                    .mask(Rectangle().padding(.bottom, geometry.size.height * CGFloat(amplitude)))
                    .animation(.easeOut(duration: 0.15))

                // White bar with slower animation for floating effect
                if includeCaps {
                    addCap(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .padding(geometry.size.width * paddingFraction / 2)
            .border(backgroundColor, width: geometry.size.width * paddingFraction / 2)
        }
    }

    // Creates the Cap View - seperate method allows variable definitions inside a GeometryReader
    func addCap(width: CGFloat, height: CGFloat) -> some View {
        let padding = width * paddingFraction / 2
        let capHeight = height * 0.005
        let capDisplacement = height * 0.02
        let capOffset = -height * CGFloat(amplitude) - capDisplacement - padding * 2
        let capMaxOffset = -height + capHeight + padding * 2

        return Rectangle()
            .fill(Color.white)
            .frame(height: capHeight)
            .offset(x: 0.0, y: -height > capOffset - capHeight ? capMaxOffset : capOffset) // prevents offset from pushing cap outside of it's frame
            .animation(.easeOut(duration: 0.6))
    }
}
