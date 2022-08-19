// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Foundation

enum TestAudioURLs: String {
    case drumloop = "drumloop.wav", short = "short.aif"

    func url() -> URL {
        let path = Bundle.module.path(forResource: rawValue, ofType: nil)!
        return URL(fileURLWithPath: path)
    }
}
