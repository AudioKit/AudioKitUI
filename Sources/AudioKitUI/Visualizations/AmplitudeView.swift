// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

class AmplitudeModel: ObservableObject {
    @Published var amplitude: Double = 0.0
    var nodeTap: AmplitudeTap!
    var node: Node?
    var stereoMode: StereoMode = .center
    var analysisMode: AnalysisMode = .peak
    @Environment(\.isPreview) var isPreview
    
    init() {
        if isPreview {
            mockAmplitudeChange()
        }
    }
    
    func updateNode(_ node: Node) {
        if node !== self.node {
            self.node = node
            nodeTap = AmplitudeTap(
              node,
              stereoMode: stereoMode,
              analysisMode: analysisMode,
              callbackQueue: .main
            ) { amp in
                self.pushData(amp)
            }
            nodeTap.start()
        }
    }
    
    func pushData(_ amp: Float) {
        amplitude = Double(amp)
    }
    
    func mockAmplitudeChange() {
        amplitude = Double.random(in: 0...1.0)
        let waitTime: TimeInterval = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
            self.mockAmplitudeChange()
        }
    }
}

public struct AmplitudeView: View {
    @StateObject var amplitudeModel = AmplitudeModel()
    let node: Node
    let stereoMode: StereoMode
    let analysisMode: AnalysisMode
    let numberOfSegments: Int
    let fillType: FillType
    let backgroundColor: Color

    public init(
      _ node: Node,
      stereoMode: StereoMode = .center,
      analysisMode: AnalysisMode = .peak,
      backgroundColor: Color = .black,
      numberOfSegments: Int = 20
    ) {
        self.node = node
        self.stereoMode = stereoMode
        self.analysisMode = analysisMode
        self.backgroundColor = backgroundColor
        self.fillType = .gradient(gradient: Gradient(colors: [.red, .yellow, .green]))
        self.numberOfSegments = numberOfSegments
    }
    
    public init(
      _ node: Node,
      color: Color,
      stereoMode: StereoMode = .center,
      analysisMode: AnalysisMode = .peak,
      backgroundColor: Color = .black,
      numberOfSegments: Int = 20
    ) {
        self.node = node
        self.stereoMode = stereoMode
        self.analysisMode = analysisMode
        self.backgroundColor = backgroundColor
        self.fillType = .solid(color: color)
        self.numberOfSegments = numberOfSegments
    }
    
    public init(
      _ node: Node,
      colors: Gradient,
      stereoMode: StereoMode = .center,
      analysisMode: AnalysisMode = .peak,
      backgroundColor: Color = .black,
      numberOfSegments: Int = 20
    ) {
        self.node = node
        self.stereoMode = stereoMode
        self.analysisMode = analysisMode
        self.backgroundColor = backgroundColor
        self.fillType = .gradient(gradient: colors)
        self.numberOfSegments = numberOfSegments
    }
    
    public var body: some View {
        let isClipping = amplitudeModel.amplitude >= 1.0 ? true : false
        let numberOfBlackSegments = numberOfSegments - 1
        
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // colored rectangle in the back
                if !isClipping {
                    Rectangle()
                        .flexibleFill(type: fillType)
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
                    // simply cover a certain amount of the colored rectangle with the background color from the top
                    Rectangle()
                        .fill(self.backgroundColor)
                        .mask(Rectangle().padding(.bottom, geometry.size.height * CGFloat(amplitudeModel.amplitude)))
                        .animation(.linear(duration: 0.05), value: amplitudeModel.amplitude)
                }
            }
            .onAppear {
                amplitudeModel.stereoMode = stereoMode
                amplitudeModel.analysisMode = analysisMode
                amplitudeModel.updateNode(node)
            }
        }
        .drawingGroup()
    }
    
    func addSegments(width _: CGFloat, height: CGFloat, numberOfBlackSegments: Int) -> some View {
        let splitHeight = height / CGFloat(numberOfBlackSegments + 1)
        let solidHeight = splitHeight * (2.0 / 3.0)
        let spaceHeight = splitHeight * (1.0 / 3.0) + splitHeight * (1.0 / 3.0) / CGFloat(numberOfBlackSegments)
        
        return VStack(spacing: 0.0) {
            ForEach((1 ... numberOfBlackSegments + 1).reversed(), id: \.self) { index in
                
                if index != numberOfBlackSegments + 1 {
                    Rectangle()
                        .fill(self.backgroundColor)
                        .frame(height: spaceHeight)
                }
                addOpacityRectangle(height: solidHeight, index: index, n: numberOfBlackSegments)
                    .animation(.linear(duration: 0.05), value: amplitudeModel.amplitude)
            }
        }
    }
    
    // these sit in front of the color rectangles and are either on or off (opacity used for animating)
    func addOpacityRectangle(height: CGFloat, index: Int, n: Int) -> some View {
        let opacity = amplitudeModel.amplitude > Double(index - 1) / Double(n + 1) ? 0.0 : 1.0
        
        return Rectangle()
            .fill(self.backgroundColor)
            .frame(height: height)
            .opacity(opacity)
            .animation(.linear(duration: 0.05), value: amplitudeModel.amplitude)
    }
}

struct AmplitudeView_Previews: PreviewProvider {
    static var previews: some View {
        AmplitudeView(Mixer(), numberOfSegments: 1)
            .previewLayout(.fixed(width: 40, height: 500))
        
        AmplitudeView(Mixer(), numberOfSegments: 20)
            .previewLayout(.fixed(width: 40, height: 500))
        
        AmplitudeView(Mixer(), color: .blue, numberOfSegments: 20)
            .previewLayout(.fixed(width: 40, height: 500))
    }
}
