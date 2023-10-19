// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/
import AudioKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI
import Combine
import Foundation
#if os(macOS)
class NoteView: NSView {
    var viewModel: MIDITrackViewModel?
    var cancellable = Set<AnyCancellable>()

    func addViewModel( _ withModel: MIDITrackViewModel) {
        self.viewModel = withModel
        self.viewModel?.$trackPosition
            .sink(receiveValue: { [unowned self] pixelValue in
                self.frame.origin.x = pixelValue
            }).store(in: &cancellable)
    }
}
#else
class NoteView: UIView {
    var viewModel: MIDITrackViewModel?
    var cancellable = Set<AnyCancellable>()

    func addViewModel( _ withModel: MIDITrackViewModel) {
        self.viewModel = withModel
        self.viewModel?.$trackPosition
            .sink(receiveValue: { [unowned self] pixelValue in
                self.frame.origin.x = pixelValue
            }).store(in: &cancellable)
    }
}
#endif
struct NotesModel: ViewRepresentable {
    @Binding var fileURL: URL?
    var viewModel: MIDITrackViewModel
    let trackNumber: Int
    let trackHeight: CGFloat
    let noteZoom: CGFloat = 50_000.0
    #if os(macOS)
    func makeNSView(context: Context) -> some NSView {
        if let fileURL = fileURL {
            let noteMap = MIDIFileTrackNoteMap(midiFile: MIDIFile(url: fileURL), trackNumber: trackNumber)
            let length = CGFloat(noteMap.endOfTrack) * noteZoom
            let view = NoteView(frame: NSRect(x: 0, y: 0, width: length, height: trackHeight))
            view.addViewModel(viewModel)
            populateViewNotes(view, context: context, noteMap: noteMap)
            return view
        } else {
            let view = NoteView()
            view.addViewModel(viewModel)
            return view
        }
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        if let fileURL = fileURL {
            let noteMap = MIDIFileTrackNoteMap(midiFile: MIDIFile(url: fileURL), trackNumber: trackNumber)
            let length = CGFloat(noteMap.endOfTrack) * noteZoom
            nsView.frame.size.width = length
            nsView.frame.size.height = trackHeight
            nsView.frame.origin.y = 0
            nsView.frame.origin.x = 0
            populateViewNotes(nsView, context: context, noteMap: noteMap)
        } else {
            if nsView.subviews.count > 0 {
                nsView.subviews.forEach({ $0.removeFromSuperview()})
            }
            nsView.frame.size.width = 0
            nsView.frame.size.height = 0
            nsView.frame.origin.y = 0
            nsView.frame.origin.x = 0
            viewModel.trackPosition = 0
        }
    }

    func populateViewNotes(_ nsView: NSView, context: Context, noteMap: MIDIFileTrackNoteMap) {
        let noteList = noteMap.noteList
        let low = noteMap.loNote
        let range = noteMap.noteRange
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
            singleNoteView.layer?.backgroundColor = CGColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            singleNoteView.layer?.cornerRadius = noteh * 0.5
            nsView.addSubview(singleNoteView)
        }
    }
    #else
    func makeUIView(context: Context) -> some UIView {
        if let fileURL = fileURL {
            let noteMap = MIDIFileTrackNoteMap(midiFile: MIDIFile(url: fileURL), trackNumber: trackNumber)
            let length = CGFloat(noteMap.endOfTrack) * noteZoom
            let view = NoteView(frame: CGRect(x: 0, y: 0, width: length, height: trackHeight))
            view.addViewModel(viewModel)
            populateViewNotes(view, context: context, noteMap: noteMap)
            return view
        } else {
            let view = NoteView()
            view.addViewModel(viewModel)
            return view
        }
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let fileURL = fileURL {
            let noteMap = MIDIFileTrackNoteMap(midiFile: MIDIFile(url: fileURL), trackNumber: trackNumber)
            let length = CGFloat(noteMap.endOfTrack) * noteZoom
            uiView.frame.size.width = length
            uiView.frame.size.height = trackHeight
            uiView.frame.origin.y = 0
            uiView.frame.origin.x = 0
            populateViewNotes(uiView, context: context, noteMap: noteMap)
        } else {
            if uiView.subviews.count > 0 {
                uiView.subviews.forEach({ $0.removeFromSuperview()})
            }
            uiView.frame.size.width = 0
            uiView.frame.size.height = 0
            uiView.frame.origin.y = 0
            uiView.frame.origin.x = 0
            viewModel.trackPosition = 0
        }
    }

    func populateViewNotes(_ uiView: UIView, context: Context, noteMap: MIDIFileTrackNoteMap) {
        let noteList = noteMap.noteList
        let low = noteMap.loNote
        let range = noteMap.noteRange
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
            singleNoteView.backgroundColor = UIColor.secondarySystemBackground
            singleNoteView.layer.cornerRadius = noteh * 0.5
            singleNoteView.clipsToBounds = true
            uiView.addSubview(singleNoteView)
        }
    }
    #endif
}

