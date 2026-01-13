//
//  ZZZWidgetLiveActivity.swift
//  ZZZWidget
//
//  Created by Joo on 1/7/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// ZZZActivityAttributes is defined in Runner/ZZZActivityAttributes.swift 
// and added to the ZZZWidgetExtension target.

struct ZZZWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ZZZActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                // Character Image or Emoji (Placeholder)
                Text(context.attributes.characterName == "MyPet" ? "🐶" : "👤")
                    .font(.largeTitle)
                    .padding()
                
                VStack(alignment: .leading) {
                    Text(context.state.status)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(context.state.message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text("🐶")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.message)
                        .font(.caption)
                }
            } compactLeading: {
                Text("🐶")
            } compactTrailing: {
                Text(context.state.status)
            } minimal: {
                Text("🐶")
            }
            .widgetURL(URL(string: "zzzapp://activity"))
            .keylineTint(Color.blue)
        }
    }
}

// Preview commented out for iOS 16 compatibility
// #Preview("Notification", as: .content, using: ZZZActivityAttributes(characterName: "MyPet")) {
//    ZZZWidgetLiveActivity()
// } contentStates: {
//     ZZZActivityAttributes.ContentState(status: "SLEEP", message: "Sleeping...")
//     ZZZActivityAttributes.ContentState(status: "ONLINE", message: "Online!")
// }