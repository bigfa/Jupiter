import SwiftUI

struct MediaFloatingMetadataCard<Accessory: View>: View {
    let item: MediaItem
    let viewportHeight: CGFloat
    let bottomSafeInset: CGFloat
    let isLoading: Bool
    let statusMessage: String?
    let accessory: Accessory

    init(
        item: MediaItem,
        viewportHeight: CGFloat,
        bottomSafeInset: CGFloat,
        isLoading: Bool,
        statusMessage: String?,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.item = item
        self.viewportHeight = viewportHeight
        self.bottomSafeInset = bottomSafeInset
        self.isLoading = isLoading
        self.statusMessage = statusMessage
        self.accessory = accessory()
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 0) {
            if horizontalSizeClass == .compact {
                Capsule()
                    .fill(Color(.tertiaryLabel))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
            }
            
            HStack {
                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                accessory
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            let state = MediaMetadataPresentation.contentState(item: item, isDetailLoading: isLoading)
            
            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    Group {
                        switch state {
                        case .loadingSkeleton:
                            skeletonView(width: proxy.size.width)
                        case .empty:
                            Text("No EXIF data")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                        case .content:
                            contentView(cards: MediaMetadataPresentation.cards(for: item), width: proxy.size.width)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottomSafeInset + 24)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 36, x: 0, y: 12)
        )
    }

    @ViewBuilder
    private func skeletonView(width: CGFloat) -> some View {
        let count = MediaMetadataPresentation.cardCount(for: item, isDetailLoading: isLoading)
        let placeholderCards = (0..<count).map { _ in
            MediaMetadataCardItem(field: .camera, value: "Loading...")
        }
        contentView(cards: placeholderCards, width: width, isSkeleton: true)
            .opacity(0.6)
    }

    private func contentView(cards: [MediaMetadataCardItem], width: CGFloat, isSkeleton: Bool = false) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(cards) { card in
                if isSkeleton {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .frame(minHeight: 110)
                } else {
                    CardItemView(card: card)
                        .frame(minHeight: 110)
                }
            }
        }
    }
}

private struct CardItemView: View {
    let card: MediaMetadataCardItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MetadataLineIcon(field: card.field)
                .frame(width: 28, height: 28)
                .accessibilityLabel(card.field.accessibilityTitle)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(card.field.accessibilityTitle.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .tracking(0.5)
                
                Text(card.value)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}

private struct MetadataLineIcon: View {
    let field: MediaMetadataField

