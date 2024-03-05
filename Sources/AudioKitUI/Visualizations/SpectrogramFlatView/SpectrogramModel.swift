// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/
//

import AudioKit
import SwiftUI

struct SpectrogramFFTMetaData {
    // fftSize defines how detailled the music is analyzed in the time domain. 
    // the lower the value, the less detail:
    // * 1024: will receive about four analyzed frequencies between C2 and C* (65Hz to 130Hz). New data comes roughly 21.5 times per second, each 46ms.  
    // * 2048: will receive about eight analyzed frequencies between C2 and C* (65Hz to 130Hz).  New data comes roughly 11 times per second, each 93ms. 
    // * 4096: will receive about 16 analyzed frequencies between C2 and C* (65Hz to 130Hz). New data comes roughly  5.5 times per second, each 186ms.  
    // Choose a higher value when you want to analyze low frequencies, choose a lower value when you want fast response and high frame rate on display
    // Default: 2048
    var fftSize = 4096/2

    // how/why can the sample rate be edited? Shouldn't this come from the node/engine?
    // if the sample rate is changed, does the displayed frequency range also have to be changed?
    // took this from existing SpectrogramView, will investigate later
    var sampleRate: double_t = 44100
}

struct SliceQueue {
    var maxItems: Int = 120
    var items: [SpectrogramSlice] = []
    
    public mutating func pushToQueue(element: SpectrogramSlice) {
        enqueue(element: element)
        if items.count > maxItems {
            dequeue()
        }
    }

    private mutating func enqueue(element: SpectrogramSlice) {
        items.append(element)
    }

    private mutating func dequeue() {
        if !items.isEmpty {
            items.remove(at: 0)
        }
    }
}

///  Model for the SpectrogramFlatView. Makes connection to the audio node and receives FFT data
class SpectrogramModel: ObservableObject {
    @Published var slices = SliceQueue()
    var sliceSize = CGSize(width: 10, height: 250) {
        didSet {
            if xcodePreview { createTestData() }
        }
    }
    let nodeMetaData = SpectrogramFFTMetaData()
    let xcodePreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    var nodeTap: FFTTap!
    var node: Node?

    // we use 48Hz, which is a bit lower than G1. A1 would be 440Hz/8 = 55Hz.  
    // The lowest human bass voice in choral music is reaching down to C1 (32.7 Hz). 
    // don't go lower than 6.0, it just doesn't make sense and the display gets terribly distorted
    // don't use 0 as it breaks the display because log10(0) is undefined and this error not handled
    var minFreq: CGFloat = 48.0
    // we will not show anything above 13500 as it's not music anymore but just the overtones
    var maxFreq: CGFloat = 13500.0

    // create a filled Queue, always full of stuff. looks a bit better. 
    // otherwise it would be fast moving at the beginning and then  
    // pressing together until full (looks funny though :-). 
    // In case of Xcode Preview, filling of queue will be done in 
    // setSliceSize called typically from the geometry reader. 
    init() {
        if !xcodePreview { 
            createEmptyData() 
        }
    }

    // fill the queue with empty data so the layouting doesn't start in the middle
    private func createEmptyData() {
        for _ in 0 ... slices.maxItems - 1 {
            var points: [CGPoint] = []
            for i in 0 ..< 10 {
                let frequency = CGFloat(Float(i) * Float.pi)
                let amplitude = CGFloat(-200.0)
                points.append(CGPoint(x: frequency, y: amplitude))
            }
            // size and freuqency doesnt' really matter as it will all be black
            let slice = SpectrogramSlice(
                gradientUIColors: SpectrogramFlatView.gradientUIColors,
                sliceWidth: sliceSize.width,
                sliceHeight: sliceSize.height,
                fftReadingsAsTupels: points,
                spectrogramMinFreq: minFreq,
                spectrogramMaxFreq: maxFreq, 
                fftMetaData: nodeMetaData
            )
            slices.pushToQueue(element:slice)
        }
    }

    private func createTestData() {
        let testCellAmount = 200
        for _ in 0 ... slices.maxItems - 1 {
            var points: [CGPoint] = []
            // lowest and highest frequency full amplitude to see the rendering showing full frequency spectrum
            // CGPoint x: frequency  y: Amplitude -200 ... 0 whereas 0 is full loud volume 
            for i in 0 ... testCellAmount {
                // linear frequency range from 48 to 13500 in amount of steps we generate
                let frequency = 48.0 + CGFloat( i * (13500 / testCellAmount ))  
                var amplitude = CGFloat.random(in: -200 ... 0)
                // add some silence to the test data
                amplitude = amplitude < -80 ? amplitude : -200.0  
                points.append(CGPoint(x: frequency, y: amplitude))
            }
            let slice = SpectrogramSlice(
                gradientUIColors: SpectrogramFlatView.gradientUIColors,
                sliceWidth: sliceSize.width,
                sliceHeight: sliceSize.height,
                fftReadingsAsTupels: points,
                spectrogramMinFreq: minFreq,
                spectrogramMaxFreq: maxFreq,
                fftMetaData: nodeMetaData
            )
            slices.pushToQueue(element:slice)
        }
    }
    
    func updateNode(_ node: Node) {
        // Using a background thread to get data from FFTTap. 
        // This doesn't make it more efficient but will not bother 
        // main thread and user while doing the work
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node, bufferSize: UInt32(nodeMetaData.fftSize * 2), callbackQueue: .global()) { fftData in
                self.pushData(fftData)
            }
            // normalization would mean that on each slice, the loudest would have 
            // amplitude 1.0, independent of what has happened before. 
            // we don't want that as we want absolute measurements that can be compared over time. 
            nodeTap.isNormalized = false
            nodeTap.zeroPaddingFactor = 1
            nodeTap.start()
        }
    }

    func pushData(_ fftFloats: [Float]) {
        // Comes several times per second, depending on fftSize. 
        // This call pushes new fftReadings into the queue. 
        // Queue ist observed by the view and thus view is updated. 
        // The incoming array of floats contains 2 * fftSize entries. coded in real and imaginery part. 
        // The frequencies in the even numbers and the amplitudes in the odd numbers of the array. 
        let slice = SpectrogramSlice(
            gradientUIColors: SpectrogramFlatView.gradientUIColors,
            sliceWidth: sliceSize.width,
            sliceHeight: sliceSize.height,
            fftReadings: fftFloats,
            spectrogramMinFreq: minFreq,
            spectrogramMaxFreq: maxFreq, 
            fftMetaData: nodeMetaData
        )
        // we receive the callback typically on a background thread, where 
        // also the slice image was rendered. to inform UI we dispatch it on main thread
        DispatchQueue.main.async {
            self.slices.pushToQueue(element: slice)
        }
    }

}

