import XCTest
@testable import Jupiter

final class MediaFeedPresentationTests: XCTestCase {
    func testAllCategoryTabTitleIsAlwaysEnglish() {
        XCTAssertEqual(MediaFeedPresentation.allCategoryTabTitle, "All")
    }

    func testDateSectionHeaderUsesEditorialArchiveCopy() {
        let header = MediaFeedPresentation.dateSectionHeader(
            title: "Apr 10",
            itemCount: 6
        )

        XCTAssertEqual(header.eyebrow, "")
        XCTAssertEqual(header.title, "Apr 10")
        XCTAssertEqual(header.caption, "")
    }

    func testHeatSectionHeaderUsesCuratedCopy() {
        let header = MediaFeedPresentation.heatSectionHeader(itemCount: 12)

        XCTAssertEqual(header.eyebrow, "热度排序")
        XCTAssertEqual(header.title, "热门照片")
        XCTAssertEqual(header.caption, "12 张作品")
    }

    func testEmptyStateUsesAllCopyForNilCategory() {
        let content = MediaFeedPresentation.emptyState(categoryName: nil)

        XCTAssertEqual(content.title, "这里还没有照片")
        XCTAssertEqual(content.summary, "全部分类暂时还是空的，稍后再来翻翻看。")
    }

    func testEmptyStateUsesCategorySpecificCopyWhenCategoryProvided() {
        let content = MediaFeedPresentation.emptyState(categoryName: "旅行")

        XCTAssertEqual(content.title, "旅行里还没有照片")
        XCTAssertEqual(content.summary, "试试切换别的分类，或者晚一点再来看看新的整理。")
    }
}
