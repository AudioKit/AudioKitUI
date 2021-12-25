
// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/
import SwiftUI
import AudioKit

// This class will need a re-work -- will push a commit to AudioKit/AudioKit soon
extension MIDIFileTrackNoteMap {
    public func getNoteList() -> [MIDINoteDuration] {
        var finalNoteList = [MIDINoteDuration]()
        var eventPosition = 0.0
        var noteNumber = 0
        var noteOn = 0
        var noteOff = 0
        var velocityEvent: Int?
        var notesInProgress: [Int: (Double, Double)] = [:]
        for event in midiTrack.channelEvents {
            let data = event.data
            let eventTypeNumber = data[0]
            let eventType = event.status?.type?.description ?? "No Event"

            //Usually the third element of a note event is the velocity
            if data.count > 2 {
                velocityEvent = Int(data[2])
            }

            if noteOn == 0 {
                if eventType == "Note On" {
                    noteOn = Int(eventTypeNumber)
                }
            }
            if noteOff == 0 {
                if eventType == "Note Off" {
                    noteOff = Int(eventTypeNumber)
                }
            }

            if eventTypeNumber == noteOn {
                //A note played with a velocity of zero is the equivalent
                //of a noteOff command
                if velocityEvent == 0 {
                    eventPosition = (event.positionInBeats ?? 1.0) / Double(self.midiFile.ticksPerBeat ?? 1)
                    noteNumber = Int(data[1])
                    if let prevPosValue = notesInProgress[noteNumber]?.0 {
                        notesInProgress[noteNumber] = (prevPosValue, eventPosition)
                        var noteTracker: MIDINoteDuration = MIDINoteDuration(
                            noteOnPosition: 0.0,
                            noteOffPosition: 0.0, noteNumber: 0)
                        if let note = notesInProgress[noteNumber] {
                            noteTracker = MIDINoteDuration(
                                noteOnPosition:
                                    note.0,
                                noteOffPosition:
                                    note.1,
                                noteNumber: noteNumber)
                        }
                        notesInProgress.removeValue(forKey: noteNumber)
                        finalNoteList.append(noteTracker)
                    }
                } else {
                    eventPosition = (event.positionInBeats ?? 1.0) / Double(self.midiFile.ticksPerBeat ?? 1)
                    noteNumber = Int(data[1])
                    notesInProgress[noteNumber] = (eventPosition, 0.0)
                }
            }

            if eventTypeNumber == noteOff {
                eventPosition = (event.positionInBeats ?? 1.0) / Double(self.midiFile.ticksPerBeat ?? 1)
                noteNumber = Int(data[1])
                if let prevPosValue = notesInProgress[noteNumber]?.0 {
                    notesInProgress[noteNumber] = (prevPosValue, eventPosition)
                    var noteTracker: MIDINoteDuration = MIDINoteDuration(
                        noteOnPosition: 0.0,
                        noteOffPosition: 0.0,
                        noteNumber: 0)
                    if let note = notesInProgress[noteNumber] {
                        noteTracker = MIDINoteDuration(
                            noteOnPosition:
                                note.0,
                            noteOffPosition:
                                note.1,
                            noteNumber: noteNumber)
                    }
                    notesInProgress.removeValue(forKey: noteNumber)
                    finalNoteList.append(noteTracker)
                }
            }

            eventPosition = 0.0
            noteNumber = 0
            velocityEvent = nil
        }
        return finalNoteList
    }
    public func getLowNote(noteList: [MIDINoteDuration]) -> Int {
        if noteList.count >= 2 {
            return (noteList.min(by: { $0.noteNumber < $1.noteNumber })?.noteNumber) ?? 0
        } else {
            return 0
        }
    }
    public func getHiNote(noteList: [MIDINoteDuration]) -> Int {
        if noteList.count >= 2 {
            return (noteList.max(by: { $0.noteNumber < $1.noteNumber })?.noteNumber) ?? 0
        } else {
            return 0
        }
    }
}
struct NoteGroup: UIViewRepresentable {
    @Binding var isPlaying: Bool
    @Binding var sequencerTempo: Double
    let noteMap: MIDIFileTrackNoteMap
    let length: CGFloat
    let trackHeight: CGFloat
    let noteZoom: CGFloat

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
        let noteList = noteMap.getNoteList()
        let low = noteMap.getLowNote(noteList: noteList)
        let high = noteMap.getHiNote(noteList: noteList)
        let range = (high - low) + 1
        let noteh = trackHeight / CGFloat(range)
        let maxh = trackHeight - noteh
        for note in noteList {
            let noteNumber = note.noteNumber - low
            let noteStart = Double(note.noteStartTime)
            let noteDuration = Double(note.noteDuration)
            let noteLength = Double(noteDuration * noteZoom)
            let notePosition = Double(noteStart * noteZoom)
            let noteLevel = (maxh - (Double(noteNumber) * noteh))
            let singleNoteRect = CGRect(x: notePosition, y: noteLevel, width: noteLength, height: noteh)
            let singleNoteView = UIView(frame: singleNoteRect)
            singleNoteView.backgroundColor = UIColor.red
            singleNoteView.layer.cornerRadius = noteh * 0.5
            uiView.addSubview(singleNoteView)
        }
    }
    func setupTimer(_ uiView: UIView) {
        let base = (20 + (8.0 / 10.0) + (1.0 / 30.0))
        let inverse = 1.0 / base
        let multiplier = inverse * 60 * (10_000 / noteZoom)
        let scrollTimer = Timer.scheduledTimer(
            withTimeInterval: multiplier * (1/sequencerTempo), repeats: true) { timer in
            scrollNotes(uiView)
            if !isPlaying {
                timer.invalidate()
            }
        }
        RunLoop.main.add(scrollTimer, forMode: .common)
    }
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
