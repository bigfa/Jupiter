import Foundation

enum FeedPresentation {
    private static let keyLocale = Locale(identifier: "zh_CN")
    private static let displayLocale = Locale(identifier: "en_US_POSIX")
    private static let gregorianCalendar = Calendar(identifier: .gregorian)

    static func formattedSectionTitle(from value: String?, now: Date = Date()) -> String {
        sectionInfo(from: value, now: now).title
    }

    static func sectionKey(from value: String?) -> String {
        sectionInfo(from: value).key
    }

    static func sectionInfo(from value: String?, now: Date = Date()) -> (key: String, title: String) {
        guard let value, let date = parsedDate(from: value) else {
            return ("unknown", String(localized: "Unknown date"))
        }

        let keyFormatter = DateFormatter()
        keyFormatter.calendar = gregorianCalendar
        keyFormatter.locale = keyLocale
        keyFormatter.dateFormat = "yyyy-MM-dd"

        let titleFormatter = DateFormatter()
        titleFormatter.calendar = gregorianCalendar
        titleFormatter.locale = displayLocale
        let currentYear = gregorianCalendar.component(.year, from: now)
        let itemYear = gregorianCalendar.component(.year, from: date)
        titleFormatter.dateFormat = currentYear == itemYear ? "MMM dd" : "MMM dd, yyyy"

        return (
            key: keyFormatter.string(from: date),
            title: titleFormatter.string(from: date)
        )
    }

    static func parsedDate(from value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }

        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]
        if let date = isoFallback.date(from: value) {
            return date
        }

        let exifFormatter = DateFormatter()
        exifFormatter.locale = Locale(identifier: "en_US_POSIX")
        exifFormatter.timeZone = TimeZone.current
        exifFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return exifFormatter.date(from: value)
    }
}
