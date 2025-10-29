//
//  SakshatSavitaWidgetsLiveActivity.swift
//  SakshatSavitaWidgets
//
//  Created by Rakesh Jadav on 28/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SakshatSavitaWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SakshatSavitaWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SakshatSavitaWidgetsAttributes.self) { context in
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

extension SakshatSavitaWidgetsAttributes {
    fileprivate static var preview: SakshatSavitaWidgetsAttributes {
        SakshatSavitaWidgetsAttributes(name: "World")
    }
}

extension SakshatSavitaWidgetsAttributes.ContentState {
    fileprivate static var smiley: SakshatSavitaWidgetsAttributes.ContentState {
        SakshatSavitaWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SakshatSavitaWidgetsAttributes.ContentState {
         SakshatSavitaWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SakshatSavitaWidgetsAttributes.preview) {
   SakshatSavitaWidgetsLiveActivity()
} contentStates: {
    SakshatSavitaWidgetsAttributes.ContentState.smiley
    SakshatSavitaWidgetsAttributes.ContentState.starEyes
}
