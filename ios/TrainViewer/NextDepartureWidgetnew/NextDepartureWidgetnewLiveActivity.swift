//
//  NextDepartureWidgetnewLiveActivity.swift
//  NextDepartureWidgetnew
//
//  Created by Sayed Mohamed on 07.09.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NextDepartureWidgetnewAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct NextDepartureWidgetnewLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NextDepartureWidgetnewAttributes.self) { context in
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

extension NextDepartureWidgetnewAttributes {
    fileprivate static var preview: NextDepartureWidgetnewAttributes {
        NextDepartureWidgetnewAttributes(name: "World")
    }
}

extension NextDepartureWidgetnewAttributes.ContentState {
    fileprivate static var smiley: NextDepartureWidgetnewAttributes.ContentState {
        NextDepartureWidgetnewAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: NextDepartureWidgetnewAttributes.ContentState {
         NextDepartureWidgetnewAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: NextDepartureWidgetnewAttributes.preview) {
   NextDepartureWidgetnewLiveActivity()
} contentStates: {
    NextDepartureWidgetnewAttributes.ContentState.smiley
    NextDepartureWidgetnewAttributes.ContentState.starEyes
}
