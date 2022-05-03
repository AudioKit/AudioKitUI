// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

/// Background grid for the piano roll.
///
/// We tried using Canvas but because a piano roll grid can be very large when inside a scroll
/// view, Canvas allocates too big of a texture for rendering.
struct PianoRollGrid: Shape {

    var gridSize: CGSize
    var length: Int
    var height: Int

    func path(in rect: CGRect) -> Path {

        let size = rect.size
        var path = Path()
        for column in 0 ... length {
            let x = CGFloat(column) * gridSize.width
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for row in 0 ... height {
            let y = CGFloat(row) * gridSize.height
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        return path
    }
}
