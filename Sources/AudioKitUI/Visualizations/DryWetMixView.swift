import AudioKit
import AVFoundation
import SwiftUI

public struct DryWetMixView: View {
    var dry: Node
    var wet: Node
    var mix: Node

    public init(dry: Node, wet: Node, mix: Node) {
        self.dry = dry
        self.wet = wet
        self.mix = mix
    }

    var height: CGFloat = 100

    func plot(_ node: Node, label: String, color: Color) -> some View {
        VStack {
            HStack { Text(label); Spacer() }
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color(hue: 0, saturation: 0, brightness: 0.5, opacity: 0.2))
                    .frame(height: height)
                NodeOutputView(node, color: color).frame(height: height).clipped()
            }
        }
    }

    public var body: some View {
        VStack(spacing: 30) {
            plot(dry, label: "Input", color: .red)
            plot(wet, label: "Processed Signal", color: .blue)
            plot(mix, label: "Mixed Output", color: .purple)
        }
    }
}
