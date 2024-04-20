// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

#if !os(macOS) || targetEnvironment(macCatalyst)

import Foundation
import UIKit

/// Get an intermediate color between two or more colors
/// 
/// Example: `let color = [.green, .yellow, .red].intermediate(0.7)`
///
/// inspired by [stackoverflow 15032562 answer Nikaaner](https://stackoverflow.com/questions/15032562/ios-find-color-at-point-between-two-colors/59996029#59996029)
extension Array where Element: UIColor {
    /// Get an intermediate color between two or more colors
    /// 
    /// Example: `let color = [.green, .yellow, .red].intermediate(0.7)`
    public func intermediate(_ percentage: CGFloat) -> UIColor {
        let percentage = Swift.max(Swift.min(percentage, 1), 0)
        switch percentage {
        case 0: return first ?? .clear
        case 1: return last ?? .clear
        default:
            let approxIndex = percentage / (1 / CGFloat(count - 1))
            let firstIndex = Int(approxIndex.rounded(.down))
            let secondIndex = Int(approxIndex.rounded(.up))
            let fallbackIndex = Int(approxIndex.rounded())

            let firstColor = self[firstIndex]
            let secondColor = self[secondIndex]
            let fallbackColor = self[fallbackIndex]

            var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
            var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
            guard firstColor.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1) else { return fallbackColor }
            guard secondColor.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2) else { return fallbackColor }

            let intermediatePercentage = approxIndex - CGFloat(firstIndex)
            return UIColor(
                red: CGFloat(red1 + (red2 - red1) * intermediatePercentage),
                green: CGFloat(green1 + (green2 - green1) * intermediatePercentage),
                blue: CGFloat(blue1 + (blue2 - blue1) * intermediatePercentage),
                alpha: CGFloat(alpha1 + (alpha2 - alpha1) * intermediatePercentage)
            )
        }
    }
}

#endif
