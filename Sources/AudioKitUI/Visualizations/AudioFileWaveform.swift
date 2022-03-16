// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI
import AudioKit
import Accelerate

class AudioFileWaveformViewModel: ObservableObject {
    @Published var rmsValues = [Float]()

    init(url: URL, rmsFramesPerSecond: Double) {
        rmsValues = AudioHelpers.getRMSValues(url: url, rmsFramesPerSecond: rmsFramesPerSecond)
    }

    init(url: URL, rmsSamplesPerWindow: Int) {
        rmsValues = AudioHelpers.getRMSValues(url: url, windowSize: rmsSamplesPerWindow)
    }
}

public struct AudioFileWaveform: View {
    @ObservedObject var viewModel: AudioFileWaveformViewModel

    public init(url: URL, rmsSamplesPerWindow: Int = 256) {
        viewModel = AudioFileWaveformViewModel(url: url,
                                               rmsSamplesPerWindow: rmsSamplesPerWindow)
    }

    public var body: some View {
        if viewModel.rmsValues.count > 2 {
            AudioWaveform(rmsVals: viewModel.rmsValues)
                .fill(Color.gray)
        } else {
            AudioWaveform(rmsVals: viewModel.rmsValues)
                .stroke(Color.gray)
        }
    }
}

struct AudioFileWaveform_Previews: PreviewProvider {
    static var previews: some View {
        AudioFileWaveform(url: TestAudioURLs.drumloop.url())
        AudioFileWaveform(url: TestAudioURLs.short.url(), rmsSamplesPerWindow: 1)
        AudioFileWaveform(url: TestAudioURLs.short.url())
    }
}
