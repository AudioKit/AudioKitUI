// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI
import AudioKit
import AVFoundation

public struct TrackView<Segment: ViewableSegment>: View {
    var segments: [Segment]
    var rmsFramesPerSecond: Double
    var pixelsPerRMS: Double

    public init(segments: [Segment], rmsFramesPerSecond: Double = 50, pixelsPerRMS: Double = 1) {
        self.segments = segments
        self.rmsFramesPerSecond = rmsFramesPerSecond
        self.pixelsPerRMS = pixelsPerRMS
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.gray.opacity(0.1)
            ForEach(segments) { segment in
                SegmentView<Segment>(segment: segment,
                                     rmsFramesPerSecond: rmsFramesPerSecond,
                                     pixelsPerRMS: pixelsPerRMS)
            }
        }
    }
}

struct SegmentView<Segment: ViewableSegment>: View {
    var segment: Segment
    var rmsFramesPerSecond: Double
    var pixelsPerRMS: Double

    var rmsValuesForRange: [Float] {
        let startingIndex = Int(segment.fileStartTime * rmsFramesPerSecond)
        let endingIndex = Int(segment.fileEndTime * rmsFramesPerSecond)-1
        return Array(segment.rmsValues[startingIndex...endingIndex])
    }

    var body: some View {
            AudioWaveform(rmsVals: rmsValuesForRange)
                .fill(Color.black)
                .background(Color.gray.opacity(0.1))
                .frame(width: pixelsPerRMS * Double(rmsValuesForRange.count))
                .offset(x: segment.playbackStartTime * rmsFramesPerSecond * pixelsPerRMS)
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        let rmsFramesPerSecond: Double = 50

        let segment1 = try! MockSegment(audioFileURL: TestAudioURLs.drumloop.url(),
                                        playbackStartTime: 0.0,
                                        rmsFramesPerSecond: 50)
        let segment2 = try! MockSegment(audioFileURL: TestAudioURLs.drumloop.url(),
                                        playbackStartTime: 5.0,
                                        rmsFramesPerSecond: 50)
        let segments = [segment1, segment2]

        return TrackView<MockSegment>(segments: segments, rmsFramesPerSecond: rmsFramesPerSecond)
    }
}

public protocol ViewableSegment: Identifiable {
    var playbackStartTime: TimeInterval { get }
    var playbackEndTime: TimeInterval { get }
    var fileStartTime: TimeInterval { get }
    var fileEndTime: TimeInterval { get }
    var rmsValues: [Float] { get }
}

public struct MockSegment: ViewableSegment, StreamableAudioSegment {
    public var id = UUID()
    public var audioFile: AVAudioFile
    public var playbackStartTime: TimeInterval
    public var fileStartTime: TimeInterval = 0
    public var fileEndTime: TimeInterval
    public var completionHandler: AVAudioNodeCompletionHandler?
    public var rmsValues: [Float]
    var rmsFramesPerSecond: Double

    public var playbackEndTime: TimeInterval {
        let duration = fileEndTime - fileStartTime
        return playbackStartTime + duration
    }

    public init(audioFileURL: URL, playbackStartTime: TimeInterval, rmsFramesPerSecond: Double) throws {
        do {
            self.playbackStartTime = playbackStartTime
            self.rmsFramesPerSecond = rmsFramesPerSecond
            audioFile = try AVAudioFile(forReading: audioFileURL)
            rmsValues = AudioHelpers.getRMSValues(url: audioFileURL, rmsFramesPerSecond: rmsFramesPerSecond)
            fileEndTime = AudioHelpers.getFileEndTime(audioFile)
        } catch {
            throw error
        }
    }
}
