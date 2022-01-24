// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

public struct MusicalDurationStepper: View {
    @Binding var musicalDuration: MusicalDuration
    var time: Float

    public init(musicalDuration: Binding<MusicalDuration>, time: Float) {
        _musicalDuration = musicalDuration
        self.time = time
    }

    public var body: some View {
        GeometryReader { geo in
            let font = Font.system(size: geo.size.height * 0.45, weight: .light)
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.17))
                HStack {
                    Text("◀").font(font).onTapGesture {
                        musicalDuration = musicalDuration.previous
                    }
                    Spacer()
                    Text("▶").font(font).onTapGesture {
                        musicalDuration = musicalDuration.next
                    }
                }
                .padding(SwiftUI.EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                Text("\(musicalDuration.description) (\(String(format: "%.3f", time))s)").font(font)
            }
        }

    }
}
