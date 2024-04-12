// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

#if !os(macOS) || targetEnvironment(macCatalyst)

import SwiftUI

/// One slice with frequencies from low frequencies at the bottom up to high frequences. 
/// Amplitudes shown in different colors according to the submitted gradient 
/// Resulting image has an integral size (dimensions in Int), so they are most of 
/// the time a bit smaller than requested. This is because they are drawn in 
/// a CGContext that doesn't have fractions of pixels to draw.  
struct SpectrogramSlice: View, Identifiable {
    static var counterSinceStart = 0
    // static Int instead of a UUID as identifier. While debugging it's practical 
    // to see the order and therefore time the slice was created.
    // Furthermore for the sake of premature performance optimisation: 
    // Incrementing an Int could be supposedly faster than creating UUID.
    // depending on the version of swiftlint, this will be marked as rule violation to be 2 characters in length
    // swiftlint:disable identifier_name
    let id: Int
    // swiftlint:enable identifier_name
    // we don't provide defaults, the caller really should know about these
    let gradientUIColors: [UIColor]
    let sliceWidth: CGFloat
    let sliceHeight: CGFloat
    let rawFftReadings: [Float]
    let fftMetaData: SpectrogramFFTMetaData
    // they don't contain CGPoints in the sense of graphic but in the sense of vectors.
    // x describing the frequency axis and y the amplitude axis.
    private var fftReadingFrequencyAmplitudePairs: [CGPoint]
    private var cachedUIImage: UIImage
    private var allRects: [CGRect]
    private var allColors: [Color]

    init(
        gradientUIColors: [UIColor],
        sliceWidth: CGFloat,
        sliceHeight: CGFloat,
        fftReadings: [Float],
        fftMetaData: SpectrogramFFTMetaData
    ) {
        self.gradientUIColors = gradientUIColors
        self.sliceWidth = sliceWidth
        self.sliceHeight = sliceHeight
        self.rawFftReadings = fftReadings
        self.fftMetaData = fftMetaData
        Self.counterSinceStart = Self.counterSinceStart &+ 1
        id = Self.counterSinceStart
        allRects = []
        allColors = []
        fftReadingFrequencyAmplitudePairs = []
        cachedUIImage = UIImage(systemName: "pause")!

        self.fftReadingFrequencyAmplitudePairs = captureAmplitudeFrequencyData(fftReadings)

        createSpectrumRects()
        cachedUIImage = createSpectrumImage()

        // release data, we don't need it anymore
        fftReadingFrequencyAmplitudePairs = []
        allRects = []
        allColors = []
    }

    /// convenience initialiser, useful when measurements are created manually 
    init(
        gradientUIColors: [UIColor],
        sliceWidth: CGFloat,
        sliceHeight: CGFloat,
        fftReadingsFrequencyAmplitudePairs: [CGPoint],
        fftMetaData: SpectrogramFFTMetaData
    ) {
        self.gradientUIColors = gradientUIColors
        self.sliceWidth = sliceWidth
        self.sliceHeight = sliceHeight
        self.fftReadingFrequencyAmplitudePairs = fftReadingsFrequencyAmplitudePairs
        self.fftMetaData = fftMetaData
        Self.counterSinceStart = Self.counterSinceStart &+ 1
        id = Self.counterSinceStart
        allRects = []
        allColors = []
        self.rawFftReadings = []
        cachedUIImage = UIImage(systemName: "pause")!

        createSpectrumRects()
        cachedUIImage = createSpectrumImage()
    }

    public var body: some View {
        return Image(uiImage: cachedUIImage).resizable()
            // flip it as the slice was drawn in the first quadrant
            .scaleEffect(x: 1, y: -1)
    }

