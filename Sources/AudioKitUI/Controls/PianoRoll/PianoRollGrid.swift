// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

struct PianoRollGrid: Shape {

    var gridSize: CGSize
    var length: Int
    var height: Int

    func path(in rect: CGRect) -> Path {

        let size = rect.size
        var path = Path()
        for i in 0 ... length {
            let x = CGFloat(i) * gridSize.width
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for i in 0 ... height {
            let y = CGFloat(i) * gridSize.height
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        return path
    }
}
