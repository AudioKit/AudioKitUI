// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

/// A single note in the piano roll.
///
/// A note has half a grid column at the end for changing the length.
///
/// With each note as a separate view this might not be suitable for very large sequences, but
/// it makes it easier to implement.
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
    var isContinuous = false

    func snap(note: PianoRollNote, offset: CGSize, lengthOffset: CGFloat = 0.0) -> PianoRollNote {
        var n = note
        if isContinuous {
            n.start += offset.width / gridSize.width
        } else {
            n.start += round(offset.width / CGFloat(gridSize.width))
        }
        n.start = max(0, n.start)
        n.start = min(Double(sequenceLength - 1), n.start)
        n.pitch -= Int(round(offset.height / CGFloat(gridSize.height)))
        n.pitch = max(0, n.pitch)
        n.pitch = min(sequenceHeight - 1, n.pitch)
        if isContinuous {
            n.length += lengthOffset / gridSize.width
        } else {
            n.length += round(lengthOffset / gridSize.width)
        }
        n.length = max(1, n.length)
        n.length = min(Double(sequenceLength), n.length)
        n.length = min(Double(sequenceLength) - n.start, n.length)
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