public class MIDITrackViewModel: ObservableObject {
    @Published var trackPosition: CGFloat = 0.0
    let engine = AudioEngine()
    var lastTempo: Double = 0.0
    var sequencer: AppleSequencer = AppleSequencer()
    var sampler: MIDISampler = MIDISampler()
    var trackTimer: Timer = Timer()
    public init() {
        engine.output = Reverb(sampler, dryWetMix: 0.2)
    }

    public func startEngine() {
        do {
            try engine.start()
        } catch {
        }
    }
    public func stopEngine() {
        engine.stop()
    }

    public func play() {
        let base: Double = (20 + (8.0 / 10.0) + (1.0 / 30.0))
        let inverse: Double = 1.0 / base
        let multiplier: Double = inverse * 60 * (10_000 / Double(50_000.0))
        sequencer.play()
        trackTimer = Timer.scheduledTimer(timeInterval: multiplier * (1/lastTempo),
                                          target: self, selector: #selector(self.update),
                                          userInfo: nil, repeats: true)
        RunLoop.main.add(trackTimer, forMode: .common)
    }

    public func stop() {
        sequencer.stop()
        trackTimer.invalidate()
    }

    @objc func update() {
        if lastTempo != sequencer.tempo && sequencer.allTempoEvents.count > 1 {
            lastTempo = sequencer.tempo
            trackTimer.invalidate()
            play()
        }
        trackPosition -= 1
    }

    public func loadSequencerFile(fileURL: URL) {
        sequencer.loadMIDIFile(fromURL: fileURL)
        if sequencer.allTempoEvents.isNotEmpty {
            lastTempo = sequencer.allTempoEvents[0].1
        } else {
            lastTempo = sequencer.tempo
        }
        sequencer.setGlobalMIDIOutput(sampler.midiIn)
        do {
            try sampler.loadSoundFont("UprightPianoKW-20190703", preset: 0, bank: 0)
        } catch {
        }
    }
}
/// MIDI track UI similar to the one in your DAW
public struct MIDITrackView: View {
    @EnvironmentObject var viewModel: MIDITrackViewModel
    @Binding var fileURL: URL?
    var trackNumber: Int
    let trackWidth: CGFloat
    let trackHeight: CGFloat

    public init(fileURL: Binding<URL?>,
                trackNumber: Int,
                trackWidth: CGFloat,
                trackHeight: CGFloat
    ) {
        _fileURL = fileURL
        self.trackNumber = trackNumber
        self.trackWidth = trackWidth
        self.trackHeight = trackHeight
    }

    public var body: some View {
        ZStack {
            NotesModel(fileURL: $fileURL, viewModel: viewModel, trackNumber: trackNumber, trackHeight: trackHeight)
        }
        .frame(width: trackWidth, height: trackHeight, alignment: .center)
    }
}
