// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

// MARK: SpectrumModel

class SpectrumModel: ObservableObject {
    @Environment(\.isPreview) var isPreview
    @Published var amplitudes: [CGFloat] = []
    @Published var frequencies: [CGFloat] = []
    
    private var node: Node?
    private var sampleRate: double_t = 44100
    private var nodeTap: FFTTap!
    private var FFT_SIZE = 2048
    private var minDeadBand: CGFloat = 40.0
    private var maxDeadBand: CGFloat = 40.0
    private var currentMidAmp: CGFloat = 100.0
    var minFreq: CGFloat = 30.0
    var maxFreq: CGFloat = 20000.0
    private var minAmp: CGFloat = -1.0
    private var maxAmp: CGFloat = -1000.0
    var topAmp: CGFloat = -60.0
    var bottomAmp: CGFloat = -216.0
    private var ampDisplacement: CGFloat = 120.0 / 2.0
    private let maxSpan: CGFloat = 170
    
    init() {
        if isPreview {
            createTestData()
        }
    }
    
    func createTestData() {
        var fakeFrequencies: [CGFloat] = []
        var fakeAmplitudes: [CGFloat] = []
        for i in 0..<255 {
            let frequency = CGFloat(sampleRate * 0.5) * CGFloat(i * 2) / CGFloat(512 * 2)
            let amplitude = CGFloat.random(in: -175...(-70))
            fakeFrequencies.append(frequency)
            fakeAmplitudes.append(amplitude)
        }
        frequencies = fakeFrequencies
        amplitudes = fakeAmplitudes
    }
    
