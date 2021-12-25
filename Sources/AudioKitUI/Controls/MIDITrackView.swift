// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/
import AudioKit
import SwiftUI

struct NoteGroup: ViewRepresentable {
    @Binding var isPlaying: Bool
    @Binding var sequencerTempo: Double
    let noteMap: MIDIFileTrackNoteMap
    let length: CGFloat
    let trackHeight: CGFloat
    let noteZoom: CGFloat

    #if os(macOS)
    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: CGRect(x: 0, y: 0, width: length, height: trackHeight))
        populateViewNotes(view, context: context)
        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        if isPlaying {
            setupTimer(nsView)
        }
    }

    func scrollNotes(_ nsView: NSView) {
        nsView.frame.origin.x -= 1
    }
    func populateViewNotes(_ nsView: NSView, context: Context) {
        let noteList = noteMap.noteList
        let low = noteMap.loNote
        let high = noteMap.hiNote
        let range = (high - low) + 1
        let noteh = trackHeight / CGFloat(range)
        let maxh = trackHeight - noteh
        for note in noteList {
            let noteNumber = note.noteNumber - low
            let noteStart = note.noteStartTime
            let noteDuration = note.noteDuration
            let noteLength = CGFloat(noteDuration) * noteZoom
            let notePosition = CGFloat(noteStart) * noteZoom
            let noteLevel = (maxh - (CGFloat(noteNumber) * noteh))
            let singleNoteRect = CGRect(x: notePosition, y: noteLevel, width: noteLength, height: noteh)
            let singleNoteView = NSView(frame: singleNoteRect)
            singleNoteView.layer?.backgroundColor = NSColor.red.cgColor
            singleNoteView.layer?.cornerRadius = noteh * 0.5
            nsView.addSubview(singleNoteView)
        }
    }
    func setupTimer(_ nsView: NSView) {
        let base: Double = (20 + (8.0 / 10.0) + (1.0 / 30.0))
        let inverse: Double = 1.0 / base
        let multiplier: Double = inverse * 60 * (10_000 / Double(noteZoom))
        let scrollTimer = Timer.scheduledTimer(
            withTimeInterval: multiplier * (1/sequencerTempo), repeats: true) { timer in
            scrollNotes(nsView)
            if !isPlaying {
                timer.invalidate()
            }
        }
        RunLoop.main.add(scrollTimer, forMode: .common)
    }
    #else
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: length, height: trackHeight))
        populateViewNotes(view, context: context)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        if isPlaying {
            setupTimer(uiView)
        }
    }

    func scrollNotes(_ uiView: UIView) {
        uiView.frame.origin.x -= 1
    }
    func populateViewNotes(_ uiView: UIView, context: Context) {
        let noteList = noteMap.noteList
        let low = noteMap.loNote
        let high = noteMap.hiNote
        let range = (high - low) + 1
        let noteh = trackHeight / CGFloat(range)
        let maxh = trackHeight - noteh
        for note in noteList {
            let noteNumber = note.noteNumber - low
            let noteStart = note.noteStartTime
            let noteDuration = note.noteDuration
            let noteLength = CGFloat(noteDuration) * noteZoom
            let notePosition = CGFloat(noteStart) * noteZoom
            let noteLevel = (maxh - (CGFloat(noteNumber) * noteh))
            let singleNoteRect = CGRect(x: notePosition, y: noteLevel, width: noteLength, height: noteh)
            let singleNoteView = UIView(frame: singleNoteRect)
            singleNoteView.backgroundColor = UIColor.red
            singleNoteView.layer.cornerRadius = noteh * 0.5
            uiView.addSubview(singleNoteView)
        }
    }
    func setupTimer(_ uiView: UIView) {
        let base: Double = (20 + (8.0 / 10.0) + (1.0 / 30.0))
        let inverse: Double = 1.0 / base
        let multiplier: Double = inverse * 60 * (10_000 / Double(noteZoom))
        let scrollTimer = Timer.scheduledTimer(
            withTimeInterval: multiplier * (1/sequencerTempo), repeats: true) { timer in
            scrollNotes(uiView)
            if !isPlaying {
                timer.invalidate()
            }
        }
        RunLoop.main.add(scrollTimer, forMode: .common)
    }
    #endif
}
/// MIDI track UI similar to the one in your DAW
public struct MIDITrackView: View {
    @State public var isPlaying = false
    @State var sequencerTempo = 0.0
    let trackWidth: CGFloat
    let trackHeight: CGFloat
    public var fileURL: URL
    /// Sets the zoom level of the track
    public var noteZoom: CGFloat = 50_000

    public init(trackWidth: CGFloat, trackHeight: CGFloat, fileURL: URL, noteZoom: CGFloat = 50_000) {
        self.trackWidth = trackWidth
        self.trackHeight = trackHeight
        self.fileURL = fileURL
        self.noteZoom = noteZoom
    }
    public var body: some View {
        let sequencer = AppleSequencer(fromURL: fileURL)
        VStack {
            ForEach(sequencer.tracks.indices, id: \.self) { number in
                if number < sequencer.tracks.count - 1 {
                    let noteMap = MIDIFileTrackNoteMap(midiFile: MIDIFile(url: fileURL), trackNumber: number)
                    let length = CGFloat(noteMap.endOfTrack) * noteZoom
                    NoteGroup(isPlaying: $isPlaying,
                              sequencerTempo: $sequencerTempo,
                              noteMap: noteMap, length: length,
                              trackHeight: trackHeight,
                              noteZoom: noteZoom)
                        .frame(width: trackWidth, height: trackHeight, alignment: .center)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
        }
        .onTapGesture {
            isPlaying.toggle()
            if isPlaying {
                sequencer.play()
                sequencerTempo = sequencer.allTempoEvents[0].1
            } else {
                if sequencer.isPlaying {
                    sequencer.stop()
                }
            }
        }
    }
}
