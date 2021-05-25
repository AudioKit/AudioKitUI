// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

public class WavetableModel: ObservableObject {
    @Published public var floats: [Float] = Table(.sine).content
    var node: DynamicWaveformNode?
    
    public init() {}
    
    public func updateNode(_ node: DynamicWaveformNode) {
        if node !== self.node {
            self.node = node
            self.node!.setWaveformUpdateHandler(setFloats)
            floats = node.getWaveformValues()
        }
    }
    
    func setFloats(floats: [Float]) {
        self.floats = floats.downSample(to: 128)
    }
}

public struct WavetableView: View {
    var node: DynamicWaveformNode
    @StateObject var wavetableModel = WavetableModel()
    private var strokeColor: Color
    private var strokeLineWidth: CGFloat
    private var fillColor: Color
    private var backgroundColor: Color
    
    public init(_ node: DynamicWaveformNode, strokeColor: Color = Color.white, strokeLineWidth: CGFloat = 1.0, fillColor: Color = Color.green.opacity(0.8), backgroundColor: Color = Color.black) {
        self.node = node
        self.strokeColor = strokeColor
        self.strokeLineWidth = strokeLineWidth
        self.fillColor = fillColor
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        return GeometryReader { geometry in
            createWave(width: geometry.size.width, height: geometry.size.height)
        }
        .drawingGroup()
        .onAppear {
            wavetableModel.updateNode(node)
        }
    }
    
    func createWave(width: CGFloat, height: CGFloat) -> some View {
        let xPaddedLowerBound = width*0.01
        let xPaddedUpperBound = width*0.99
        let yPaddedLowerBound = height*0.01
        let yPaddedUpperBound = height*0.99
        
        var points: [CGPoint] = []
        points.append(CGPoint(x: xPaddedLowerBound, y: 0.5*height))
        
        for i in 0 ..< wavetableModel.floats.count {
            let x = i.mapped(from: 0...wavetableModel.floats.count, to: xPaddedLowerBound...xPaddedUpperBound)
            let y = CGFloat(wavetableModel.floats[i]).mapped(from: -1...1, to: yPaddedLowerBound...yPaddedUpperBound)
            points.append(CGPoint(x: x, y: height - y))
        }
        points.append(CGPoint(x: xPaddedUpperBound, y: height*0.5))
        points.append(CGPoint(x: xPaddedLowerBound, y: height*0.5))
        
        return ZStack {
            backgroundColor
            Path { path in
                path.addLines(points)
            }
            .fill(fillColor)
            
            Path { path in
                path.addLines(points)
            }
            .stroke(strokeColor, lineWidth: strokeLineWidth)
        }
    }
}

//struct WavetableView_Previews: PreviewProvider {
//    static var previews: some View {
//        WavetableView(DynamicOscillator())
//    }
//}
