// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

struct ArcKnobDefaults {
    static let knobPreferredWidth: CGFloat = 80
    static let knobBgColor = Color.clear //  Color(hue: 0.5, saturation: 0.75, brightness: 0.5, opacity: 0.55)
    static let knobLineCap: CGLineCap = .round
    static let knobCircleWidth = 0.75 * knobPreferredWidth
    static let knobStrokeWidth = 2 * knobPreferredWidth / 20
    static let knobRotationRange: CGFloat = 0.875
    static let knobTrimMin: CGFloat = (1 - knobRotationRange) / 2.0
    static let knobTrimMax: CGFloat = 1 - knobTrimMin
    static let knobDragSensitivity: CGFloat = 0.005
}

public struct ArcKnob: View {

    @Binding var value: Float
    var range: ClosedRange<Float>
    var title: String = ""
    var textColor: Color = Color.primary
    var arcColor: Color = Color.primary
    @State var displayString: String = ""

    public init(value: Binding<Float>, range: ClosedRange<Float>, title: String, textColor: Color, arcColor: Color) {
        self._value = value
        self.range = range
        self.title = title
        self.displayString = title
        self.textColor = textColor
        self.arcColor = arcColor
    }

    var normalizedValue: Float {
        min(1.0, max(0.0, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }

    @State private var lastLocation: CGPoint = CGPoint(x: 0, y: 0)
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { dragPoint in
                guard lastLocation != CGPoint.zero else {
                    lastLocation = dragPoint.location
                    return
                }
                var change = Float((dragPoint.location.x - lastLocation.x) * ArcKnobDefaults.knobDragSensitivity)
                change -= Float((dragPoint.location.y - lastLocation.y) * ArcKnobDefaults.knobDragSensitivity)
                let tempValue = value +  change * ((range.upperBound - range.lowerBound) + range.lowerBound)
                value = min(range.upperBound, max(range.lowerBound, tempValue))
                lastLocation = dragPoint.location
                displayString = String(format: "%0.4f", value)
            }
            .onEnded { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    displayString = title
                }
                lastLocation = CGPoint.zero
            }
    }

    public var body: some View {
        let trim = ArcKnobDefaults.knobTrimMin + CGFloat(normalizedValue) * (ArcKnobDefaults.knobTrimMax - ArcKnobDefaults.knobTrimMin)
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(Color.black).opacity(0.00001) // Hack to make gesture work from "clear portion" of knob
            VStack {
                // Title of ArcKnob
                Text(displayString == "" ? title : displayString).fontWeight(.semibold).font(Font.system(size: geometry.size.height / 8)).foregroundColor(textColor)

                ZStack(alignment: .center) {

                    // Stroke entire trim of knob
                    Circle()
                        .trim(from: ArcKnobDefaults.knobTrimMin, to: ArcKnobDefaults.knobTrimMax)
                        .rotation(.degrees(-270))
                        .stroke(Color.black ,style: StrokeStyle(lineWidth: ArcKnobDefaults.knobStrokeWidth, lineCap: ArcKnobDefaults.knobLineCap))
                        .frame(width: ArcKnobDefaults.knobCircleWidth, height: ArcKnobDefaults.knobCircleWidth)

                    // Stroke value trim of knob
                    Circle()
                        .trim(from: ArcKnobDefaults.knobTrimMin, to: trim)
                        .rotation(.degrees(-270))
                        .stroke(arcColor, style: StrokeStyle(lineWidth: ArcKnobDefaults.knobStrokeWidth + 1, lineCap: ArcKnobDefaults.knobLineCap))
                        .frame(width: ArcKnobDefaults.knobCircleWidth, height: ArcKnobDefaults.knobCircleWidth)
                }

            }}.gesture(dragGesture)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}
