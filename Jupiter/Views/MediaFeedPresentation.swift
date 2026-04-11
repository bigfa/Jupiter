import Foundation

struct MediaFeedSectionHeaderContent: Equatable {
    let eyebrow: String
    let title: String
    let caption: String
}

struct MediaFeedEmptyStateContent: Equatable {
    let title: String
    let summary: String
}

enum MediaFeedPresentation {
    static let allCategoryTabTitle = "All"

    static func dateSectionHeader(title: String, itemCount: Int) -> MediaFeedSectionHeaderContent {
        MediaFeedSectionHeaderContent(
            eyebrow: "",
            title: title,
            caption: ""
        )
    }

    static func heatSectionHeader(itemCount: Int) -> MediaFeedSectionHeaderContent {
        MediaFeedSectionHeaderContent(
            eyebrow: "热度排序",
            title: "热门照片",
            caption: "\(itemCount) 张作品"
        )
    }

    static func emptyState(categoryName: String?) -> MediaFeedEmptyStateContent {
        let trimmedName = categoryName?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedName, !trimmedName.isEmpty {
            return MediaFeedEmptyStateContent(
                title: "\(trimmedName)里还没有照片",
                summary: "试试切换别的分类，或者晚一点再来看看新的整理。"
            )
        }

        return MediaFeedEmptyStateContent(
            title: "这里还没有照片",
            summary: "全部分类暂时还是空的，稍后再来翻翻看。"
        )
    }

    static func noMoreLabel(sort: MediaSortOption) -> String {
        switch sort {
        case .date:
            return "已经看到最后了"
        case .likes:
            return "热门照片已经看完了"
        }
    }
}
