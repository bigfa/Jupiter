import Foundation

enum MediaSortOption: String, CaseIterable, Identifiable {
    case date
    case likes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .date: return "最新"
        case .likes: return "最热"
        }
    }
}
