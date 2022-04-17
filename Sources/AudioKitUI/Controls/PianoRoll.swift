// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

struct PianoRollNote {

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

struct PianoRoll: View {

    @Binding var model: PianoRollModel

    var body: some View {
        Canvas { cx, size in
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
    }
}

struct PianoRollTestView: View {

    @State var model = PianoRollModel(notes: [], length: 16, height: 16)

    var body: some View {
        PianoRoll(model: $model).padding()
    }
}

struct PianoRoll_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollTestView().frame(width: 1024, height: 768)
    }
}
