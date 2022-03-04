// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Foundation

enum TestAudioURLs: String {
    case drumloop = "drumloop.wav"

    func url() -> URL {
        let path = Bundle.module.path(forResource: self.rawValue, ofType: nil)!
        return URL(fileURLWithPath: path)
    }
}