    @ViewBuilder
    var body: some View {
        Group {
            if field == .iso {
                isoBadgeIcon
            } else if field == .focalLength {
                focalLengthBadgeIcon
            } else {
                GeometryReader { proxy in
                    iconPath(in: proxy.frame(in: .local))
                        .stroke(
                            Color.primary.opacity(0.7),
                            style: StrokeStyle(
                                lineWidth: 1.5,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var focalLengthBadgeIcon: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let strokeColor = Color.primary.opacity(0.7)

            ZStack {
                Text("mm")
                    .font(.system(size: side * 0.26, weight: .semibold, design: .rounded))
                    .foregroundStyle(strokeColor)
                    .offset(y: -side * 0.16)

                Path { path in
                    let y = side * 0.70
                    let left = side * 0.16
                    let right = side * 0.84
                    let arrow = side * 0.10

                    path.move(to: CGPoint(x: left, y: y))
                    path.addLine(to: CGPoint(x: right, y: y))

                    path.move(to: CGPoint(x: left + arrow, y: y - arrow * 0.7))
                    path.addLine(to: CGPoint(x: left, y: y))
                    path.addLine(to: CGPoint(x: left + arrow, y: y + arrow * 0.7))

                    path.move(to: CGPoint(x: right - arrow, y: y - arrow * 0.7))
                    path.addLine(to: CGPoint(x: right, y: y))
                    path.addLine(to: CGPoint(x: right - arrow, y: y + arrow * 0.7))
                }
                .stroke(
                    strokeColor,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }

    private var isoBadgeIcon: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let inset = side * 0.08
            let strokeColor = Color.primary.opacity(0.7)

            ZStack {
                RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1.5)
                    .padding(inset)

                Text("ISO")
                    .font(.system(size: side * 0.34, weight: .semibold, design: .rounded))
                    .foregroundStyle(strokeColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private func iconPath(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let minX = rect.midX - side / 2
        let minY = rect.midY - side / 2

        func x(_ value: CGFloat) -> CGFloat { minX + value / 24 * side }
        func y(_ value: CGFloat) -> CGFloat { minY + value / 24 * side }
        func point(_ px: CGFloat, _ py: CGFloat) -> CGPoint { CGPoint(x: x(px), y: y(py)) }
        func box(_ px: CGFloat, _ py: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: x(px), y: y(py), width: w / 24 * side, height: h / 24 * side)
        }

        var path = Path()

        switch field {
        case .camera:
            path.addPath(Path(roundedRect: box(2, 8, 20, 12), cornerRadius: side * 2.5 / 24))
            path.move(to: point(8, 8))
            path.addLine(to: point(9.4, 6))
            path.addLine(to: point(14.6, 6))
            path.addLine(to: point(16, 8))
            path.addEllipse(in: box(8.5, 10.5, 7, 7))
            path.addEllipse(in: box(17.1, 10.1, 1.8, 1.8))

        case .lens:
            path.addEllipse(in: box(3.5, 3.5, 17, 17))
            path.addEllipse(in: box(7, 7, 10, 10))
            path.addEllipse(in: box(10, 10, 4, 4))

        case .aperture:
            path.addEllipse(in: box(3.5, 3.5, 17, 17))
            path.move(to: point(12, 12)); path.addLine(to: point(8.3, 5.8))
            path.move(to: point(12, 12)); path.addLine(to: point(16.5, 6.6))
            path.move(to: point(12, 12)); path.addLine(to: point(19, 10.9))
            path.move(to: point(12, 12)); path.addLine(to: point(16.8, 17.1))
            path.move(to: point(12, 12)); path.addLine(to: point(10.2, 19))
            path.move(to: point(12, 12)); path.addLine(to: point(5.4, 15.4))
            path.addEllipse(in: box(10, 10, 4, 4))

        case .shutter:
            path.addEllipse(in: box(3.5, 3.5, 17, 17))
            path.move(to: point(12, 8))
            path.addLine(to: point(12, 12))
            path.addLine(to: point(15, 14))
            path.move(to: point(7, 4.5))
            path.addLine(to: point(5, 6.5))

        case .iso, .focalLength:
            break

        case .format:
            path.move(to: point(7, 3))
            path.addLine(to: point(14, 3))
            path.addLine(to: point(18, 7))
            path.addLine(to: point(18, 21))
            path.addLine(to: point(7, 21))
            path.addLine(to: point(7, 3))
            path.move(to: point(14, 3))
            path.addLine(to: point(14, 8))
            path.addLine(to: point(18, 8))
            path.move(to: point(9, 13)); path.addLine(to: point(15, 13))
            path.move(to: point(9, 17)); path.addLine(to: point(15, 17))

        case .shootTime:
            path.addPath(Path(roundedRect: box(4, 5, 16, 15), cornerRadius: side * 2 / 24))
            path.move(to: point(8, 3)); path.addLine(to: point(8, 7))
            path.move(to: point(16, 3)); path.addLine(to: point(16, 7))
            path.move(to: point(4, 9)); path.addLine(to: point(20, 9))
            path.addEllipse(in: box(9.2, 11.2, 5.6, 5.6))
            path.move(to: point(12, 12.8)); path.addLine(to: point(12, 14.4)); path.addLine(to: point(13.2, 15.2))

        case .gps:
            path.addEllipse(in: box(6, 6, 12, 12))
            path.addEllipse(in: box(10.5, 10.5, 3, 3))
            path.move(to: point(12, 2)); path.addLine(to: point(12, 6))
            path.move(to: point(12, 18)); path.addLine(to: point(12, 22))
            path.move(to: point(2, 12)); path.addLine(to: point(6, 12))
            path.move(to: point(18, 12)); path.addLine(to: point(22, 12))

        case .location:
            path.move(to: point(12, 21))
            path.addQuadCurve(to: point(6, 11), control: point(6, 17))
            path.addQuadCurve(to: point(12, 5), control: point(6, 6))
            path.addQuadCurve(to: point(18, 11), control: point(18, 6))
            path.addQuadCurve(to: point(12, 21), control: point(18, 17))
            path.addEllipse(in: box(9.8, 8.8, 4.4, 4.4))

        case .tags:
            path.move(to: point(3, 11))
            path.addLine(to: point(11, 3))
            path.addLine(to: point(18, 3))
            path.addLine(to: point(18, 10))
            path.addLine(to: point(10, 18))
            path.addLine(to: point(3, 11))
            path.addEllipse(in: box(13.5, 5.5, 2, 2))

        case .categories:
            path.addPath(Path(roundedRect: box(4, 4, 7, 7), cornerRadius: side * 1.5 / 24))
            path.addPath(Path(roundedRect: box(13, 4, 7, 7), cornerRadius: side * 1.5 / 24))
            path.addPath(Path(roundedRect: box(4, 13, 7, 7), cornerRadius: side * 1.5 / 24))
            path.addPath(Path(roundedRect: box(13, 13, 7, 7), cornerRadius: side * 1.5 / 24))
        }

        return path
    }
}
