// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import SwiftUI

#if os(macOS)
public typealias ViewRepresentable = NSViewRepresentable
#else
public typealias ViewRepresentable = UIViewRepresentable
#endif

public extension Color {
    var cg: CGColor {
        return CrossPlatformColor(self).cgColor
    }
}
