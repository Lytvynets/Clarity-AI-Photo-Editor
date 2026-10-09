
import SwiftUI

struct BeforeAfterSlider: View {
    let before: UIImage
    let after: UIImage
    var transparent = false
    var autoReveal = true
    /// When true, only horizontal drags move the slider, so a vertical swipe on a tall photo
    /// still scrolls the page it sits in.
    var verticalScrollFriendly = false

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

            let content = ZStack(alignment: .leading) {
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

            interactive(content, width: width)
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

    @ViewBuilder
    private func interactive<Content: View>(_ content: Content, width: CGFloat) -> some View {
        if verticalScrollFriendly {
            content.overlay(
                HorizontalDragSurface(
                    onBegan: { isDragging = true },
                    onMove: { fraction in position = fraction },
                    onEnded: {
                        isDragging = false
                        Haptics.tap()
                    }
                )
            )
        } else {
            content
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


/// Transparent touch surface for the before/after slider. A horizontal drag (or a tap) moves the
/// slider; a vertical drag is ignored, so the enclosing ScrollView can scroll even when the photo
/// fills the whole screen.
struct HorizontalDragSurface: UIViewRepresentable {

    var onBegan: () -> Void
    var onMove: (CGFloat) -> Void
    var onEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        context.coordinator.surface = self
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.surface = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var surface: HorizontalDragSurface?

        private func fraction(of gesture: UIGestureRecognizer) -> CGFloat? {
            guard let view = gesture.view else { return nil }
            let width = max(view.bounds.width, 1)
            return min(1, max(0, gesture.location(in: view).x / width))
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let surface, let value = fraction(of: gesture) else { return }
            switch gesture.state {
            case .began:
                surface.onBegan()
                surface.onMove(value)
            case .changed:
                surface.onMove(value)
            case .ended, .cancelled, .failed:
                surface.onEnded()
            default:
                break
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let surface, let value = fraction(of: gesture) else { return }
            surface.onMove(value)
            Haptics.tap()
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
