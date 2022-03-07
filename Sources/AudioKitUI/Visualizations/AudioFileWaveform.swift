// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI
import AudioKit
import Accelerate

class AudioFileWaveformViewModel: ObservableObject {
    @Published var rmsValues = [Float]()
    var rmsWindowSize: Double
    
    init(url: URL, rmsWindowSize: Double) {
        self.rmsWindowSize = rmsWindowSize
        rmsValues = AudioHelpers.getRMSValues(url: url, rmsFramesPerSecond: rmsWindowSize)
    }
}

public struct AudioFileWaveform: View {
    @ObservedObject var viewModel: AudioFileWaveformViewModel

    public init(url: URL, rmsWindowSize: Double = 256) {
        viewModel = AudioFileWaveformViewModel(url: url,
                                               rmsWindowSize: rmsWindowSize)
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
