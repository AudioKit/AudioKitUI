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
        var points: [CGPoint] = []
        points.append(CGPoint(x: Double(width)*0.01, y: Double(0.5*height)))
        for i in 0 ..< wavetableModel.floats.count {
            let x = map(n: Double(i), start1: 0, stop1: Double(wavetableModel.floats.count), start2: Double(width)*0.01, stop2: Double(width)*0.99)
            let y = map(n: Double(wavetableModel.floats[i]), start1: -1, stop1: 1, start2: Double(height)*0.99, stop2: Double(height)*0.01)
            points.append(CGPoint(x: x, y: y))
        }
        points.append(CGPoint(x: Double(width)*0.99, y: Double(height*0.5)))
        points.append(CGPoint(x: Double(width)*0.01, y: Double(height*0.5)))
        
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