    func updateNode(_ node: Node) {
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node, bufferSize: UInt32(FFT_SIZE * 2)) { fftData in
                DispatchQueue.main.async {
                    self.pushData(fftData)
                }
            }
            nodeTap.isNormalized = false
            nodeTap.zeroPaddingFactor = 1
            nodeTap.start()
        }
    }
    
    func pushData(_ fftFloats: [Float]) {
        // validate data
        // extra array necessary?
        var fftData = fftFloats
        for index in 0..<fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }
        
        captureAmplitudeFrequencyData(fftData)
        determineAmplitudeBounds()
    }
    
    /// Returns frequency, amplitude pairs after removing unwanted data points (there are simply too many in the high frequencies)
    func captureAmplitudeFrequencyData(_ fftFloats: [Float]) {
        // I don't love making these extra arrays
        let real = fftFloats.indices.compactMap { $0 % 2 == 0 ? fftFloats[$0] : nil }
        let imaginary = fftFloats.indices.compactMap { $0 % 2 != 0 ? fftFloats[$0] : nil }
        
        var maxSquared: CGFloat = 0.0
        var frequencyChosen: CGFloat = 0.0
        
        var tempAmplitudes: [CGFloat] = []
        var tempFrequencies: [CGFloat] = []
        
        var minAmplitude: CGFloat = -1.0
        var maxAmplitude: CGFloat = -1000.0
        
        for i in 0..<real.count {
            // I don't love doing this for every element
            let frequencyForBin = CGFloat(sampleRate) * 0.5 * CGFloat(i * 2) / CGFloat(real.count * 2)
            
            var squared = CGFloat(real[i] * real[i] + imaginary[i] * imaginary[i])
            
            if frequencyForBin > maxFreq {
                continue
            }
            
            if frequencyForBin > 10000 {
                if squared > maxSquared {
                    maxSquared = squared
                    frequencyChosen = frequencyForBin
                }
                if i % 16 != 0 {
                    // take the greatest 1 in every 8 points when > 10k Hz.
                    continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            } else if frequencyForBin > 1000 {
                if squared > maxSquared {
                    maxSquared = squared
                    frequencyChosen = frequencyForBin
                }
                if i % 8 != 0 {
                    // take the greatest 1 in every 4 points when > 1k Hz.
                    continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            } else {
                frequencyChosen = frequencyForBin
            }
            
            let amplitude = CGFloat(10 * log10(4 * squared / (CGFloat(FFT_SIZE) * CGFloat(FFT_SIZE))))

            if amplitude > maxAmplitude {
                maxAmplitude = amplitude
            } else if amplitude < minAmplitude {
                minAmplitude = amplitude
            }
            
            tempAmplitudes.append(amplitude)
            tempFrequencies.append(frequencyChosen)
        }
        
        amplitudes = tempAmplitudes
        frequencies = tempFrequencies
        minAmp = minAmplitude
        maxAmp = maxAmplitude
    }
    
    /// Figures out what we should use for the maximum and minimum amplitudes displayed
    /// Also sets a "mid" amp which the dead band lies around
    func determineAmplitudeBounds() {
        if maxDeadBand < abs(maxAmp - currentMidAmp) || minDeadBand < abs(maxAmp - currentMidAmp) {
            // place us at a new location
            if abs(maxAmp) < ampDisplacement {
                currentMidAmp = -ampDisplacement
            } else {
                currentMidAmp = maxAmp
            }
            topAmp = currentMidAmp + ampDisplacement
            bottomAmp = currentMidAmp - ampDisplacement
            if bottomAmp > minAmp {
                if topAmp - minAmp > maxSpan {
                    bottomAmp = topAmp - maxSpan
                } else {
                    bottomAmp = minAmp
                }
            }
        }
    }
}

// MARK: SpectrumView

public struct SpectrumView: View {
    @StateObject var spectrum = SpectrumModel()
    var node: Node
    @State var frequencyDisplayed: CGFloat = 100.0
    @State var amplitudeDisplayed: CGFloat = -100.0
    @State var cursorX: CGFloat = 0.0
    @State var cursorY: CGFloat = 0.0
    @State var popupX: CGFloat = 0.0
    @State var popupY: CGFloat = 0.0
    @State var popupOpacity: Double = 0.0
    @State var cursorDisplayed: Bool = false
    private var backgroundColor: Color
    private var shouldPlotPoints: Bool
    private var plotPointColor: Color
    private var shouldStroke: Bool
    private var strokeColor: Color
    private var shouldFill: Bool
    private var fillColor: Color
    private var shouldAnalyzeTouch: Bool
    private var cursorColor: Color
    private var shouldDisplayAxisLabels: Bool
    
    public init(_ node: Node,
                backgroundColor: Color = Color.black,
                shouldPlotPoints: Bool = false,
                plotPointColor: Color = Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.8),
                shouldStroke: Bool = true,
                strokeColor: Color = Color.white,
                shouldFill: Bool = true,
                fillColor: Color = Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.4),
                shouldAnalyzeTouch: Bool = true,
                cursorColor: Color = Color.white,
                shouldDisplayAxisLabels: Bool = true)
    {
        self.node = node
        self.backgroundColor = backgroundColor
        self.shouldPlotPoints = shouldPlotPoints
        self.plotPointColor = plotPointColor
        self.shouldStroke = shouldStroke
        self.strokeColor = strokeColor
        self.shouldFill = shouldFill
        self.fillColor = fillColor
        self.shouldAnalyzeTouch = shouldAnalyzeTouch
        self.cursorColor = cursorColor
        self.shouldDisplayAxisLabels = shouldDisplayAxisLabels
    }
    
    public var body: some View {
        GeometryReader { geometry in
            createGraphView(width: geometry.size.width, height: geometry.size.height)
                .drawingGroup()
                .onAppear {
                    spectrum.updateNode(node)
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            var x: CGFloat = value.location.x > geometry.size.width ? geometry.size.width : 0.0
                            if value.location.x > 0.0, value.location.x < geometry.size.width {
                                x = value.location.x
                            }
                            var y: CGFloat = value.location.y > geometry.size.height ? geometry.size.height : 0.0
                            if value.location.y > 0.0, value.location.y < geometry.size.height {
                                y = value.location.y
                            }
                            
                            cursorX = x
                            cursorY = y
                            
                            popupX = x > geometry.size.width / 4 ? x - geometry.size.width / 8 : x + geometry.size.width / 8
                            popupY = y > geometry.size.height / 4 ? y - geometry.size.height / 8 : y + geometry.size.height / 8

                            frequencyDisplayed = x.mappedExp(from: 0...geometry.size.width, to: spectrum.minFreq...spectrum.maxFreq)
                            amplitudeDisplayed = y.mappedInverted(from: 0...geometry.size.height, to: spectrum.bottomAmp...spectrum.topAmp)
                            
                            cursorDisplayed = true
                            popupOpacity = 1.0
                        }
                        .onEnded { _ in
                            popupOpacity = 0.0
                        }
                )
            
            if cursorDisplayed && shouldAnalyzeTouch {
                ZStack {
                    createCrossLines(width: geometry.size.width, height: geometry.size.height)
                    
                    CircleCursorView(cursorColor: cursorColor)
                        .frame(width: geometry.size.width / 30, height: geometry.size.height / 30)
                        .position(x: cursorX, y: cursorY)
                    
                    SpectrumPopupView(frequency: $frequencyDisplayed, amplitude: $amplitudeDisplayed, colorForeground: cursorColor)
                        .position(x: popupX, y: popupY)
                }
                .opacity(popupOpacity)
                .animation(.default)
                .drawingGroup()
            }
        }
    }
    
    private func createCrossLines(width: CGFloat, height: CGFloat) -> some View {
        var horizontalPoints: [CGPoint] = []
        horizontalPoints.append(CGPoint(x: 0.0, y: cursorY))
        horizontalPoints.append(CGPoint(x: width, y: cursorY))
        
        var verticalPoints: [CGPoint] = []
        verticalPoints.append(CGPoint(x: cursorX, y: 0.0))
        verticalPoints.append(CGPoint(x: cursorX, y: height))
        return ZStack {
            Path { path in
                path.addLines(horizontalPoints)
            }
            .stroke(strokeColor, lineWidth: 2).opacity(0.7)
            Path { path in
                path.addLines(verticalPoints)
            }
            .stroke(strokeColor, lineWidth: 2).opacity(0.7)
        }
    }
    
    private func createGraphView(width: CGFloat, height: CGFloat) -> some View {
        return ZStack {
            backgroundColor

            if shouldPlotPoints {
                createSpectrumCircles(width: width, height: height)
            }
            
            if shouldStroke || shouldFill {
                createSpectrumShape(width: width, height: height)
            }
            
            HorizontalAxis(minX: spectrum.minFreq, maxX: spectrum.maxFreq, isLogarithmicScale: true, shouldDisplayAxisLabel: shouldDisplayAxisLabels)
            VerticalAxis(minY: $spectrum.bottomAmp, maxY: $spectrum.topAmp, shouldDisplayAxisLabel: shouldDisplayAxisLabels)
        }
    }
    
    func createSpectrumCircles(width: CGFloat, height: CGFloat) -> some View {
        var mappedPoints: [CGPoint] = []
        
        // I imagine this is not good computationally
        for i in 0..<spectrum.amplitudes.count {
            let mappedAmplitude = spectrum.amplitudes[i].mappedInverted(from: spectrum.bottomAmp...spectrum.topAmp)
            let mappedFrequency = spectrum.frequencies[i].mappedLog10(from: spectrum.minFreq...spectrum.maxFreq)
            mappedPoints.append(CGPoint(x: mappedFrequency, y: mappedAmplitude))
        }
        
        return ZStack {
            ForEach(1..<mappedPoints.count, id: \.self) {
                if mappedPoints[$0].x > 0.00001 {
                    Circle()
                        .fill(plotPointColor)
                        .frame(width: width * 0.005)
                        .position(CGPoint(x: mappedPoints[$0].x * width, y: mappedPoints[$0].y * height))
                        .animation(.easeInOut(duration: 0.1))
                }
            }
        }
    }
    
    func createSpectrumShape(width: CGFloat, height: CGFloat) -> some View {
        var mappedIndexedDoubles: [Double] = []
        
        // I imagine this is not good computationally
        for i in 0..<spectrum.amplitudes.count {
            let mappedAmplitude = spectrum.amplitudes[i].mappedInverted(from: spectrum.bottomAmp...spectrum.topAmp)
            var mappedFrequency = spectrum.frequencies[i].mappedLog10(from: spectrum.minFreq...spectrum.maxFreq)
            
            if mappedFrequency < 0.0 || mappedFrequency > 1.0 {
                mappedFrequency = 0.0
            }
            mappedIndexedDoubles.append(Double(mappedFrequency))
            mappedIndexedDoubles.append(Double(mappedAmplitude))
        }
        
        // just some stuff that gets us the fill
        mappedIndexedDoubles.append(1.0)
        mappedIndexedDoubles.append(1.0)
        mappedIndexedDoubles.append(0.0)
        mappedIndexedDoubles.append(1.0)
        
        return ZStack {
            if shouldStroke {
                MorphableShape(controlPoints: AnimatableVector(with: mappedIndexedDoubles))
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .animation(.easeInOut(duration: 0.1))
            }
            
            if shouldFill {
                MorphableShape(controlPoints: AnimatableVector(with: mappedIndexedDoubles))
                    .fill(fillColor)
                    .animation(.easeInOut(duration: 0.1))
            }
        }
    }
}

