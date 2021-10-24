// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

class RawOutputModel: ObservableObject {
    @Environment(\.isPreview) var isPreview
    @Published var data: [CGFloat] = []
    var bufferSize: Int = 1024
    var nodeTap: RawDataTap!
    var node: Node?

    init() {
        if isPreview {
            for _ in 0...100 {
                data.append(CGFloat.random(in: -1.0...1.0))
            }
        }
    }

    func updateNode(_ node: Node, bufferSize: Int = 1024) {
        if node !== self.node {
            self.node = node
            self.bufferSize = bufferSize
            nodeTap = RawDataTap(node, bufferSize: UInt32(bufferSize)) { rawAudioData in
                DispatchQueue.main.async {
                    self.updateData(rawAudioData.map { CGFloat($0) })
                }
            }
            nodeTap.start()
        }
    }

    func updateData(_ data: [CGFloat]) {
        self.data = data
    }
}

public struct RawOutputView: View {
    @StateObject var rawOutputModel = RawOutputModel()
    @Binding var strokeColor: Color
    @Binding var isNormalized: Bool
    @Binding var scaleFactor: CGFloat
    var bufferSize: Int = 1024
    var node: Node?

    public init(_ node: Node? = nil,
                bufferSize: Int = 1024,
                strokeColor: Binding<Color> = .constant(Color.black),
                isNormalized: Binding<Bool> = .constant(false),
                scaleFactor: Binding<CGFloat> = .constant(1.0)) {
        self.node = node
        self.bufferSize = bufferSize
        self._strokeColor = strokeColor
        self._isNormalized = isNormalized
        self._scaleFactor = scaleFactor
    }

    public var body: some View {
        RawAudioPlot(data: rawOutputModel.data, isNormalized: isNormalized, scaleFactor: scaleFactor)
            .stroke(strokeColor)
            .onAppear {
                if let node = node {
                    rawOutputModel.updateNode(node)
                }
            }
    }
}

struct RawAudioPlot: Shape {
    var data: [CGFloat]
    var isNormalized: Bool
    var scaleFactor: CGFloat = 1.0

    func path(in rect: CGRect) -> Path {
        var coordinates: [CGPoint] = []

        var rangeValue: CGFloat = 1.0
        if isNormalized {
            if let max = data.max() {
                if let min = data.min() {
                    rangeValue = abs(min) > max ? abs(min) : max
                }
            }
        } else {
            rangeValue = rangeValue / scaleFactor
        }

        for index in 0 ..< data.count {
            let x = index.mapped(from: 0...data.count, to: rect.minX...rect.maxX)
            let y = data[index].mappedInverted(from: -rangeValue...rangeValue, to: rect.minY...rect.maxY)

            coordinates.append(CGPoint(x: x, y: y))
        }

        return Path { path in
            path.addLines(coordinates)
        }
    }
}

struct RawOutputView_Previews: PreviewProvider {
    static var previews: some View {
        RawOutputView()
    }
}
