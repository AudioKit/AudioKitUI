// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

public struct PianoRollNote: Equatable, Identifiable {
    public init(start: Int, length: Int, pitch: Int) {
        self.start = start
        self.length = length
        self.pitch = pitch
    }

    public var id = UUID()

    /// The start step.
    var start: Int

    /// How many steps long?
    var length: Int

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

struct PianoRollNoteView: View {
    @Binding var note: PianoRollNote
    var gridSize: CGSize
    @State var offset = CGSize.zero
    @State var hovering = false
    @State var lengthOffset: CGFloat = 0

    func snap() -> PianoRollNote {
        var n = note
        n.start += Int(offset.width / CGFloat(gridSize.width) + sign(offset.width) * 0.5)
        n.pitch += Int(offset.height / CGFloat(gridSize.height) + sign(offset.height) * 0.5)
        n.length += Int(lengthOffset / gridSize.width + sign(lengthOffset) * 0.5 )
        return n
    }

    func noteOffset(note: PianoRollNote) -> CGSize {
        CGSize(width: gridSize.width * CGFloat(note.start),
               height: gridSize.height * CGFloat(note.pitch))
    }

    var body: some View {
        if offset != CGSize.zero {
            Rectangle()
                .foregroundColor(.black.opacity(0.2))
                .frame(width: gridSize.width * CGFloat(note.length),
                       height: gridSize.height)
                .offset(noteOffset(note: snap()))
                .zIndex(-1)
        }
        ZStack(alignment: .trailing) {
            Rectangle()
                .foregroundColor(.cyan.opacity( (hovering || offset != .zero || lengthOffset != 0) ? 1.0 : 0.8))
            Rectangle()
                .foregroundColor(.black)
                .padding(4)
                .frame(width: 10)
        }
            .onHover { over in hovering = over }
            .padding(1) // so we can see consecutive notes
            .frame(width: gridSize.width * CGFloat(note.length) + lengthOffset,
                   height: gridSize.height)
            .offset(x: gridSize.width * CGFloat(note.start) + offset.width,
                    y: gridSize.height * CGFloat(note.pitch) + offset.height)
            .gesture(DragGesture()
                .onChanged{ value in
                    offset = value.translation
                }
                .onEnded{ value in
                    withAnimation(.easeOut) {
                        note = snap()
                        offset = CGSize.zero
                    }
                })
        HStack() {
            Spacer()
            Rectangle()
                .foregroundColor(.white.opacity(0.001))
                .frame(width: gridSize.width * 0.2, height: gridSize.height)
                .gesture(DragGesture()
                    .onChanged{ value in
                        lengthOffset = value.translation.width
                    }
                    .onEnded{ value in
                        withAnimation(.easeOut) {
                            note = snap()
                            lengthOffset = 0
                        }
                    })
        }
        .frame(width: gridSize.width * CGFloat(note.length),
               height: gridSize.height)
        .offset(x: gridSize.width * CGFloat(note.start) + offset.width,
                y: gridSize.height * CGFloat(note.pitch) + offset.height)

    }
}

struct PianoRollTileView: View {

    @Binding var model: PianoRollModel
    var gridSize: CGSize
    var step: Int
    var pitch: Int

    let gridColor = Color(red: 15.0/255.0, green: 17.0/255.0, blue: 16.0/255.0)

    var body: some View {
        Rectangle()
            .foregroundColor(Color(white: 0, opacity: 0.001))
            .border(gridColor, width: 0.5)
            .frame(width: gridSize.width,
                   height: gridSize.height)
            .offset(x: gridSize.width * CGFloat(step),
                    y: gridSize.height * CGFloat(pitch))
            .onTapGesture {
                model.notes.append(PianoRollNote(start: step, length: 1, pitch: pitch))
            }
    }
}

public struct PianoRoll: View {

    @Binding var model: PianoRollModel

    public init(model: Binding<PianoRollModel>) {
        _model = model
    }

    public var body: some View {
        ZStack {
            GeometryReader { proxy in
                let gridSize = CGSize(width: proxy.size.width / CGFloat(model.length),
                                      height: proxy.size.height / CGFloat(model.height))
                ForEach(0..<model.length) { step in
                    ForEach(0..<model.height) { pitch in
                        PianoRollTileView(model: $model,
                                          gridSize: gridSize,
                                          step: step,
                                          pitch: pitch)
                    }
                }
                ForEach(model.notes) { note in
                    PianoRollNoteView(
                        note: $model.notes[model.notes.firstIndex(of: note)!],
                        gridSize: gridSize)
                    .onTapGesture {
                        model.notes.removeAll(where: { $0 == note })
                    }
                }
            }
        }
    }
}

public struct PianoRollTestView: View {

    public init() { }

    @State var model = PianoRollModel(notes: [
        PianoRollNote(start: 1, length: 2, pitch: 3),
        PianoRollNote(start: 5, length: 1, pitch: 4)
    ], length: 16, height: 16)

    public var body: some View {
        PianoRoll(model: $model).padding()
    }
}

struct PianoRoll_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollTestView().frame(width: 1024, height: 768)
    }
}
