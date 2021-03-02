import AudioKit
import SwiftUI

public struct KeyboardWidget: ViewRepresentable {

    public var firstOctave = 2
    public var octaveCount = 2

    public typealias UIViewType = KeyboardView
    public var delegate: KeyboardDelegate?

    #if os(macOS)
    public func makeNSView(context: Context) -> KeyboardView {
        let view = KeyboardView()
        view.delegate = delegate
        view.firstOctave = firstOctave
        view.octaveCount = octaveCount
        return view
    }
    public func updateNSView(_ nsView: KeyboardView, context: Context) {}
    #else
    public func makeUIView(context: Context) -> KeyboardView {

        let view = KeyboardView()
        view.delegate = delegate
        view.firstOctave = firstOctave
        view.octaveCount = octaveCount
        return view
    }
    public func updateUIView(_ uiView: KeyboardView, context: Context) {}
    #endif

    public init(delegate: KeyboardDelegate? = nil, firstOctave: Int = 2, octaveCount: Int = 2) {
        self.delegate = delegate
        self.firstOctave = firstOctave
        self.octaveCount = octaveCount
    }
}

struct KeyboardWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KeyboardWidget().previewLayout(PreviewLayout.fixed(width: 500, height: 200))
                .padding()
                .previewDisplayName("Light Mode")

            KeyboardWidget().previewLayout(PreviewLayout.fixed(width: 500, height: 200))
                .padding()
                .background(Color(.systemBackground))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
