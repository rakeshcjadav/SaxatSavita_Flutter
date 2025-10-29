import WidgetKit
import SwiftUI

struct ReadingProgressWidget: Widget {
    let kind: String = "ReadingProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingProgressProvider()) { entry in
            ReadingProgressWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Reading Progress")
        .description("Track your daily reading progress and goals")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ReadingProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadingProgressEntry {
        ReadingProgressEntry(
            date: Date(),
            targetMinutes: 30,
            completedMinutes: 15,
            targetKirans: 3,
            completedKirans: 2,
            progressPercentage: 0.5,
            streakDays: "7 days"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingProgressEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.saxatsavita.flutter.widgets")
        let targetMinutes = userDefaults?.integer(forKey: "daily_target_minutes") ?? 30
        let completedMinutes = userDefaults?.integer(forKey: "completed_minutes") ?? 0
        let targetKirans = userDefaults?.integer(forKey: "target_kirans") ?? 3
        let completedKirans = userDefaults?.integer(forKey: "completed_kirans") ?? 0
        let progressPercentage = userDefaults?.double(forKey: "progress_percentage") ?? 0.0
        let streakDays = userDefaults?.string(forKey: "streak_days") ?? "0 days"
        
        let entry = ReadingProgressEntry(
            date: Date(),
            targetMinutes: targetMinutes,
            completedMinutes: completedMinutes,
            targetKirans: targetKirans,
            completedKirans: completedKirans,
            progressPercentage: progressPercentage,
            streakDays: streakDays
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ReadingProgressEntry] = []

        // Generate a timeline consisting of one entry for the current time.
        let currentDate = Date()
        let userDefaults = UserDefaults(suiteName: "group.com.saxatsavita.flutter.widgets")
        let targetMinutes = userDefaults?.integer(forKey: "daily_target_minutes") ?? 30
        let completedMinutes = userDefaults?.integer(forKey: "completed_minutes") ?? 0
        let targetKirans = userDefaults?.integer(forKey: "target_kirans") ?? 3
        let completedKirans = userDefaults?.integer(forKey: "completed_kirans") ?? 0
        let progressPercentage = userDefaults?.double(forKey: "progress_percentage") ?? 0.0
        let streakDays = userDefaults?.string(forKey: "streak_days") ?? "0 days"
        
        let entry = ReadingProgressEntry(
            date: currentDate,
            targetMinutes: targetMinutes,
            completedMinutes: completedMinutes,
            targetKirans: targetKirans,
            completedKirans: completedKirans,
            progressPercentage: progressPercentage,
            streakDays: streakDays
        )
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ReadingProgressEntry: TimelineEntry {
    let date: Date
    let targetMinutes: Int
    let completedMinutes: Int
    let targetKirans: Int
    let completedKirans: Int
    let progressPercentage: Double
    let streakDays: String
}

struct ReadingProgressWidgetEntryView : View {
    var entry: ReadingProgressProvider.Entry

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.14, blue: 0.49),
                        Color(red: 0.16, green: 0.21, blue: 0.58),
                        Color(red: 0.22, green: 0.29, blue: 0.67)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    Text("Reading Progress")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                    
                    // Reading time progress
                    HStack {
                        Text("Today's Reading")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.8))
                        Spacer()
                        Text("\(entry.completedMinutes)/\(entry.targetMinutes) min")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Progress bar
                    ProgressView(value: entry.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.green))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    // Kirans progress
                    HStack {
                        Text("Kirans Read")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.8))
                        Spacer()
                        Text("\(entry.completedKirans)/\(entry.targetKirans)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Streak
                    HStack {
                        Text("🔥 Streak")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.8))
                        Spacer()
                        Text(entry.streakDays)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}