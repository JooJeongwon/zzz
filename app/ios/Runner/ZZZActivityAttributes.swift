import ActivityKit
import Foundation

struct ZZZActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that changes over time
        var status: String
        var message: String
    }

    // Fixed non-changing properties about the activity
    var characterName: String
}
