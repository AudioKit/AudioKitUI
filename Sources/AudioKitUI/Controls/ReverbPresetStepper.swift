// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AVFoundation
import SwiftUI

public struct ReverbPresetStepper: View {
    @Binding var preset: AVAudioUnitReverbPreset

    public init(preset: Binding<AVAudioUnitReverbPreset>) {
        _preset = preset
    }
    
    public var body: some View {
        GeometryReader { geo in
            let font = Font.system(size: geo.size.height * 0.45, weight: .light)
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.17))
                HStack {
                    Text("◀").font(font).onTapGesture {
                        preset = preset.previous
                    }
                    Spacer()
                    Text("▶").font(font).onTapGesture {
                        preset = preset.next
                    }
                }
                .padding(SwiftUI.EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                Text(preset.name.uppercased()).font(font)
            }
        }

    }
}
