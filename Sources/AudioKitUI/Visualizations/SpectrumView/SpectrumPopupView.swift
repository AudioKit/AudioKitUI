// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

struct SpectrumPopupView_Previews: PreviewProvider {
    static var previews: some View {
        SpectrumPopupView(frequency: .constant(100.1), amplitude: .constant(-100.1))
    }
}

struct SpectrumPopupView: View {
    @Binding var frequency: CGFloat
    @Binding var amplitude: CGFloat
    @State var colorForeground = Color.yellow

    var body: some View {
        var ampString = ""
        var freqString = ""
        var noteString = ""

        var freqDisplayed = frequency

        var freqUnits = "  Hz"
        if frequency > 999 {
            freqDisplayed = frequency / 1000.0
            freqUnits = "kHz"
        }

        freqString = getThreeCharacters(freqDisplayed)
        ampString = getThreeCharacters(amplitude, isNegative: true)
        noteString = calculateNote(frequency)
        if noteString.count < 3 {
            noteString = "  " + calculateNote(frequency)
        }

        return VStack(spacing: 0.0) {
            Text(freqString + " " + freqUnits)
            Text("          " + noteString)
            Text(ampString + "  db")
        }
        .font(.headline)
        .foregroundColor(colorForeground)
        .padding(5)
        .background(Color.black)
        .cornerRadius(10)
    }
}

func getThreeCharacters(_ value: CGFloat, isNegative: Bool = false) -> String {
    if !isNegative {
        if value < 10.0 {
            return String(format: "%.2f", value)
        } else if value < 100.0 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    } else {
        if value < -100.0 {
            return String(format: "%.0f", value)
        } else if value < -10.0 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

func calculateNote(_ pitch: CGFloat) -> String {
    let noteFrequencies: [CGFloat] = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps: [String] = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    var frequency: CGFloat = pitch
    while frequency > CGFloat(noteFrequencies[noteFrequencies.count - 1]) {
        frequency /= 2.0
    }
    while frequency < CGFloat(noteFrequencies[0]) {
        frequency *= 2.0
    }

    var minDistance: CGFloat = 10_000.0
    var index = 0

    for possibleIndex in 0 ..< noteFrequencies.count {
        let distance = CGFloat(fabsf(Float(noteFrequencies[possibleIndex]) - Float(frequency)))
        if distance < minDistance {
            index = possibleIndex
            minDistance = distance
        }
    }
    let octave = Int(log2f(Float(pitch / frequency)))
    return "\(noteNamesWithSharps[index])\(octave)"
}
