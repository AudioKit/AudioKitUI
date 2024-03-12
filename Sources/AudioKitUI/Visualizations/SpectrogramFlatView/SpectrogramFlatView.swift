// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/
/* 
 Cause of inefficiency of this implementation
 * Each time a new slice arrives from FFTTap, the view gets a complete layout update.
 * Rendering of new slices is done on a background thread and involves too many steps
 * Frame rate is defined by how many samples come per second. This look ugly in case of less than 25 per second.
 * It somehow doesn't show the frequency range that is selected, so some cpu time 
    is wasted for calculating stuff that isn't shown. 
 * Some arrays are iterated several times in a row whereas it could be done in one enumeration. 
 
 Following possibilities to be considered for a more energy efficient implementation:
 * Only calc what is shown, enumerate array only once (see comment on captureAmplitudeFrequencyData()). 
 * Make the layouting independent of sample rate, just move the slices left with a continous, builtin animation.
 * Layout and draw the slices directly on a Canvas (instead of HStack) and independently move the Canvas left. 
 * Try .drawingGroup() if it helps up the performance
 * Use ImageRenderer objectwillchange to create a stream of images
 * Use Sample Code from Apple of vDSP and Accellerate (macOS) and port it to iOS: 
    https://developer.apple.com/documentation/accelerate/visualizing_sound_as_an_audio_spectrogram
 * Spectrogram is actually kind of a Heatmap, so use SwiftUI.Chart
 * Use factory and emitter to emit new slice images (like in a particle system)
 * Measure performance impact when spreading on several threads or combine on main thread
 * Use Metal-API with shaders similar to what aurioTouch Sample Code by Apple did in OpenGL
 * Try to replace all CGPoint and CGPoint[] calculations using Accelerate or some other optimized library 
 * Measure efficiency and compare if it would make a difference to only use opaque colors in gradient
 * By all these possibilites to improve energy efficiency, don't forget the latency.

 */

import AudioKit
import SwiftUI

/// Displays a rolling plot of the frequency spectrum. 
///
/// Each slice represents a point in time with the frequencies shown from bottom to top
/// at this moment. Each frequency-cell is colored according to the amplitude.
/// The spectrum is shown logarithmic so octaves have the same distance. 
/// 
/// This implementation is rather energy inefficent. You might not want to use it 
/// a central feature in your app. Furthermore it's not scientificicly correct, when displaying
/// white noise, it will not show a uniform distribution.

// might be easy to make available in earlier versions, primarly because of .onChange(of:
@available(iOS 17.0, *)
public struct SpectrogramFlatView: View {
    // this static var is a shortcut: better to have this in SpectrogramModel or SpectrogramFFTMetaData
    public static var gradientUIColors: [UIColor] =  [(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)), (#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 0.6275583187)), (#colorLiteral(red: 0.4217140079, green: 0.6851614118, blue: 0.9599093795, alpha: 0.8245213468)), (#colorLiteral(red: 0.8122602105, green: 0.6033009887, blue: 0.8759307861, alpha: 1)), (#colorLiteral(red: 0.9826132655, green: 0.5594901443, blue: 0.4263145328, alpha: 1)), (#colorLiteral(red: 1, green: 0.2607713342, blue: 0.4242972136, alpha: 1))]
    @StateObject var spectrogram = SpectrogramFlatModel()
    let node: Node
    let backgroundColor: Color

    /// put only one color into the array for a monochrome view
    public init(node: Node,
                amplitudeColors: [Color] = [], 
                backgroundColor: Color = Color.black) {
        self.node = node
        if amplitudeColors.count > 1 {
            Self.gradientUIColors = amplitudeColors.map { UIColor($0) }
        } else if amplitudeColors.count == 1 {
            Self.gradientUIColors = [UIColor(backgroundColor), UIColor(amplitudeColors[0])]
        }
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        return GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .onAppear {
                        spectrogram.updateNode(node)
                    }
                HStack(spacing: 0.0) {
                    ForEach(spectrogram.slices.items) { slice in
                        // flip it as the slice was drawn in the first quadrant
                        slice.scaleEffect(x: 1, y: -1)
                        //.border(.green, width: 2.0)
                    }
                    // flip it so the new slices come in right and move to the left
                    .scaleEffect(x: -1, y: 1)
                }
                //.border(.red, width: 5.0)
                .frame(maxWidth: .infinity, maxHeight:.infinity, alignment: .trailing)
            }.onChange(of: geometry.size, initial: true) { oldSize, newSize  in
                spectrogram.sliceSize = CGSize(
                    // even when we have non-integral width for a slice, the
                    // resulting image will be integral in size but resizable
                    // the HStack will then layout them not pixel aligned and stretched.
                    // that's why we ceil/floor it: ceiling makes them a bit more precise. 
                    // floor makes it more energy efficient. 
                    // We did some measurements, it's hard to tell visually
                    width:floor(newSize.width / CGFloat(spectrogram.slices.maxItems)),
                    height: newSize.height
                )
            }
        }
    }
}

// MARK: Preview

@available(iOS 17.0, *)
struct SpectrogramFlatView_Previews: PreviewProvider {
    static var previews: some View {
        return SpectrogramFlatView(node: Mixer())
    }
}
