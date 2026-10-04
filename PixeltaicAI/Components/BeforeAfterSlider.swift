
import SwiftUI

struct BeforeAfterSlider: View {
    let before: UIImage
    let after: UIImage
    var transparent = false
    var autoReveal = true

    @State private var position: CGFloat = 0.5
    @State private var didIntro = false
    @State private var isDragging = false

    private var aspect: CGFloat {
        let ratio = after.size.width / max(after.size.height, 1)
        return min(max(ratio, 0.5), 2.0)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack(alignment: .leading) {
                if transparent {
                    CheckerboardView()
                        .frame(width: width, height: height)
                }

                Image(uiImage: after)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)

                Image(uiImage: before)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: max(0, width * position))
                    }

                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: height)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .offset(x: width * position - 1)

                ZStack {
                    Circle().fill(Color.white)
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: 0x2A1B4D))
                }
                .frame(width: 40, height: 40)
                .scaleEffect(isDragging ? 1.12 : 1)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 3)
                .offset(x: width * position - 20)

                VStack {
                    HStack {
                        label("Before")
                            .opacity(position > 0.16 ? 1 : 0)
                        Spacer()
                        label("After")
                            .opacity(position < 0.84 ? 1 : 0)
                    }
                    .padding(12)
                    Spacer()
                }
                .frame(width: width, height: height)
                .allowsHitTesting(false)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let fraction = value.location.x / max(width, 1)
                        position = min(1, max(0, fraction))
                    }
                    .onEnded { _ in
                        isDragging = false
                        Haptics.tap()
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .aspectRatio(aspect, contentMode: .fit)
        .onAppear {
            guard autoReveal, !didIntro else { return }
            didIntro = true
            position = 0.05
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                position = 0.5
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundColor(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .animation(.easeOut(duration: 0.15), value: position)
    }
}


struct ImageCanvas: View {
    let image: UIImage
    var transparent = false

    private var aspect: CGFloat {
        let ratio = image.size.width / max(image.size.height, 1)
        return min(max(ratio, 0.5), 2.0)
    }

    var body: some View {
        ZStack {
            if transparent { CheckerboardView() }
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }
}
