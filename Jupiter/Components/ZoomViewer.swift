import SwiftUI

struct ZoomViewer: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            ZoomableImageView(url: url, zoomScale: .constant(1))
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(16)
            }
        }
    }
}

struct ZoomViewer_Previews: PreviewProvider {
    static var previews: some View {
        ZoomViewer(url: URL(string: "https://example.com"))
    }
}
