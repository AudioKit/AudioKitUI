// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

/// Settings class for the KeyboardWidget - Publishes to KeyboardView
public class KeyboardWidgetSettings: ObservableObject {
    /// Octave Count for the wrapped KeyboardView
    @Published public var octaveCount: Int = 2
    /// First Octave for the wrapped KeyboardView
    @Published public var firstOctave: Int = 0
    /// Polyphonic Mode toggle for the wrapped KeyboardView
    @Published public var polyphonicMode: Bool = false
    public init() {}
}
/// SwiftUI View - Wraps a KeyboardView
public struct KeyboardWidget: ViewRepresentable {
    var firstOctave: Int
    var octaveCount: Int
    var polyphonicMode: Int

    public typealias UIViewType = KeyboardView
    public var delegate: KeyboardDelegate?

    #if os(macOS)
    public func makeNSView(context: Context) -> KeyboardView {
        let view = KeyboardView(width: 400, height: 100)
        view.delegate = delegate
        view.firstOctave = firstOctave
        view.octaveCount = octaveCount
        view.polyphonicMode = polyphonicMode
        return view
    }
    public func updateNSView(_ nsView: KeyboardView, context: Context) {
        nsView.firstOctave = firstOctave
        nsView.octaveCount = octaveCount
        nsView.polyphonicMode = polyphonicMode
        view.setNeedsDisplay()
    }
    #else
    public func makeUIView(context: Context) -> KeyboardView {
        let view = KeyboardView()
        view.delegate = delegate
        view.firstOctave = firstOctave
        view.octaveCount = octaveCount
        view.polyphonicMode = polyphonicMode
        return view
    }
    public func updateUIView(_ uiView: KeyboardView, context: Context) {
        uiView.firstOctave = firstOctave
        uiView.octaveCount = octaveCount
        uiView.polyphonicMode = polyphonicMode
        uiView.setNeedsDisplay()
    }
    #endif

    public init(delegate: KeyboardDelegate? = nil, firstOctave: Int, octaveCount: Int) {
        self.delegate = delegate
        self.firstOctave = firstOctave
        self.octaveCount = octaveCount
        self.polyphonicMode = polyphonicMode
    }
}
