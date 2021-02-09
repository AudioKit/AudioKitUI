// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI

struct CircleCursorView: View {
    @State var cursorColor = Color.yellow

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(cursorColor)
                    .opacity(0.3)
                    .shadow(color: cursorColor, radius: geo.size.width * 0.01)
                Circle()
                    .fill(cursorColor)
                    .opacity(0.6)
                    .padding(geo.size.width * 0.05)
                Circle()
                    .fill(cursorColor)
                    .shadow(color: cursorColor, radius: geo.size.width * 0.1)
                    .padding(geo.size.width * 0.1)
            }
        }
    }
}

struct CircleCursorView_Previews: PreviewProvider {
    static var previews: some View {
        CircleCursorView()
    }
}
