#if !os(macOS) || targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

public typealias TouchCallback = ([CGPoint])->Void

public struct MultitouchOverlayView: UIViewRepresentable {

    public var callback: TouchCallback

    public init(callback cb: @escaping TouchCallback) {
        callback = cb
    }

    public func makeUIView(context: UIViewRepresentableContext<MultitouchOverlayView>) -> MultitouchOverlayView.UIViewType {
        let v = UIView(frame: .zero)
        let gesture = MultitouchRecognizer(target: context.coordinator, callback: callback)
        v.addGestureRecognizer(gesture)
        return v
    }

    public func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<MultitouchOverlayView>) {}
}

class MultitouchRecognizer: UIGestureRecognizer {

    var callback: TouchCallback = { _ in }
    var touchLocations = [UITouch: CGPoint]()

    init(target: Any?, callback: @escaping TouchCallback) {
        self.callback = callback
        super.init(target: target, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        touchLocations.removeAll()
        for touch in touches { touchLocations[touch] = touch.location(in: super.view) }
        callback(Array(touchLocations.values))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        touchLocations.removeAll()
        for touch in touches { touchLocations[touch] = touch.location(in: super.view) }
        callback(Array(touchLocations.values))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        touchLocations.removeAll()
        for touch in touches { touchLocations.removeValue(forKey: touch) }
        callback(Array(touchLocations.values))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        touchLocations.removeAll()
        for touch in touches { touchLocations.removeValue(forKey: touch) }
        callback(Array(touchLocations.values))
    }

}
#endif
