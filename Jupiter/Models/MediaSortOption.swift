import Foundation

enum MediaSortOption: String, CaseIterable, Identifiable {
    case date
    case likes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .date: return String(localized: "Latest")
        case .likes: return String(localized: "Hottest")
        }
    }
}
