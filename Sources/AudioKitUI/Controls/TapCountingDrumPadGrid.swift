// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

#if !os(macOS) || targetEnvironment(macCatalyst)

import SwiftUI

public struct TapCountingDrumPadGrid: View {
    var names: [String]
    var rows = 2
    var cols = 4
    @State var drumPadTouchCount: [Int]
    var callback: ([Int]) -> Void = { _ in }

    public init(names: [String], rows: Int = 2, cols: Int = 4, callback: @escaping ([Int]) -> Void) {
        self.names = names
        self.rows = rows
        self.cols = cols
        self.callback = callback
        drumPadTouchCount = Array(repeating: 0, count: rows * cols)
    }

    let padColors =  [Color(red: 79.0/255.0, green: 118.0/255.0, blue: 142.0/255.0),
                      Color(red: 201.0/255.0, green: 83.0/255.0, blue: 70.0/255.0),
                      Color(red: 79.0/255.0, green: 118.0/255.0, blue: 142.0/255.0),
                      Color(red: 201.0/255.0, green: 83.0/255.0, blue: 70.0/255.0),
                      Color(red: 103.0/255.0, green: 97.0/255.0, blue: 124.0/255.0),
                      Color(red: 57.0/255.0, green: 125.0/255.0, blue: 113.0/255.0),
                      Color(red: 103.0/255.0, green: 97.0/255.0, blue: 124.0/255.0),
                      Color(red: 57.0/255.0, green: 125.0/255.0, blue: 113.0/255.0)
    ]

    func padColor(_ idx: Int) -> Color {
        if idx < drumPadTouchCount.count {
            return padColors[idx].opacity(max(0.5, 1.0 - 0.2 * Double(drumPadTouchCount[idx])))
        } else {
            return Color.clear
        }
    }

    @State var padWidth: CGFloat = 0
    @State var padHeight: CGFloat = 0

    func updateSize(_ gp: GeometryProxy) {
        padWidth = gp.size.width / CGFloat(cols) - 5
        padHeight = gp.size.height / CGFloat(rows)
    }

    func calculateDrumPadTouchCounts(_ touchLocations: [CGPoint]) -> [Int] {
        var returnArray = Array(repeating: 0, count: rows * cols)
        for touch in touchLocations {
            let row = Int(touch.y / (padHeight + 10))
            let column = Int(touch.x / (padWidth + 7))
            let idx = row * cols + column
            if idx < returnArray.count { returnArray[idx] += 1 }
        }
        return returnArray
    }

    public var body: some View {
        GeometryReader { gp in
            let count = rows * cols
            let padWidth = gp.size.width / CGFloat(cols) - 5 //* (CGFloat(cols) - 1)
            let padHeight = gp.size.height / CGFloat(rows)
            let columns = Array(repeating: GridItem(.fixed(padWidth)), count: cols)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<count) { idx in
                    ZStack {
                        if #available(iOS 15.0, *) {
                            RoundedRectangle(cornerRadius: padWidth / 10)
                                .fill(.ellipticalGradient(Gradient(colors: [padColor(idx).opacity(0.7),
                                                                            padColor(idx)])))
                                .frame(width: padWidth, height: padHeight)
                        } else {
                            RoundedRectangle(cornerRadius: padWidth / 10)
                                .fill(padColor(idx))
                                .frame(width: padWidth, height: padHeight)
                        }
                        Text(names[idx]).foregroundColor(Color.primary.opacity(0.8)).font(Font.system(size: 18))
                    }
                }
            }.overlay(
                MultitouchOverlayView { touchLocations in
                    updateSize(gp)
                    drumPadTouchCount = calculateDrumPadTouchCounts(touchLocations)
                    callback(drumPadTouchCount)
                }
            )
        }
    }
}

#endif
