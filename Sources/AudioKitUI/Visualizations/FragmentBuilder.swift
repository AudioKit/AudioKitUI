import Foundation
import MetalKit
import SwiftUI

public enum MetalFragment: String {
    case mirror = """
    float sample = waveform.sample(s, in.t.x).x;

    half4 backgroundColor{0,0,0,1};
    half4 foregroundColor{1,0.2,0.2,1};

    float y = (in.t.y - .5);
    float d = fmax(fabs(y) - fabs(sample), 0);
    float alpha = smoothstep(0.01, 0.04, d);
    return { mix(foregroundColor, backgroundColor, alpha) };
    """
}

public class FragmentBuilder {
    var foregroundColor: CGColor = Color.gray.cg
    var backgroundColor: CGColor = Color.clear.cg
    var isCentered: Bool = true
    var isFilled: Bool = true
    var isFFT: Bool = false

    init(foregroundColor: CGColor = Color.white.cg,
         backgroundColor: CGColor = Color.clear.cg,
         isCentered: Bool = true,
         isFilled: Bool = true,
         isFFT: Bool = false)
    {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.isCentered = isCentered
        self.isFilled = isFilled
        self.isFFT = isFFT
    }

    var stringValue: String {
        return """
        float sample = waveform.sample(s, \(isFFT ? "(pow(10, in.t.x) - 1.0) / 9.0" : "in.t.x")).x;

        half4 backgroundColor{\(backgroundColor.components![0]), \(backgroundColor.components![1]),\(backgroundColor.components![2]),\(backgroundColor.components![3])};
        half4 foregroundColor{\(foregroundColor.components![0]), \(foregroundColor.components![1]),\(foregroundColor.components![2]),\(foregroundColor.components![3])};

        float y = (-in.t.y + \(isCentered ? 0.5 : 1));
        float d = \(isFilled ? "fmax(fabs(y) - fabs(sample), 0)" : "fabs(y - sample)");
        float alpha = \(isFFT ? "fabs(1/(50 * d))" : "smoothstep(0.01, 0.02, d)");
        return { mix(foregroundColor, backgroundColor, alpha) };
        """
    }
}
