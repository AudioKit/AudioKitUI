// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import SwiftUI

public struct WavetableArrayView: View {
    @StateObject var wavetableModel = WavetableModel()
    var node: DynamicWaveformNode
    @Binding var selectedValue: AUValue
    @State var wavetables: [AudioKit.Table]
    private var backgroundColor: Color
    private var arrayStrokeColor: Color
    private var selectedStrokeColor: Color
    private var fillColor: Color
    
    public init(_ node: DynamicWaveformNode,
                selectedValue: Binding<AUValue>,
                realWavetables: [AudioKit.Table],
                backgroundColor: Color = Color.black,
                arrayStrokeColor: Color = Color.white.opacity(0.4),
                selectedStrokeColor: Color = Color.white.opacity(1.0),
                fillColor: Color = Color.green.opacity(0.7))
    {
        self.node = node
        _selectedValue = selectedValue
        self._wavetables = State(initialValue: Table.downSampleTables(inputTables: realWavetables))
        self.backgroundColor = backgroundColor
        self.arrayStrokeColor = arrayStrokeColor
        self.selectedStrokeColor = selectedStrokeColor
        self.fillColor = fillColor
    }
    
    public var body: some View {
        let selectedIndex = Int(selectedValue)
        let xOffset = CGFloat(0.21) / CGFloat(wavetables.count)
        let yOffset = CGFloat(-0.77) / CGFloat(wavetables.count)
        
        return GeometryReader { geometry in
            ZStack {
                StaticWavetableArrayView(wavetables: wavetables)
                fillAndStrokeTable(width: geometry.size.width * 0.75,
                                   height: geometry.size.height * 0.2,
                                   table: wavetableModel.floats)
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.2)
                    .offset(x: CGFloat(selectedIndex) * geometry.size.width * xOffset-geometry.size.width / 4.3,
                            y: CGFloat(selectedIndex) * geometry.size.height * yOffset + geometry.size.height / 2.6)
            }
            .onAppear {
                wavetableModel.updateNode(node)
            }
        }
    }
    
    func fillAndStrokeTable(width: CGFloat, height: CGFloat, table: [Float], fillColor: Color = Color.green.opacity(0.7), selectedStrokeColor: Color = Color.white.opacity(1.0)) -> some View {
        var points: [CGPoint] = []
        points.append(CGPoint(x: 0.0, y: height * 0.5))
        for i in 0..<table.count {
            let x = i.mapped(from: 0...table.count, to: 0.0...width)
            let y = CGFloat(table[i]).mappedInverted(from: -1...1, to: 0.0...height)
            points.append(CGPoint(x: x, y: y))
        }
        points.append(CGPoint(x: width, y: height * 0.5))
        points.append(CGPoint(x: 0.0, y: height * 0.5))

        return ZStack {
            Path { path in
                path.addLines(points)
            }.stroke(selectedStrokeColor, lineWidth: 1)
            
            Path { path in
                path.addLines(points)
            }.fill(fillColor)
        }
    }
}

struct StaticWavetableArrayView: View {
    @State var wavetables: [AudioKit.Table] = []
    @State var arrayStrokeColor = Color.white.opacity(0.4)
    var selectedStrokeColor = Color.white.opacity(1.0)
    
    var body: some View {
        let xOffset = CGFloat(0.21) / CGFloat(wavetables.count)
        let yOffset = CGFloat(-0.77) / CGFloat(wavetables.count)

        return GeometryReader { geometry in
            ZStack {
                Color.black
                ForEach((0..<wavetables.count).reversed(), id: \.self) { i in
                    strokeTable(width: geometry.size.width * 0.75,
                                height: geometry.size.height * 0.2,
                                table: wavetables[i].content)
                        .frame(width: geometry.size.width * 0.5,
                               height: geometry.size.height * 0.2)
                        .offset(x: CGFloat(i) * geometry.size.width * xOffset-geometry.size.width / 4.3,
                                y: CGFloat(i) * geometry.size.height * yOffset + geometry.size.height / 2.6)
                }
            }
        }
    }
    
    func strokeTable(width: CGFloat, height: CGFloat, table: [Float]) -> some View {
        var points: [CGPoint] = []
        for i in 0..<table.count {
            let x = i.mapped(from: 0...table.count, to: 0.0...width)
            let y = CGFloat(table[i]).mappedInverted(from: -1...1, to: 0.0...height)
            points.append(CGPoint(x: x, y: y))
        }
        
        return Path { path in
            path.addLines(points)
        }
        .stroke(arrayStrokeColor, lineWidth: 1)
    }
}
