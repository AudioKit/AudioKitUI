// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

public struct PianoRollNote: Equatable, Identifiable {
    public init(start: Int, length: Double, pitch: Int) {
        self.start = start
        self.length = length
        self.pitch = pitch
    }

    public var id = UUID()

    /// The start step.
    var start: Int

    /// How many steps long?
    var length: Double

    /// Abstract pitch, not MIDI notes.
    var pitch: Int

}

public struct PianoRollModel: Equatable {
    public init(notes: [PianoRollNote], length: Int, height: Int) {
        self.notes = notes
        self.length = length
        self.height = height
    }

    /// The sequence being edited.
    var notes:[PianoRollNote]

    /// How many steps in the piano roll.
    var length: Int

    /// Maximum pitch.
    var height: Int

}

func sign(_ x: CGFloat) -> CGFloat {
    x > 0 ? 1 : -1
}

/// Touch-oriented piano roll.
///
/// Note: Requires macOS 12 / iOS 15 due to SwiftUI bug (crashes in SwiftUI when deleting notes).
struct PianoRollNoteView: View {
    @Binding var note: PianoRollNote
    var gridSize: CGSize
    var color: Color

    // Note: using @GestureState instead of @State here fixes a bug where the
    //       offset could get stuck when inside a ScrollView.
    @GestureState var offset = CGSize.zero
    @GestureState var startNote: PianoRollNote?

    @State var hovering = false

    // Note: using @GestureState instead of @State here fixes a bug where the
    //       lengthOffset could get stuck when inside a ScrollView.
    @GestureState var lengthOffset: CGFloat = 0

    var sequenceLength: Int
    var sequenceHeight: Int

    func snap(note: PianoRollNote, offset: CGSize, lengthOffset: CGFloat = 0.0) -> PianoRollNote {
        var n = note
        n.start += Int(offset.width / CGFloat(gridSize.width) + sign(offset.width) * 0.5)
        n.start = max(0, n.start)
        n.start = min(sequenceLength - 1, n.start)
        n.pitch -= Int(offset.height / CGFloat(gridSize.height) + sign(offset.height) * 0.5)
        n.pitch = max(0, n.pitch)
        n.pitch = min(sequenceHeight - 1, n.pitch)
        n.length += Double(Int(lengthOffset / gridSize.width + sign(lengthOffset) * 0.5 ))
        // n.length += lengthOffset / gridSize.width
        n.length = max(1, n.length)
        n.length = min(Double(sequenceLength), n.length)
        n.length = min(Double(sequenceLength - n.start), n.length)
        return n
    }

    func noteOffset(note: PianoRollNote, dragOffset: CGSize = .zero) -> CGSize {
        CGSize(width: gridSize.width * CGFloat(note.start) + dragOffset.width,
               height: gridSize.height * CGFloat(sequenceHeight - note.pitch) + dragOffset.height)
    }

    var body: some View {

        // While dragging, show where the note will go.
        if offset != CGSize.zero {
            Rectangle()
                .foregroundColor(.black.opacity(0.2))
                .frame(width: gridSize.width * CGFloat(note.length),
                       height: gridSize.height)
                .offset(noteOffset(note: note))
                .zIndex(-1)
        }

        // Set the minimum distance so a note drag will override
        // the drag of a containing ScrollView.
        let minimumDistance: CGFloat = 2

        let noteDragGesture = DragGesture(minimumDistance: minimumDistance)
            .updating($offset) { value, state, _ in
                state = value.translation
            }
            .updating($startNote){ value, state, _ in
                if state == nil {
                    state = note
                }
            }
            .onChanged{ value in
                if let startNote = startNote {
                    note = snap(note: startNote, offset: value.translation)
                }
            }

        let lengthDragGesture = DragGesture(minimumDistance: minimumDistance)
            .updating($lengthOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded{ value in
                note = snap(note: note, offset: CGSize.zero, lengthOffset: value.translation.width)
            }

        // Main note body.
        ZStack(alignment: .trailing) {
            Rectangle()
                .foregroundColor(color.opacity( (hovering || offset != .zero || lengthOffset != 0) ? 1.0 : 0.8))
            Rectangle()
                .foregroundColor(.black)
                .padding(4)
                .frame(width: 10)
        }
            .onHover { over in hovering = over }
            .padding(1) // so we can see consecutive notes
            .frame(width: max(gridSize.width, gridSize.width * CGFloat(note.length) + lengthOffset),
                   height: gridSize.height)
            .offset( noteOffset(note: startNote ?? note, dragOffset: offset))
            .gesture(noteDragGesture)

        // Length tab at the end of the note.
        HStack() {
            Spacer()
            Rectangle()
                .foregroundColor(.white.opacity(0.001))
                .frame(width: gridSize.width * 0.5, height: gridSize.height)
                .gesture(lengthDragGesture)
        }
        .frame(width: gridSize.width * CGFloat(note.length),
               height: gridSize.height)
        .offset(noteOffset(note: note, dragOffset: offset))

    }
}

struct PianoRollGrid: Shape {

    var gridSize: CGSize
    var length: Int
    var height: Int

    func path(in rect: CGRect) -> Path {

        let size = rect.size
        var path = Path()
        for i in 0 ... length {
            let x = CGFloat(i) * gridSize.width
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for i in 0 ... height {
            let y = CGFloat(i) * gridSize.height
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        return path
    }
}

public struct PianoRoll: View {

    @Binding var model: PianoRollModel
    var gridSize = CGSize(width: 80, height: 40)
    var _noteColor = Color.accentColor

    public init(model: Binding<PianoRollModel>) {
        _model = model
    }

    init(model: Binding<PianoRollModel>, noteColor: Color) {
        _model = model
        _noteColor = noteColor
    }

    let gridColor = Color(red: 15.0/255.0, green: 17.0/255.0, blue: 16.0/255.0)

    public var body: some View {
        ZStack(alignment: .topLeading) {
            let dragGesture = DragGesture(minimumDistance: 0).onEnded({ value in
                let location = value.location
                let step = Int(location.x / gridSize.width)
                let pitch = model.height - Int(location.y / gridSize.height)
                model.notes.append(PianoRollNote(start: step, length: 1, pitch: pitch))
            })
            PianoRollGrid(gridSize: gridSize, length: model.length, height: model.height)
                .stroke(lineWidth: 0.5)
                .foregroundColor(gridColor)
                .contentShape(Rectangle())
                .gesture(TapGesture().sequenced(before: dragGesture))
            ForEach(model.notes) { note in
                PianoRollNoteView(
                    note: $model.notes[model.notes.firstIndex(of: note)!],
                    gridSize: gridSize,
                    color: _noteColor,
                    sequenceLength: model.length,
                    sequenceHeight: model.height)
                .onTapGesture {
                    model.notes.removeAll(where: { $0 == note })
                }
            }
        }.frame(width: CGFloat(model.length) * gridSize.width,
                height: CGFloat(model.height) * gridSize.height)
    }

    public func noteColor(_ color: Color) -> Self {
        PianoRoll(model: _model, noteColor: color)
    }
}

public struct PianoRollTestView: View {

    public init() { }

    @State var model = PianoRollModel(notes: [
        PianoRollNote(start: 1, length: 2, pitch: 3),
        PianoRollNote(start: 5, length: 1, pitch: 4)
    ], length: 128, height: 128)

    public var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            PianoRoll(model: $model).noteColor(.cyan)
        }.background(Color(white: 0.1))
    }
}

struct PianoRoll_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollTestView()
    }
}
