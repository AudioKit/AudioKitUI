// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import SwiftUI

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
    let color: Color

    public init(url: URL, rmsSamplesPerWindow: Int = 256, color: Color = Color.gray) {
        viewModel = AudioFileWaveformViewModel(url: url,
                                               rmsSamplesPerWindow: rmsSamplesPerWindow)
        self.color = color
    }

    public var body: some View {
        if viewModel.rmsValues.count > 2 {
            AudioWaveform(rmsVals: viewModel.rmsValues)
                .fill(color)
        } else {
            AudioWaveform(rmsVals: viewModel.rmsValues)
                .stroke(color)
        }
    }
}

struct AudioFileWaveform_Previews: PreviewProvider {
    static var previews: some View {
        AudioFileWaveform(url: TestAudioURLs.drumloop.url())
        AudioFileWaveform(url: TestAudioURLs.drumloop.url(), color: .red)
        AudioFileWaveform(url: TestAudioURLs.short.url(), rmsSamplesPerWindow: 1)
        AudioFileWaveform(url: TestAudioURLs.short.url())
    }
}
