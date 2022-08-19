// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import SwiftUI

class AudioFileWaveformViewModel: ObservableObject {
    @Published var rmsValues = [Float]()

    var url = URL(string: "")
    var windowSize = 0

    init() {}

    func update(url: URL, rmsSamplesPerWindow: Int) {
        if url != self.url || rmsSamplesPerWindow != windowSize {
            rmsValues = AudioHelpers.getRMSValues(url: url, windowSize: rmsSamplesPerWindow)
            self.url = url
            windowSize = rmsSamplesPerWindow
        }
    }
}

public struct AudioFileWaveform: View {
    @StateObject private var viewModel = AudioFileWaveformViewModel()

    var url: URL
    var rmsSamplesPerWindow: Int
    var color: Color

    public init(url: URL, rmsSamplesPerWindow: Int = 256, color: Color = Color.gray) {
        self.url = url
        self.rmsSamplesPerWindow = rmsSamplesPerWindow
        self.color = color
    }

    public var body: some View {
        Group {
            if viewModel.rmsValues.count > 2 {
                AudioWaveform(rmsVals: viewModel.rmsValues)
                    .fill(color)
            } else {
                AudioWaveform(rmsVals: viewModel.rmsValues)
                    .stroke(color)
            }
        }.onAppear {
            viewModel.update(url: url, rmsSamplesPerWindow: rmsSamplesPerWindow)
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
