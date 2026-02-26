import Foundation

enum RootSection: String {
    case home
    case albums

    var order: Int {
        switch self {
        case .home: return 0
        case .albums: return 1
        }
    }

    var toggleTitle: String {
        switch self {
        case .home: return String(localized: "Albums")
        case .albums: return String(localized: "Home")
        }
    }

    var toggleIcon: String {
        switch self {
        case .home: return "rectangle.stack"
        case .albums: return "photo.on.rectangle"
        }
    }

    var next: RootSection {
        switch self {
        case .home: return .albums
        case .albums: return .home
        }
    }
}
