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
            cx.draw(Text("This is a test"), at: CGPoint(x: 100, y: 100))
        }
    }
}

struct PianoRollTestView: View {

    @State var model = PianoRollModel(notes: [], length: 16, height: 16)

    var body: some View {
        PianoRoll(model: $model)
    }
}

struct PianoRoll_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollTestView().frame(width: 1024, height: 768)
    }
}
