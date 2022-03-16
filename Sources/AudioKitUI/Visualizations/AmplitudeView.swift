// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

class AmplitudeModel: ObservableObject {
    @Published var amplitude: Double = 0.0
    var nodeTap: AmplitudeTap!
    var node: Node?
    var stereoMode: StereoMode
    
    init(stereoMode: StereoMode = .center) {
        self.stereoMode = stereoMode
    }
    
    func updateNode(_ node: Node) {
        if node !== self.node {
            self.node = node
            nodeTap = AmplitudeTap(node, stereoMode: stereoMode, analysisMode: .peak) { amp in
                DispatchQueue.main.async {
                    self.pushData(amp)
                }
            }
            nodeTap.start()
        }
    }
    
    func pushData(_ amp: Float) {
        amplitude = Double(amp)
    }
}

public struct AmplitudeView: View {
    @StateObject var amplitudeModel = AmplitudeModel()
    var node: Node
    @State var stereoMode: StereoMode = .center
    @State var numberOfSegments: Int
    
    @State var fillType: FillType = .gradient(gradient: Gradient(colors: [.red, .yellow, .green]))
    
    init(_ node: Node, stereoMode: StereoMode = .center, numberOfSegments: Int = 20) {
        self.node = node
        self._stereoMode = State(initialValue: stereoMode)
        self._numberOfSegments = State(initialValue: numberOfSegments)
    }

    init(_ node: Node, color: Color, stereoMode: StereoMode = .center, numberOfSegments: Int = 20) {
        self.node = node
        self._stereoMode = State(initialValue: stereoMode)
        self._fillType = State(initialValue: .solid(color: color))
        self._numberOfSegments = State(initialValue: numberOfSegments)
    }

    init(_ node: Node, colors: Gradient, stereoMode: StereoMode = .center, numberOfSegments: Int = 20) {
        self.node = node
        self._stereoMode = State(initialValue: stereoMode)
        self._fillType = State(initialValue: .gradient(gradient: colors))
        self._numberOfSegments = State(initialValue: numberOfSegments)
    }
    
    public var body: some View {
        let isClipping = amplitudeModel.amplitude >= 1.0 ? true : false
        let numberOfBlackSegments = numberOfSegments - 1
        
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // colored rectangle in the back
                if !isClipping {
                    Rectangle()
                        .flexableFill(fillType: fillType)
                } else {
                    Rectangle()
                        .fill(Color.red)
                }

                if numberOfSegments > 1 {
                    // draw rectangles in front of the colored rectangle
                    // some are constant black to create the segments
                    // some are "on" or "off" - based on their opacity to create the colored regions
                    addSegments(width: geometry.size.width, height: geometry.size.height, numberOfBlackSegments: numberOfBlackSegments)
                } else {
                    // simply cover a certain amount of the colored rectangle with black from the top
                    Rectangle()
                        .fill(Color.black)
                        .mask(Rectangle().padding(.bottom, geometry.size.height * CGFloat(amplitudeModel.amplitude)))
                        .animation(.linear(duration: 0.05))
                }
            }
            .onAppear {
                amplitudeModel.stereoMode = stereoMode
                amplitudeModel.updateNode(node)
            }
        }
        .drawingGroup()
    }
    
    func addSegments(width: CGFloat, height: CGFloat, numberOfBlackSegments: Int) -> some View {
        let splitHeight = height / CGFloat(numberOfBlackSegments + 1)
        let solidHeight = splitHeight * (2.0 / 3.0)
        let spaceHeight = splitHeight * (1.0 / 3.0) + splitHeight * (1.0 / 3.0) / CGFloat(numberOfBlackSegments)
        
        return VStack(spacing: 0.0) {
            ForEach((1 ... numberOfBlackSegments + 1).reversed(), id: \.self) { index in
                
                if index != numberOfBlackSegments + 1 {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: spaceHeight)
                }
                addOpacityRectangle(height: solidHeight, index: index, n: numberOfBlackSegments)
            }
        }
    }
    
    // these sit in front of the color rectangles and are either on or off (opacity used for animating)
    func addOpacityRectangle(height: CGFloat, index: Int, n: Int) -> some View {
        let opacity = amplitudeModel.amplitude > Double(index - 1) / Double(n + 1) ? 0.0 : 1.0
        
        return Rectangle()
            .fill(Color.black)
            .frame(height: height)
            .opacity(opacity)
            .animation(.linear(duration: 0.05))
    }
}

struct AmplitudeView_Previews: PreviewProvider {
    static var previews: some View {
        AmplitudeView(Mixer())
            .previewLayout(.fixed(width: 40, height: 500))
    }
}
