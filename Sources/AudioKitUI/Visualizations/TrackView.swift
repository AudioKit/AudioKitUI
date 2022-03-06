// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI
import AudioKit
import AVFAudio

public struct TrackView<Segment: ViewableSegment>: View {
    var segments: [Segment]

    public init(segments: [Segment]) {
        self.segments = segments
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray.opacity(0.1)
            ForEach(segments) { segment in
                AudioWaveform(rmsVals: segment.rmsValuesForRange)
                    .fill(Color.black)
                    .background(Color.gray.opacity(0.1))
                    .offset(x: segment.playbackStartTime * RMS_FRAMES_PER_SECOND * PIXELS_PER_RMS_FRAME)
                    .frame(width: PIXELS_PER_RMS_FRAME * Double(segment.rmsValuesForRange.count))
            }
        }
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        let segment1 = try! MockSegment(audioFileURL: TestAudioURLs.drumloop.url(), playbackStartTime: 0.0)
        let segment2 = try! MockSegment(audioFileURL: TestAudioURLs.drumloop.url(), playbackStartTime: 5.0)
        let segments = [segment1, segment2]

        return TrackView<MockSegment>(segments: segments)
    }
}

public protocol ViewableSegment: Identifiable {
    var playbackStartTime: TimeInterval { get }
    var playbackEndTime: TimeInterval { get }
    var rmsValuesForRange: [Float] { get }
}

private let RMS_FRAMES_PER_SECOND: Double = 50
private let PIXELS_PER_RMS_FRAME: Double = 1

public struct MockSegment: ViewableSegment, StreamableAudioSegment {
    public var id = UUID()
    public var audioFile: AVAudioFile
    public var playbackStartTime: TimeInterval
    public var fileStartTime: TimeInterval = 0
    public var fileEndTime: TimeInterval
    public var completionHandler: AVAudioNodeCompletionHandler?
    private var rmsValues: [Float]

    public var rmsValuesForRange: [Float] {
        let startingIndex = Int(fileStartTime * RMS_FRAMES_PER_SECOND)
        let endingIndex = Int(fileEndTime * RMS_FRAMES_PER_SECOND)-1
        return Array(rmsValues[startingIndex...endingIndex])
    }

    public var playbackEndTime: TimeInterval {
        let duration = fileEndTime - fileStartTime
        return playbackStartTime + duration
    }

    public init(audioFileURL: URL, playbackStartTime: TimeInterval) throws {
        do {
            self.playbackStartTime = playbackStartTime
            audioFile = try AVAudioFile(forReading: audioFileURL)
            rmsValues = AudioHelpers.getRMSValues(url: audioFileURL, rmsFramesPerSecond: RMS_FRAMES_PER_SECOND)
            fileEndTime = AudioHelpers.getFileEndTime(audioFile)
        } catch {
            throw error
        }
    }
}
