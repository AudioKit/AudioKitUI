// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

class WavetableModel: ObservableObject {
    @Published var floats: [Float] = Table(.sine).content
    var node: DynamicOscillator?
    
    func updateNode(_ node: DynamicOscillator) {
        if node !== self.node {
            self.node = node
            self.node!.wavetableUpdateHandler = setFloats
            floats = node.getWavetableValues()
        }
    }
    
    func setFloats(floats: [Float]) {
        self.floats = floats
    }
}

struct WavetableView: View {
    @StateObject var wavetableModel = WavetableModel()
    @State var strokeColor = Color.white
    @State var fillColor = Color.green.opacity(0.8)
    @State var backgroundColor = Color.black
    var node: DynamicOscillator
    
    var body: some View {
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
            let x = i.mapped(to: xPaddedLowerBound...xPaddedUpperBound, from: 0...wavetableModel.floats.count)
            let y = CGFloat(wavetableModel.floats[i]).mapped(to: yPaddedLowerBound...yPaddedUpperBound, from: -1...1)
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
            .stroke(strokeColor, lineWidth: 3)
        }
    }
}

struct WavetableView_Previews: PreviewProvider {
    static var previews: some View {
        WavetableView(node: DynamicOscillator())
    }
}
