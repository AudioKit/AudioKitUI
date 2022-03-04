// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI
import AudioKit
import Accelerate

class AudioFileWaveformViewModel: ObservableObject {
    @Published var rmsValues = [Float]()
    
    init(url: URL) {
        rmsValues = getRMSValues(url: url)
    }

    func getRMSValues(url: URL) -> [Float] {
        if let audioInformation = loadAudioSignal(audioURL: url) {
            let signal = audioInformation.signal
            return createRMSAnalysisArray(signal: signal, windowSize: Int(audioInformation.rate/256))
        }
        return []
    }

    func createRMSAnalysisArray(signal: [Float], windowSize: Int) -> [Float] {
        let numberOfSamples = signal.count
        let numberOfOutputArrays = numberOfSamples / windowSize
        var outputArray: [Float] = []
        for index in 0...numberOfOutputArrays-1 {
            let startIndex = index * windowSize
            let endIndex = startIndex + windowSize >= signal.count ? signal.count-1 : startIndex + windowSize
            let arrayToAnalyze = Array(signal[startIndex..<endIndex])
            var rms: Float = 0
            vDSP_rmsqv(arrayToAnalyze, 1, &rms, UInt(windowSize))
            outputArray.append(rms)
        }
        return outputArray
    }
}

public struct AudioFileWaveform: View {
    @ObservedObject var viewModel: AudioFileWaveformViewModel

    public init(url: URL) {
        viewModel = AudioFileWaveformViewModel(url: url)
    }

    public var body: some View {
        AudioWaveform(rmsVals: viewModel.rmsValues)
            .fill(Color.gray)
    }
}

struct AudioFileWaveform_Previews: PreviewProvider {
    static var previews: some View {
        AudioFileWaveform(url: TestAudioURLs.drumloop.url())
    }
}
