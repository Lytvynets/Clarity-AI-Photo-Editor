
import SwiftUI

struct ProcessingView: View {
    let image: UIImage?
    let status: String
    var onCancel: () -> Void

    @State private var sweep = false
    @State private var pulse = false

    private let tips = [
        "Analyzing your photo…",
        "Rendering fine details…",
        "Balancing light and color…",
        "Polishing the edges…",
        "Almost there…"
    ]

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)

            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .blur(radius: 5)
                        .saturation(0.7)
                        .opacity(0.65)
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .aspectRatio(1, contentMode: .fit)
                }

                GeometryReader { geo in
                    LinearGradient(colors: [.clear, Theme.fuchsia.opacity(0.85), Theme.violet.opacity(0.4), .clear],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 110)
                        .offset(y: sweep ? geo.size.height : -110)
                        .blendMode(.plusLighter)
                }
                .allowsHitTesting(false)

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
                    .scaleEffect(pulse ? 1.15 : 0.9)
                    .shadow(color: Theme.fuchsia, radius: pulse ? 18 : 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.brandGradient, lineWidth: 1.5)
                    .opacity(pulse ? 1 : 0.4)
            )
            .padding(.horizontal, 28)

            VStack(spacing: 6) {
                Text(status.isEmpty ? "Working on it…" : status)
                    .font(.app(.headline, weight: .semibold))
                    .foregroundColor(.white)
                    .id(status)
                    .transition(.opacity)

                TimelineView(.periodic(from: Date(), by: 2.6)) { context in
                    let index = Int(context.date.timeIntervalSince1970 / 2.6) % tips.count
                    Text(tips[index])
                        .font(.app(.subheadline))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: status)

            Button {
                Haptics.tap()
                onCancel()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(SecondaryButtonStyle())
            .frame(width: 160)

            Spacer(minLength: 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: false)) {
                sweep = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
