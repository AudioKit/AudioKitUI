// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

/// Touch-oriented piano roll.
///
/// Note: Requires macOS 12 / iOS 15 due to SwiftUI bug (crashes in SwiftUI when deleting notes).
public struct PianoRoll: View {

    @Binding var model: PianoRollModel
    var gridSize = CGSize(width: 80, height: 40)
    var noteColor = Color.accentColor

    public init(model: Binding<PianoRollModel>, noteColor: Color = .accentColor) {
        _model = model
        self.noteColor = noteColor
    }

    let gridColor = Color(red: 15.0/255.0, green: 17.0/255.0, blue: 16.0/255.0)

    public var body: some View {
        ZStack(alignment: .topLeading) {
            let dragGesture = DragGesture(minimumDistance: 0).onEnded({ value in
                let location = value.location
                let step = Double(Int(location.x / gridSize.width))
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
                    color: noteColor,
                    sequenceLength: model.length,
                    sequenceHeight: model.height,
                    isContinuous: true)
                .onTapGesture {
                    model.notes.removeAll(where: { $0 == note })
                }
            }
        }.frame(width: CGFloat(model.length) * gridSize.width,
                height: CGFloat(model.height) * gridSize.height)
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
            PianoRoll(model: $model, noteColor: .cyan)
        }.background(Color(white: 0.1))
    }
}

struct PianoRoll_Previews: PreviewProvider {
    static var previews: some View {
        PianoRollTestView()
    }
}