    // This code draws in the first quadrant, it's much easier to understand 
    // when we can draw from low to high frequency bottom to top.
    // will have to flip the image when using in a typical Spectrogram View
    func createSpectrumImage() -> UIImage {
        // return an empty image when no data here to visualize.
        guard allRects.count > 0 else { return UIImage() }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: sliceWidth, height: sliceHeight))
        let img = renderer.image { ctx in
            for index in 0...allRects.count-1 {
                UIColor(allColors[index]).setFill()
                ctx.fill(allRects[index])
            }
        }
        return img
    }

    // unused method drawing into a Canvas. Might be useful in the future 
    // when doing more energy efficent drawing. 
    // MARK: createSpectrumSlice() 
    /* func createSpectrumSlice() -> some View {
        return Canvas { context, _ in
            for index in 0...allRects.count-1 {
                context.fill(
                    Path(allRects[index]),
                    with: .color(allColors[index])
                )
            }
            // flip it back. Code is much easier to understand when we can draw from low to high frequency
            // drawing in the first quadrant, as we did in macOS Core Animation
        }.scaleEffect(x: 1, y: -1)
    } */

    mutating func createSpectrumRects() {
        guard fftReadingFrequencyAmplitudePairs.count > 0 else { return }
        // calc rects and color within initialiser, so the drawing will just use those
        // fftReadings contains typically 210 pairs with frequency (x) and amplitude (y)
        // those then are mapped to y coordinate and color
        let mappedCells = mapFftReadingsToCells()
        // size.height is it's height shown
        // size.width is intensitiy between  0..1
        var cumulativePosition = 0.0
        var cellHeight = sliceHeight / CGFloat(fftReadingFrequencyAmplitudePairs.count)
        // iterating thru the array with an index (instead of enumeration)
        // as index is used to calc height
        for index in 0...mappedCells.count - 1 {
            // index 0 contains highest y, meaning lowest frequency
            cellHeight = mappedCells[index].height
            let thisRect =  CGRect(
                origin: CGPoint(x: 0, y: cumulativePosition),
                size: CGSize(width: sliceWidth, height: cellHeight))
            cumulativePosition += cellHeight
            allRects.append(thisRect)
            allColors.append(Color(SpectrogramFlatView.gradientUIColors.intermediate(mappedCells[index].width))  )
        }
        if cumulativePosition > sliceHeight {
            // print("Warning: all cells sum up higher than what could fit: " +
            // "\(cumulativePosition) should be less or equal than: \(sliceHeight) for ID: \(id)")
        }

    }

    // the incoming array of fft readings should be sorted by frequency
    func mapFftReadingsToCells() -> [CGSize] {
        guard fftReadingFrequencyAmplitudePairs.count > 0 else { return [] }
        var outCells: [CGSize] = []
        // never return an empty array
        // the lowest delimiter in full amplitude but no height
        outCells.append(CGSize(width: 1.0, height: 0.0))
        // starting at line 1
        var lastFrequencyPosition = 0.0
        for index in 1 ..< fftReadingFrequencyAmplitudePairs.count {
            let amplitude = fftReadingFrequencyAmplitudePairs[index].y.mapped(from: -200 ... 0, to: 0 ... 1.0)
            // the frequency comes out from lowest frequency at 0 to max frequency at height
            let frequency = fftReadingFrequencyAmplitudePairs[index].x
            let frequencyPosition = frequency.mappedLog10(
                from: fftMetaData.minFreq ... fftMetaData.maxFreq,
                to: 0 ... sliceHeight
            )

            if frequencyPosition < 0.0 {
                // those frequencies come from the fft but we don't show them
                // these are the ones typcally smaller than minFreq
                continue
            }
            // calc height using the last frequency and ceil it to prevent black lines between measurements. 
            // it may happen that a cell is less than 1.0 high: that shouldn't bother us
            let cellHeight = ceil(frequencyPosition - lastFrequencyPosition)
            lastFrequencyPosition += cellHeight
            outCells.append(CGSize(width: amplitude, height: cellHeight))
        }
        // delimiter at top end in full Amplitude but no height
        outCells.append(CGSize(width: 1.0, height: 0.0))
        return outCells
    }

    /// Returns frequency, amplitude pairs after removing unwanted data points,  
    /// there are simply too many in the high frequencies.
    /// The resulting array has fftSize amount of readings. The incoming array is compiled to CGPoints containing
    /// frequency and amplitude, where as x is frequency and y amplitude. 
    /// The amount of pairs depends on minFreq and maxFreq as well as the fftSize.
    /// To understand CGPoint x and y imagine a chart that spans from left to right for lowest to highest frequency
    /// and on shows vertically the amplitude, as the equalizer view of an 80ies stereo system. 
    /// The FFT-slices start at frequency 0, which is odd. 
    /// Lowest frequency meaning amplitude of all frequencies 
    /// from 0 to the first other frequency (typically 5Hz or 21.533Hz) 
    /// 
    /// Alternative implementation: have this array not with CGPoint of frequency and amplitude 
    /// but only of amplitude already color coded in the gradient. The frequency axis 
    /// would then be hardcoded as the plot distance on y-axis
    ///
    /// Improvement: make the filtering of high frequencies dependent of fftSize. 
    /// The more data, the more filtering is needed.  
    /// 
    /// Make this more energy efficient by combining this function with mapFftReadingsToCells

    func captureAmplitudeFrequencyData(_ fftFloats: [Float]) -> [CGPoint] {
        // need at least two data points
        guard fftFloats.count > 1 else { return [] }
        var maxSquared: Float = 0.0
        var frequencyChosen = 0.0
        var points: [CGPoint] = []
        // Frequencies are shown in a logarithmic scale (meaning octaves have same distance).
        // Therefore frequencies above these levels are reduced.
        let filterFrequencyHigh = 8000.0
        let filterFrequencyMid = 4000.0
        let filterFrequency = 1000.0

        for index in 1 ... (fftFloats.count / 2) {
            // Compiler or LLVM will make these four following array access' into two 
            let real = fftFloats[index-1].isNaN ? 0.0 : fftFloats[index-1]
            let imaginary = fftFloats[index].isNaN ? 0.0 : fftFloats[index]
            let frequencyForBin = fftMetaData.sampleRate * 0.5 * Double(index * 2) / Double(fftFloats.count * 2)
            var squared: Float = real * real + imaginary * imaginary

            // if the frequency is higher as we need: continue
            // we don't filter low frequencies, they are all pushed to the queue
            if frequencyForBin > Double(fftMetaData.maxFreq) { continue }
            frequencyChosen = frequencyForBin

            if frequencyForBin > filterFrequencyHigh {
                // take the greatest 1 in every 16 points when > 8k Hz.
                maxSquared = squared > maxSquared ? squared : maxSquared
                if index % 16 != 0 { continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            } else if frequencyForBin > filterFrequencyMid {
                // take the greatest 1 in every 8 points when > 4k Hz.
                maxSquared = squared > maxSquared ? squared : maxSquared
                if index % 8 != 0 { continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            } else if frequencyForBin > filterFrequency {
                // take the greatest 1 in every 2 points when > 1k Hz.
                // This might be already too much data, depending on the highest frequency shown 
                // and the height of where this slice is shown. 
                // might reduce it to show every 4th point. 
                maxSquared = squared > maxSquared ? squared : maxSquared
                if index % 2 != 0 { continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            }
            let fftBins = CGFloat(fftMetaData.fftSize)
            let amplitude = Double(10 * log10(4 * CGFloat(squared) / fftBins * fftBins))
            points.append(CGPoint(x: frequencyChosen, y: amplitude))
        }
        return points
    }
}

// MARK: Preview
@available(iOS 17.0, *)
struct SpectrogramSlice_Previews: PreviewProvider {
    static var previews: some View {
        // This shows the wrong behaviour of the slice: the lowest frequency isn't shown, the 
        // lowest amplitude below -200 should be black but is white. 
        return SpectrogramSlice(gradientUIColors:
                            [(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)), (#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)), (#colorLiteral(red: 0.4217140079, green: 0.6851614118, blue: 0.9599093795, alpha: 1)), (#colorLiteral(red: 0.8122602105, green: 0.6033009887, blue: 0.8759307861, alpha: 1)), (#colorLiteral(red: 0.9826132655, green: 0.5594901443, blue: 0.4263145328, alpha: 1)), (#colorLiteral(red: 1, green: 0.2607713342, blue: 0.4242972136, alpha: 1))],
                         sliceWidth: 40, sliceHeight: 150,
                         fftReadingsFrequencyAmplitudePairs: [
                            CGPoint(x: 150, y: -80),
                            CGPoint(x: 350, y: -50),
                            CGPoint(x: 500, y: -10),
                            CGPoint(x: 1000, y: -160),
                            CGPoint(x: 1500, y: -260),
                            CGPoint(x: 2000, y: -120),
                            CGPoint(x: 3000, y: -80),
                            CGPoint(x: 5000, y: -30),
                            CGPoint(x: 8800, y: -40),
                            CGPoint(x: 8000, y: -10)],
                         fftMetaData: SpectrogramFFTMetaData()
        )
    }
}

#endif
