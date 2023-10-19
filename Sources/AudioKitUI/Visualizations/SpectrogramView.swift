// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

// MARK: FFTDataReadings

struct FFTDataReadings {
    var maxItems: Int
    var queue = Queue()

    mutating func pushToQueue(points: [CGPoint]) {
        queue.enqueue(element: points)
        if queue.items.count >= maxItems {
            queue.dequeue()
        }
    }

    init(maxItems: Int) {
        self.maxItems = maxItems
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            queue = createTestData()
        } else {
            queue = createEmptyData()
        }
    }

    func createEmptyData() -> Queue {
        var queue = Queue()
        for _ in 0 ... maxItems - 1 {
            var points: [CGPoint] = []
            for i in 0 ..< 210 {
                let frequency = 44100 * 0.5 * CGFloat(i * 2) / CGFloat(2048)
                let amplitude = CGFloat(-200.0)
                points.append(CGPoint(x: frequency, y: amplitude))
            }
            queue.enqueue(element: points)
        }
        return queue
    }

    func createTestData() -> Queue {
        var queue = Queue()
        for _ in 0 ... maxItems - 1 {
            var points: [CGPoint] = []
            for i in 0 ..< 210 {
                let frequency = 44100 * 0.5 * CGFloat(i * 2) / CGFloat(2048)
                let amplitude = CGFloat.random(in: -200 ... 0)
                points.append(CGPoint(x: frequency, y: amplitude))
            }
            queue.enqueue(element: points)
        }
        return queue
    }
}

// MARK: Queue

struct Queue {
    var items: [[CGPoint]] = []

    mutating func enqueue(element: [CGPoint]) {
        items.append(element)
    }

    mutating func dequeue() {
        if !items.isEmpty {
            items.remove(at: 0)
        }
    }
}

// MARK: SpectrogramModel

class SpectrogramModel: ObservableObject {
    @Published var fftDataReadings = FFTDataReadings(maxItems: 80)

    var nodeTap: FFTTap!
    private var FFT_SIZE = 1024
    let sampleRate: double_t = 44100
    var node: Node?

    var minFreq: CGFloat = 30.0
    var maxFreq: CGFloat = 20000.0

