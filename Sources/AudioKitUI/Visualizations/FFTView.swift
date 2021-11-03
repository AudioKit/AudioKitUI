// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

class FFTModel: ObservableObject {
    @Published var amplitudes: [Double?] = Array(repeating: nil, count: 50)
    var nodeTap: FFTTap!
    private var FFT_SIZE = 2048
    var node: Node?
    var numberOfBars: Int = 50
    var maxAmplitude: Double = -10.0
    var minAmplitude: Double = -150.0

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

    func updateAmplitudes(_ fftFloats: [Float]) {
        var fftData = fftFloats
        for index in 0 ..< fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }

        var tempAmplitudes: [Double] = []

        // loop by two through all the fft data
        for i in stride(from: 0, to: FFT_SIZE - 1, by: 2) {
            if i / 2 < numberOfBars {
                // get the real and imaginary parts of the complex number
                let real = fftData[i]
                let imaginary = fftData[i + 1]

                let normalizedBinMagnitude = 2.0 * sqrt(real * real + imaginary * imaginary) / Float(FFT_SIZE)
                let amplitude = Double(20.0 * log10(normalizedBinMagnitude))

                // map amplitude array to visualizer
                var mappedAmplitude = map(n: amplitude,
                                          start1: minAmplitude,
                                          stop1: maxAmplitude,
                                          start2: 0.0,
                                          stop2: 1.0)
                if mappedAmplitude > 1.0 {
                    mappedAmplitude = 1.0
                }
                if mappedAmplitude < 0.0 {
                    mappedAmplitude = 0.0
                }

                tempAmplitudes.append(mappedAmplitude)
            }
        }
        // swap the amplitude array
        DispatchQueue.main.async {
            self.amplitudes = tempAmplitudes
        }
    }

    /// simple mapping function to scale a value to a different range
    func map(n: Double, start1: Double, stop1: Double, start2: Double, stop2: Double) -> Double {
        return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
    }
}

public struct FFTView: View {
    @StateObject var fft = FFTModel()
    private var linearGradient: LinearGradient
    private var paddingFraction: CGFloat
    private var includeCaps: Bool
    private var node: Node
    private var numberOfBars: Int
    private var minAmplitude: Double
    private var maxAmplitude: Double
    private var backgroundColor: Color

    public init(_ node: Node,
                linearGradient: LinearGradient = LinearGradient(gradient: Gradient(colors: [.red, .yellow, .green]),
                                                                startPoint: .top,
                                                                endPoint: .center),
                paddingFraction: CGFloat = 0.2,
                includeCaps: Bool = true,
                numberOfBars: Int = 50,
                maxAmplitude: Double = -10.0,
                minAmplitude: Double = -150.0,
                backgroundColor: Color = Color.black)
    {
        self.node = node
        self.linearGradient = linearGradient
        self.paddingFraction = paddingFraction
        self.includeCaps = includeCaps
        self.numberOfBars = numberOfBars
        self.maxAmplitude = maxAmplitude
        self.minAmplitude = minAmplitude
        self.backgroundColor = backgroundColor

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
        .background(backgroundColor)
    }
}

struct FFTView_Previews: PreviewProvider {
    static var previews: some View {
        FFTView(Mixer())
    }
}

struct AmplitudeBar: View {
    var amplitude: Double
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
