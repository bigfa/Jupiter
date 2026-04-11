import XCTest
@testable import Jupiter

final class AlbumCardPresentationTests: XCTestCase {
    func testSubtitleFallsBackToCategoriesWhenDescriptionMissing() {
        let album = AlbumListItem(
            id: "a_1",
            title: "Japan 2024",
            description: nil,
            coverMedia: nil,
            mediaCount: 88,
            likes: 10,
            slug: "japan-2024",
            isProtected: true,
            categories: [
                MediaCategoryItem(id: "travel", name: "旅行", slug: "travel", count: nil),
                MediaCategoryItem(id: "city", name: "城市", slug: "city", count: nil)
            ],
            categoryIds: ["travel", "city"]
        )

        XCTAssertEqual(
            AlbumCardPresentation.subtitle(for: album),
            "旅行 · 城市"
        )
    }

    func testSubtitleFallsBackToDefaultCopyWhenDescriptionAndCategoriesMissing() {
        let album = AlbumListItem(
            id: "a_2",
            title: "Moments",
            description: "   ",
            coverMedia: nil,
            mediaCount: nil,
            likes: nil,
            slug: nil,
            isProtected: nil,
            categories: nil,
            categoryIds: nil
        )

        XCTAssertEqual(
            AlbumCardPresentation.subtitle(for: album),
            "慢慢整理你的照片收藏"
        )
    }

    func testStatItemsKeepExpectedOrder() {
        let album = AlbumListItem(
            id: "a_3",
            title: "Archive",
            description: nil,
            coverMedia: nil,
            mediaCount: 88,
            likes: 10,
            slug: nil,
            isProtected: true,
            categories: nil,
            categoryIds: nil
        )

        XCTAssertEqual(
            AlbumCardPresentation.statItems(for: album).map(\.title),
            ["88 张照片", "10 喜欢", "受保护"]
        )
    }
}
