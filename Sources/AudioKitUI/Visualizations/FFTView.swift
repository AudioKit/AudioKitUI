// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import SwiftUI

class FFTModel: ObservableObject {
    @Published var amplitudes: [Float?] = Array(repeating: nil, count: 50)
    var nodeTap: FFTTap!
    private var FFT_SIZE = 2048
    var node: Node?
    var numberOfBars: Int = 50
    var maxAmplitude: Float = -10.0
    var minAmplitude: Float = -150.0

    func updateNode(_ node: Node) {
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node) { fftData in
                DispatchQueue.main.async {
                    self.updateAmplitudes(fftData)
                }
            }
            nodeTap.isNormalized = false
            nodeTap.start()
        }
    }

    func updateAmplitudes(_ fftData: [Float]) {
        var tempAmplitudes = Array(repeating: 0.0 as Float, count: numberOfBars)
        let binsPerBar = Int((Float(fftData.count) / Float(numberOfBars)).rounded(.up))

        var one = Float(1.0)
        var zero = Float(0.0)
        var decibelNormalizationFactor = Float(1.0 / (maxAmplitude - minAmplitude))
        var decibelNormalizationOffset = Float(-minAmplitude / (maxAmplitude - minAmplitude))

        var decibels = [Float](repeating: 0, count: fftData.count)
        vDSP_vdbcon(fftData, 1, &one, &decibels, 1, vDSP_Length(fftData.count), 0)
        vDSP_vsmsa(
            decibels, 1,
            &decibelNormalizationFactor,
            &decibelNormalizationOffset,
            &decibels, 1,
            vDSP_Length(decibels.count)
        )
        vDSP_vclip(decibels, 1, &zero, &one, &decibels, 1, vDSP_Length(decibels.count))

        for (index, decibel) in decibels.enumerated() {
            let bar = index / binsPerBar

            tempAmplitudes[bar] += decibel * (1 / Float(binsPerBar))
        }        

        // swap the amplitude array
        DispatchQueue.main.async {
            self.amplitudes = tempAmplitudes
        }
    }
}

public struct FFTView: View {
    @StateObject var fft = FFTModel()
    private var linearGradient: LinearGradient
    private var paddingFraction: CGFloat
    private var includeCaps: Bool
    private var node: Node
    private var numberOfBars: Int
    private var minAmplitude: Float
    private var maxAmplitude: Float

    public init(_ node: Node,
                linearGradient: LinearGradient = LinearGradient(gradient: Gradient(colors: [.red, .yellow, .green]),
                                                                startPoint: .top,
                                                                endPoint: .center),
                paddingFraction: CGFloat = 0.2,
                includeCaps: Bool = true,
                numberOfBars: Int = 50,
                maxAmplitude: Float = -10.0,
                minAmplitude: Float = -150.0)
    {
        self.node = node
        self.linearGradient = linearGradient
        self.paddingFraction = paddingFraction
        self.includeCaps = includeCaps
        self.numberOfBars = numberOfBars
        self.maxAmplitude = maxAmplitude
        self.minAmplitude = minAmplitude

        if maxAmplitude < minAmplitude {
            fatalError("Maximum amplitude cannot be less than minimum amplitude")
        }
        if minAmplitude > 0.0 || maxAmplitude > 0.0 {
            fatalError("Amplitude values must be less than zero")
        }
    }

    public var body: some View {
        HStack(spacing: 0.0) {
            ForEach(fft.amplitudes.indices, id: \.self) { number in
                if let amplitude = fft.amplitudes[number] {
                    AmplitudeBar(amplitude: amplitude,
                                 linearGradient: linearGradient,
                                 paddingFraction: paddingFraction,
                                 includeCaps: includeCaps)
                }
            }
        }.onAppear {
            fft.updateNode(node)
            fft.numberOfBars = numberOfBars
            fft.maxAmplitude = maxAmplitude
            fft.minAmplitude = minAmplitude
        }
        .drawingGroup() // Metal powered rendering
        .background(Color.black)
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

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Colored rectangle in back of ZStack
                Rectangle()
                    .fill(linearGradient)

                // Dynamic black mask padded from bottom in relation to the amplitude
                Rectangle()
                    .fill(Color.black)
                    .mask(Rectangle().padding(.bottom, geometry.size.height * CGFloat(amplitude)))
                    .animation(.easeOut(duration: 0.15))

                // White bar with slower animation for floating effect
                if includeCaps {
                    addCap(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .padding(geometry.size.width * paddingFraction / 2)
            .border(Color.black, width: geometry.size.width * paddingFraction / 2)
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
