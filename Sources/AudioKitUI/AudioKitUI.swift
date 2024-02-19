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

    var simd: SIMD4<Float> {
        if let comps = cg.components {
            return .init(Float(comps[0]),
                         Float(comps[1]),
                         Float(comps[2]),
                         Float(comps[3]))
        }
        return .zero
    }
}

public extension EnvironmentValues {
    var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}
