// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI
import AudioKit

class FFTModel: ObservableObject {
    @Published var amplitudes: [Double] = Array(repeating: 0.95, count: 50)
    var nodeTap: FFTTap!
    private var FFT_SIZE = 512
    
    init(_ node: Node){
        nodeTap = FFTTap(node) { fftData in
            DispatchQueue.main.async {
                self.updateAmplitudes(fftData)
            }
        }
        nodeTap.start()
    }
    
    func updateAmplitudes(_ fftData: [Float]){
        
        // loop by two through all the fft data
        for i in stride(from: 0, to: self.FFT_SIZE - 1, by: 2) {
            
            // get the real and imaginary parts of the complex number
            let real = fftData[i]
            let imaginary = fftData[i + 1]
            
            let normalizedBinMagnitude = 2.0 * sqrt(real * real + imaginary * imaginary) / Float(self.FFT_SIZE)
            let amplitude = Double(20.0 * log10(normalizedBinMagnitude))
            
            // scale the resulting data
            var scaledAmplitude = (amplitude + 250) / 229.80
            
            // restrict the range to 0.0 - 1.0
            if (scaledAmplitude < 0) {
                scaledAmplitude = 0
            }
            if (scaledAmplitude > 1.0) {
                scaledAmplitude = 1.0
            }
            
            // add the amplitude to our array (further scaling array to look good in visualizer)
            DispatchQueue.main.async {
                if(i/2 < self.amplitudes.count){
                    self.amplitudes[i/2] = self.map(n: scaledAmplitude, start1: 0.3, stop1: 0.9, start2: 0.0, stop2: 1.0)
                }
            }
        }
    }
    
    /// simple mapping function to scale a value to a different range
    func map(n:Double, start1:Double, stop1:Double, start2:Double, stop2:Double) -> Double {
        return ((n-start1)/(stop1-start1))*(stop2-start2)+start2;
    }
}

struct FFTView: View {
    
    @ObservedObject var fft : FFTModel
    
    public init(_ node: Node) {
        fft = FFTModel(node)
    }
    
    var linearGradient : LinearGradient = LinearGradient(gradient: Gradient(colors: [.red, .yellow, .green]), startPoint: .top, endPoint: .center)
    var paddingFraction: CGFloat = 0.2
    var includeCaps: Bool = true
    
    var body: some View{
        HStack(spacing: 0.0){
            ForEach(0 ..< fft.amplitudes.count) { number in
                AmplitudeBar(amplitude: fft.amplitudes[number], linearGradient: linearGradient, paddingFraction: paddingFraction, includeCaps: includeCaps)
            }
        }
        .background(Color.black)
    }
    
}

struct FFTView_Previews: PreviewProvider {
    static var previews: some View {
        FFTView(Mixer())
    }
}

struct AmplitudeBar: View {
    var amplitude: Double
    var linearGradient : LinearGradient
    var paddingFraction: CGFloat = 0.2
    var includeCaps: Bool = true
    
    var body: some View {
        GeometryReader
            { geometry in
            ZStack(alignment: .bottom){
                
                // Colored rectangle in back of ZStack
                Rectangle()
                    .fill(self.linearGradient)
                
                // Dynamic black mask padded from bottom in relation to the amplitude
                Rectangle()
                    .fill(Color.black)
                    .mask(Rectangle().padding(.bottom, geometry.size.height * CGFloat(amplitude)))
                    .animation(.easeOut(duration: 0.15))
                
                // White bar with slower animation for floating effect
                if(includeCaps){
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
            .offset(x: 0.0, y: -height > capOffset - capHeight ? capMaxOffset : capOffset) //ternary prevents offset from pushing cap outside of it's frame
            .animation(.easeOut(duration: 0.6))
    }
    
}

