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
        case .home: return "相册"
        case .albums: return "首页"
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
