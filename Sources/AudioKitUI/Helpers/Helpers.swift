// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Foundation

func map(n: Double, start1: Double, stop1: Double, start2: Double, stop2: Double) -> Double {
    return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
}

func map(n: CGFloat, start1: CGFloat, stop1: CGFloat, start2: CGFloat, stop2: CGFloat) -> CGFloat {
    return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
}
