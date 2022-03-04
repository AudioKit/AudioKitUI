// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

struct AudioWaveform: Shape {
    var rmsVals: [Float]

    func path(in rect: CGRect) -> Path {
        var points = [CGPoint]()

        // starting point
        points.append(CGPoint(x: 0, y: rect.height*0.5))

        // top of wave
        for i in 0..<rmsVals.count {
            let x = i.mapped(from: 0...rmsVals.count, to: 0...rect.width)
            let y = CGFloat(rmsVals[i]).mappedInverted(from: 0...1, to: 0...rect.height*0.5)
            points.append(CGPoint(x: x, y: y))
        }

        // bottom of wave
        for i in stride(from: rmsVals.count-1, to: 0, by: -1) {
            let x = i.mapped(from: 0...rmsVals.count, to: 0...rect.width)
            let y = CGFloat(rmsVals[i]).mapped(from: 0...1, to: rect.height*0.5...rect.height)
            points.append(CGPoint(x: x, y: y))
        }

        // move back to start
        let y = CGFloat(rmsVals[0]).mapped(from: 0...1, to: rect.height*0.5...rect.height)
        points.append(CGPoint(x: 0, y: y))
        points.append(CGPoint(x: 0, y: rect.height*0.5))
        
        var path = Path()
        path.addLines(points)
        return path
    }
}
