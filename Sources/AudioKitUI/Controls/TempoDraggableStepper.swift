import SwiftUI

public struct TempoDraggableStepper: View {
    @Binding var tempo: Float
    var sensitivty: Float = 1.0

    public init(tempo: Binding<Float>) {
        _tempo = tempo
    }

    @State var initialTouchPoint: CGPoint?
    @State var initialTempo: Float = 0.0

    public var body: some View {
        GeometryReader { geo in
            let font = Font.system(size: geo.size.height * 0.6, weight: .light)
            HStack {
                Text("TEMPO").fontWeight(.semibold).font(font).padding(.trailing, 5)
                Text("◀").font(font).onTapGesture { tempo -= 1 }
                Text("\(Int(tempo))").font(font).frame(width: geo.size.height * 1.3)
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                .onChanged({ touch in
                        if let initialTouchPoint = initialTouchPoint {
                            tempo = max(1, initialTempo + Float(touch.location.x - initialTouchPoint.x + (initialTouchPoint.y - touch.location.y)) * sensitivty / 30.0)
                        } else {
                            initialTouchPoint = touch.location
                            initialTempo = tempo
                        }
                    }).onEnded({ _ in
                        initialTouchPoint = nil
                        initialTempo = 0.0
                    }) )

                Text("▶").font(font).onTapGesture { tempo += 1 }
            }.frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
