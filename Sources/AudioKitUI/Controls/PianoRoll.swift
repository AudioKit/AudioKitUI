// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

struct PianoRollNote: Equatable, Hashable {

    /// The start step.
    var start: Int

    /// How many steps long?
    var length: Int

    /// Abstract pitch, not MIDI notes.
    var pitch: Int

}

struct PianoRollModel {

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

    var body: some View {
        Rectangle()
            .cornerRadius(5.0)
            .foregroundColor(.cyan)
            .frame(width: gridSize.width * CGFloat(note.length),
                   height: gridSize.height)
            .offset(x: gridSize.width * CGFloat(note.start),
                    y: gridSize.height * CGFloat(note.pitch))
    }
}

struct PianoRoll: View {

    @Binding var model: PianoRollModel

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

    var body: some View {
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

struct PianoRollTestView: View {

    @State var model = PianoRollModel(notes: [
        PianoRollNote(start: 1, length: 2, pitch: 3),
        PianoRollNote(start: 5, length: 1, pitch: 4)
    ], length: 16, height: 16)

    var body: some View {
        PianoRoll(model: $model).padding()
    }
}

struct PianoRoll_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollTestView().frame(width: 1024, height: 768)
    }
}