// MARK: HorizontalAxis

struct HorizontalAxis: View {
    @State var minX: CGFloat = 30
    @State var maxX: CGFloat = 20000
    @State var isLogarithmicScale: Bool = true
    @State var shouldDisplayAxisLabel: Bool = true
    
    public var body: some View {
        let verticalLineXLocations: [CGFloat] = [100.0, 1000.0, 10000.0]
        let verticalLineLabels = ["100", "1k", "10k"]
        
        var verticalLineXLocationsMapped: [CGFloat] = Array(repeating: 0.0, count: verticalLineXLocations.count)
        
        if isLogarithmicScale {
            for i in 0..<verticalLineXLocations.count {
                verticalLineXLocationsMapped[i] = verticalLineXLocations[i].mappedLog10(from: minX...maxX)
            }
        } else {
            for i in 0..<verticalLineXLocations.count {
                verticalLineXLocationsMapped[i] = verticalLineXLocations[i].mapped(from: minX...maxX)
            }
        }
        
        return ZStack {
            GeometryReader { geo in
                ForEach(0..<verticalLineXLocationsMapped.count, id: \.self) { i in
                    Path { path in
                        path.move(to: CGPoint(x: verticalLineXLocationsMapped[i] * geo.size.width, y: 0.0))
                        path.addLine(to: CGPoint(x: verticalLineXLocationsMapped[i] * geo.size.width, y: geo.size.height))
                    }
                    .stroke(Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.8))

                    if shouldDisplayAxisLabel {
                        Text(verticalLineLabels[i])
                            .font(.footnote)
                            .foregroundColor(.white)
                            .position(x: verticalLineXLocationsMapped[i] * geo.size.width + geo.size.width * 0.02, y: geo.size.height * 0.03)
                    }
                }
            }
        }
    }
}

