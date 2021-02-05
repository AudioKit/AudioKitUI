// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

extension Shape {
    @ViewBuilder
    func flexableFill(fillType: FillType) -> some View {
        switch fillType {
        case .solid(let color):
            self.fill(color)
        case .gradient(let gradient):
            self.fill(LinearGradient(gradient: gradient, startPoint: .top, endPoint: .center))
        }
    }
}

enum FillType {
    case solid(color: Color)
    case gradient(gradient: Gradient)
}
