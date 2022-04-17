// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

public struct PianoRollNote: Equatable, Hashable {
    public init(start: Int, length: Int, pitch: Int) {
        self.start = start
        self.length = length
        self.pitch = pitch
    }

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

struct PianoRollNoteView: View {
    @Binding var note: PianoRollNote
    var gridSize: CGSize
    @State var offset = CGSize.zero
    @State var hovering = false

    var body: some View {
        if offset != CGSize.zero {
            Rectangle()
                .foregroundColor(.black)
                .frame(width: gridSize.width * CGFloat(note.length),
                       height: gridSize.height)
                .offset(x: gridSize.width * CGFloat(note.start + Int(offset.width / CGFloat(gridSize.width))),
                        y: gridSize.height * CGFloat(note.pitch + Int(offset.height / CGFloat(gridSize.height))))
                .zIndex(-1)
        }
        Rectangle()
            .cornerRadius(5.0)
            .foregroundColor(.cyan.opacity(hovering ? 1.0 : 0.8))
            .onHover { over in hovering = over }
            .frame(width: gridSize.width * CGFloat(note.length),
                   height: gridSize.height)
            .offset(x: gridSize.width * CGFloat(note.start) + offset.width,
                    y: gridSize.height * CGFloat(note.pitch) + offset.height)
            .gesture(DragGesture()
                .onChanged{ value in
                    offset = value.translation
                }
                .onEnded{ value in
                    note.start += Int(value.translation.width / CGFloat(gridSize.width))
                    note.pitch += Int(value.translation.height / CGFloat(gridSize.height))
                    offset = CGSize.zero
                })
    }
}

public struct PianoRoll: View {

    @Binding var model: PianoRollModel

    public init(model: Binding<PianoRollModel>) {
        _model = model
    }

    func drawGrid(cx: GraphicsContext, size: CGSize) {
        var x: CGFloat = 0
        for _ in 0 ... model.length {

            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))

            cx.stroke(path, with: .color(.gray), lineWidth: 1)

            x += size.width / CGFloat(model.length)
        }

        var y: CGFloat = 0
        for _ in 0 ... model.height {

            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))

            cx.stroke(path, with: .color(.gray), lineWidth: 1)

            y += size.height / CGFloat(model.height)
        }
    }

    public var body: some View {
        ZStack {
            Canvas { cx, size in
                drawGrid(cx: cx, size: size)
            }
            GeometryReader { proxy in
                ForEach(model.notes, id: \.self) { note in
                    PianoRollNoteView(
                        note: $model.notes[model.notes.firstIndex(of: note)!],
                        gridSize: CGSize(width: proxy.size.width / CGFloat(model.length),
                                         height: proxy.size.height / CGFloat(model.height)))
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