    func updateNode(_ node: Node) {
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node, bufferSize: UInt32(FFT_SIZE * 2), callbackQueue: .main) { fftData in
                self.pushData(fftData)
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
        for index in 0 ..< fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }
        captureAmplitudeFrequencyData(fftData)
    }

    /// Returns frequency, amplitude pairs after removing unwanted data points (there are simply too many in the high frequencies)
    func captureAmplitudeFrequencyData(_ fftFloats: [Float]) {
        // I don't love making these extra arrays
        let real = fftFloats.indices.compactMap { $0 % 2 == 0 ? fftFloats[$0] : nil }
        let imaginary = fftFloats.indices.compactMap { $0 % 2 != 0 ? fftFloats[$0] : nil }

        var maxSquared: Float = 0.0
        var frequencyChosen = 0.0

        var points: [CGPoint] = []

        for i in 0 ..< real.count {
            // I don't love doing this sort of calculation for every element
            let frequencyForBin = sampleRate * 0.5 * Double(i * 2) / Double(real.count * 2)

            var squared = real[i] * real[i] + imaginary[i] * imaginary[i]

            if frequencyForBin > Double(maxFreq) {
                continue
            }

            if frequencyForBin > 10000 {
                if squared > maxSquared {
                    maxSquared = squared
                    frequencyChosen = frequencyForBin
                }
                if i % 8 != 0 {
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
                if i % 4 != 0 {
                    // take the greatest 1 in every 4 points when > 1k Hz.
                    continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            } else {
                frequencyChosen = frequencyForBin
            }
            let amplitude = Double(10 * log10(4 * squared / (Float(FFT_SIZE) * Float(FFT_SIZE))))
            points.append(CGPoint(x: frequencyChosen, y: amplitude))
        }
        fftDataReadings.pushToQueue(points: points)
    }
}

// MARK: SpectrogramView

public struct SpectrogramView: View {
    @StateObject var spectrogram = SpectrogramModel()
    let node: Node
    let linearGradient: LinearGradient
    let strokeColor: Color
    let fillColor: Color
    let bottomColor: Color
    let sideColor: Color
    let backgroundColor: Color

    public init(node: Node,
                linearGradient: LinearGradient = LinearGradient(gradient: .init(colors: [.blue, .green, .yellow, .red]),
                                                                startPoint: .bottom,
                                                                endPoint: .top),
                strokeColor: Color = Color.white.opacity(0.8),
                fillColor: Color = Color.green.opacity(1.0),
                bottomColor: Color = Color.white.opacity(0.5),
                sideColor: Color = Color.white.opacity(0.2),
                backgroundColor: Color = Color.black) {
        self.node = node
        self.linearGradient = linearGradient
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.bottomColor = bottomColor
        self.sideColor = sideColor
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        let xOffset = CGFloat(0.22) / CGFloat(spectrogram.fftDataReadings.maxItems)
        let yOffset = CGFloat(-0.8) / CGFloat(spectrogram.fftDataReadings.maxItems)

        return GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .onAppear {
                        spectrogram.updateNode(node)
                    }
                ForEach((0 ..< spectrogram.fftDataReadings.maxItems).reversed(), id: \.self) { i in
                    Group {
                        createSpectrumFill(width: geometry.size.width * 0.75,
                                           height: geometry.size.height * 0.2,
                                           points: spectrogram.fftDataReadings.queue.items[spectrogram.fftDataReadings.maxItems - i - 1])
                        createBottomLine(width: geometry.size.width * 0.75, height: geometry.size.height * 0.2)
                        createLeftSideLine(width: geometry.size.width * 0.75, height: geometry.size.height * 0.2)
                        createRightSideLine(width: geometry.size.width * 0.75, height: geometry.size.height * 0.2)
                        if i == 0 {
                            createSpectrumStroke(width: geometry.size.width * 0.75,
                                                 height: geometry.size.height * 0.2,
                                                 points: spectrogram.fftDataReadings.queue.items[spectrogram.fftDataReadings.maxItems - i - 1])
                        }
                    }
                    .frame(width: geometry.size.width * 0.5,
                           height: geometry.size.height * 0.2)
                    .offset(x: CGFloat(i) * geometry.size.width * xOffset - geometry.size.width / 4.3,
                            y: CGFloat(i) * geometry.size.height * yOffset + geometry.size.height / 2.6)
                }
            }.drawingGroup()
        }
    }

    func createSpectrumFill(width: CGFloat, height: CGFloat, points: [CGPoint]) -> some View {
        var mappedPoints = mapPoints(width: width, height: height, points: points)
        mappedPoints.append(CGPoint(x: Double(width), y: Double(height)))
        mappedPoints.append(CGPoint(x: 0.0, y: Double(height)))

        return Path { path in
            path.addLines(mappedPoints)
        }
        .fill(linearGradient)
    }

    func createSpectrumStroke(width: CGFloat, height: CGFloat, points: [CGPoint]) -> some View {
        let mappedPoints = mapPoints(width: width, height: height, points: points)
        return Path { path in
            path.addLines(mappedPoints)
        }
        .stroke(strokeColor)
    }

    func mapPoints(width: CGFloat, height: CGFloat, points: [CGPoint]) -> [CGPoint] {
        var mappedPoints: [CGPoint] = []
        let startY = points[0].y.mapped(from: -200 ... 0, to: 0 ... height)
        mappedPoints.append(CGPoint(x: 0.0, y: height - startY))

        for i in 0 ..< points.count {
            let x = points[i].x.mappedLog10(from: spectrogram.minFreq ... spectrogram.maxFreq, to: 0 ... width)
            var y = points[i].y.mapped(from: -200 ... 0, to: 0 ... height)
            if x > 0.0 {
                if y < 0.0 {
                    y = 0.0
                }
                mappedPoints.append(CGPoint(x: x, y: height - y))
            }
        }
        return mappedPoints
    }

    func createBottomLine(width: CGFloat, height: CGFloat) -> some View {
        var points: [CGPoint] = []
        points.append(CGPoint(x: 0.0, y: height))
        points.append(CGPoint(x: width, y: height))

        return Path { path in
            path.addLines(points)
        }
        .stroke(bottomColor)
    }

    func createLeftSideLine(width _: CGFloat, height: CGFloat) -> some View {
        var points: [CGPoint] = []
        points.append(CGPoint(x: 0.0, y: 0.0))
        points.append(CGPoint(x: 0.0, y: height))
        return Path { path in
            path.addLines(points)
        }
        .stroke(sideColor)
    }

    func createRightSideLine(width: CGFloat, height: CGFloat) -> some View {
        var points: [CGPoint] = []
        points.append(CGPoint(x: width, y: 0.0))
        points.append(CGPoint(x: width, y: height))
        return Path { path in
            path.addLines(points)
        }
        .stroke(sideColor)
    }
}

// MARK: Preview

struct SpectrogramView_Previews: PreviewProvider {
    static var previews: some View {
        return SpectrogramView(node: Mixer())
    }
}
