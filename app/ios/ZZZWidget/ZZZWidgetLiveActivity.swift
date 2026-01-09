//
//  ZZZWidgetLiveActivity.swift
//  ZZZWidget
//
//  Created by Joo on 1/7/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ZZZWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ZZZWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ZZZWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ZZZWidgetAttributes {
    fileprivate static var preview: ZZZWidgetAttributes {
        ZZZWidgetAttributes(name: "World")
    }
}

extension ZZZWidgetAttributes.ContentState {
    fileprivate static var smiley: ZZZWidgetAttributes.ContentState {
        ZZZWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ZZZWidgetAttributes.ContentState {
         ZZZWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ZZZWidgetAttributes.preview) {
   ZZZWidgetLiveActivity()
} contentStates: {
    ZZZWidgetAttributes.ContentState.smiley
    ZZZWidgetAttributes.ContentState.starEyes
}
