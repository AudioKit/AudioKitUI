// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI


#if !os(macOS) || targetEnvironment(macCatalyst)
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
#endif

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

extension CGRect {
     /// Initialize with a size
     /// - Parameter size: size to create the CGRect with
     public init(size: CGSize) {
         self.init(origin: .zero, size: size)
     }

     /// Initialize with width and height
     /// - Parameters:
     ///   - width: Width of rectangle
     ///   - height: Height of rectangle
     public init(width: CGFloat, height: CGFloat) {
         self.init(origin: .zero, size: CGSize(width: width, height: height))
     }

     /// Initialize with width and height
     /// - Parameters:
     ///   - width: Width of rectangle
     ///   - height: Height of rectangle
     public init(width: Int, height: Int) {
         self.init(width: CGFloat(width), height: CGFloat(height))
     }
 }