// MARK: VerticalAxis

struct VerticalAxis: View {
    @Binding var minY: CGFloat
    @Binding var maxY: CGFloat
    @State var shouldDisplayAxisLabel: Bool = true
    
    public var body: some View {
        var horizontalLineYLocations: [CGFloat] = []
        for i in 1...20 {
            let amp = CGFloat(i) * -12.0
            if i % 2 != 0 {
                horizontalLineYLocations.append(amp)
            }
        }
        
        var horizontalLineYLocationsMapped: [CGFloat] = Array(repeating: 0.0, count: horizontalLineYLocations.count)
        var locationData: [HorizontalLineData] = []
        
        for i in 0..<horizontalLineYLocations.count {
            horizontalLineYLocationsMapped[i] = horizontalLineYLocations[i].mappedInverted(from: minY...maxY)
            locationData.append(HorizontalLineData(yLoc: Double(horizontalLineYLocationsMapped[i])))
        }
        
        return ZStack {
            GeometryReader { geo in
                ForEach(0..<horizontalLineYLocationsMapped.count, id: \.self) { i in
                    if horizontalLineYLocationsMapped[i] > 0.0 && horizontalLineYLocationsMapped[i] < 1.0 {
                        MorphableShape(controlPoints: AnimatableVector(with: locationData[i].locationData))
                            .stroke(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.4))
                            .animation(.easeInOut(duration: 0.2))
                        
                        if shouldDisplayAxisLabel {
                            let labelString = String(Int(horizontalLineYLocations[i]))
                            Text(labelString)
                                .position(x: geo.size.width * 0.03, y: horizontalLineYLocationsMapped[i] * geo.size.height - geo.size.height * 0.03)
                                .animation(.easeInOut(duration: 0.2))
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
    
    // This packages the y locations in a convenient way for the MorphableShape struct
    struct HorizontalLineData {
        let locationData: [Double]
        
        init(yLoc: Double) {
            locationData = [0.0, yLoc, 1.0, yLoc]
        }
    }
}

// MARK: SpectrumView_Previews

struct SpectrumView_Previews: PreviewProvider {
    static var previews: some View {
        SpectrumView(Mixer())
    }
}
