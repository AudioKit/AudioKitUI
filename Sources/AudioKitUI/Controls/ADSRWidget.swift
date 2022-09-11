#if !os(macOS) || targetEnvironment(macCatalyst)
import AudioKit
import AVFoundation
import SwiftUI

public struct ADSRWidget: UIViewRepresentable {
    public typealias UIViewType = ADSRView
    var callback: (AUValue, AUValue, AUValue, AUValue) -> Void

    public init(callback: @escaping (AUValue, AUValue, AUValue, AUValue) -> Void) {
        self.callback = callback
    }

    public func makeUIView(context _: Context) -> ADSRView {
        let view = ADSRView(callback: callback)
        view.bgColor = .systemBackground
        return view
    }

    public func updateUIView(_: ADSRView, context _: Context) {
        //
    }
}
#endif
