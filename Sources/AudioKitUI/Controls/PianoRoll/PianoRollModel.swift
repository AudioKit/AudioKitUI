// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

public struct PianoRollNote: Equatable, Identifiable {
    public init(start: Double, length: Double, pitch: Int) {
        self.start = start
        self.length = length
        self.pitch = pitch
    }

    public var id = UUID()

    /// The start step.
    var start: Double

    /// How many steps long?
    var length: Double

    /// Abstract pitch, not MIDI notes.
    var pitch: Int

}

/// Value oriented data model for `PianoRoll`
///
/// The data model is abstracted away from MIDI so that it's up to you
/// to determine what pitch means (e.g. how it is scale quantized).
public struct PianoRollModel: Equatable {
    public init(notes: [PianoRollNote], length: Int, height: Int) {
        self.notes = notes
        self.length = length
        self.height = height
    }

    /// The sequence being edited.
    var notes: [PianoRollNote]

    /// How many steps in the piano roll.
    var length: Int

    /// Maximum pitch.
    var height: Int

}
