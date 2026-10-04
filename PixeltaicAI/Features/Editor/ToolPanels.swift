

import SwiftUI

struct ToolPanel: View {
    @ObservedObject var vm: EditorViewModel
    let isPro: Bool
    var onLocked: () -> Void

    var body: some View {
        switch vm.tool {
        case .enhance:
            EnhancePanel(vm: vm, isPro: isPro, onLocked: onLocked)
        case .background:
            BackgroundPanel(vm: vm)
        case .blur:
            BlurPanel(vm: vm)
        case .magic:
            MagicPanel(vm: vm)
        case .color:
            ColorPanel(vm: vm)
        case .resize:
            ResizePanel(vm: vm)
        case .create:
            EmptyView()
        }
    }
}


private struct PanelFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.app(.body))
            .foregroundColor(Theme.textPrimary)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

private extension View {
    func panelField() -> some View { modifier(PanelFieldStyle()) }
}


struct EnhancePanel: View {
    @ObservedObject var vm: EditorViewModel
    let isPro: Bool
    var onLocked: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Enhancer")
                OptionRow(items: modeItems, selection: $vm.enhance.mode)
                if let hint = vm.faceHint {
                    Label(hint, systemImage: "face.smiling")
                        .font(.app(.caption, weight: .semibold))
                        .foregroundColor(Theme.mint)
                } else {
                    Text(vm.enhance.mode.detail)
                        .font(.app(.caption))
                        .foregroundColor(Theme.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Size", hint: vm.enhanceOutputText.map { "→ \($0)" })
                OptionRow(items: sizeItems, selection: $vm.enhance.scale, onLockedTap: onLocked)
            }

            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Remove compression noise")
                OptionRow(items: denoiseItems, selection: $vm.enhance.denoise)
            }

            Toggle(isOn: $vm.enhance.polish) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sharpen details")
                        .font(.app(.subheadline, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Redraws soft areas while keeping the structure")
                        .font(.app(.caption))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .tint(Theme.violet)
        }
    }

    private var modeItems: [OptionItem<UpscaleMode>] {
        UpscaleMode.allCases.map { OptionItem(title: $0.title, value: $0) }
    }

    private var sizeItems: [OptionItem<Int>] {
        [
            OptionItem(title: "Restore only", value: 1),
            OptionItem(title: "2× bigger", value: 2),
            OptionItem(title: "4× bigger", value: 4, locked: !isPro)
        ]
    }

    private var denoiseItems: [OptionItem<DenoiseLevel>] {
        DenoiseLevel.allCases.map { OptionItem(title: $0.title, value: $0) }
    }
}


struct BackgroundPanel: View {
    @ObservedObject var vm: EditorViewModel

    private let swatches: [Color] = [
        .white, Color(hex: 0xF1F1F5), .black, Theme.violet, Theme.pink,
        Theme.gold, Theme.mint, Theme.blue
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Result")
                OptionRow(items: resultItems, selection: $vm.background.transparent)
            }

            if !vm.background.transparent {
                VStack(alignment: .leading, spacing: 8) {
                    PanelLabel(text: "Background color")
                    swatchRow
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Subject")
                OptionRow(items: categoryItems, selection: $vm.background.category)
                    .opacity(vm.background.keepOnly.trimmed.isEmpty ? 1 : 0.4)
                TextField("Keep only… (e.g. dog, shoe, person)", text: $vm.background.keepOnly)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .panelField()
            }

            SliderRow(title: "Space around subject",
                      value: $vm.background.padding,
                      range: 0...30,
                      step: 1,
                      suffix: "%")
        }
        .animation(.easeInOut(duration: 0.25), value: vm.background.transparent)
    }

    private var resultItems: [OptionItem<Bool>] {
        [
            OptionItem(title: "Transparent", value: true, icon: "square.dashed"),
            OptionItem(title: "Solid color", value: false, icon: "paintpalette.fill")
        ]
    }

    private var categoryItems: [OptionItem<SubjectCategory>] {
        SubjectCategory.allCases.map { OptionItem(title: $0.title, value: $0) }
    }

    private var swatchRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(swatches.enumerated()), id: \.offset) { _, swatch in
                    Button {
                        Haptics.select()
                        vm.background.color = swatch
                    } label: {
                        Circle()
                            .fill(swatch)
                            .frame(width: 34, height: 34)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                            .overlay(
                                Circle()
                                    .strokeBorder(Theme.fuchsia, lineWidth: 3)
                                    .padding(-4)
                                    .opacity(vm.background.color == swatch ? 1 : 0)
                            )
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                }
                ColorPicker("", selection: $vm.background.color, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding(6)
        }
    }
}


struct BlurPanel: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Style")
                OptionRow(items: styleItems, selection: $vm.blur.style)
                Text(vm.blur.style == .lens
                     ? "Realistic camera-lens bokeh with soft highlights."
                     : "Smooth, even blur behind the subject.")
                    .font(.app(.caption))
                    .foregroundColor(Theme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Strength")
                OptionRow(items: levelItems, selection: $vm.blur.level)
            }

            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Subject")
                OptionRow(items: categoryItems, selection: $vm.blur.category)
            }
        }
    }

    private var styleItems: [OptionItem<BlurStyle>] {
        BlurStyle.allCases.map { OptionItem(title: $0.title, value: $0) }
    }

    private var levelItems: [OptionItem<BlurLevel>] {
        BlurLevel.allCases.map { OptionItem(title: $0.title, value: $0) }
    }

    private var categoryItems: [OptionItem<SubjectCategory>] {
        SubjectCategory.allCases.map { OptionItem(title: $0.title, value: $0) }
    }
}


struct MagicPanel: View {
    @ObservedObject var vm: EditorViewModel

    private let ideas = [
        "Add sunglasses",
        "Make it snowy",
        "Golden hour lighting",
        "Turn into a watercolor painting",
        "Change the background to a beach",
        "Make it nighttime",
        "Add a rainbow in the sky",
        "Vintage film look"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Describe the change")
                TextField("e.g. add sunglasses, make it snowy…", text: $vm.magicPrompt, axis: .vertical)
                    .lineLimit(2...5)
                    .panelField()
                HStack {
                    Spacer()
                    Text("\(vm.magicPrompt.count)/500")
                        .font(.app(.caption))
                        .foregroundColor(Theme.textTertiary)
                        .monospacedDigit()
                }
            }
            .onChange(of: vm.magicPrompt) { text in
                if text.count > 500 { vm.magicPrompt = String(text.prefix(500)) }
            }

            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Ideas")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ideas, id: \.self) { idea in
                            Chip(title: idea, icon: "sparkle", selected: vm.magicPrompt == idea) {
                                vm.magicPrompt = idea
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            Text("Short, specific instructions work best. Your subject and composition stay the same.")
                .font(.app(.caption))
                .foregroundColor(Theme.textTertiary)
        }
    }
}


struct ColorPanel: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                PanelLabel(text: "Presets")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ColorPreset.all) { preset in
                            Chip(title: preset.title, icon: preset.icon, selected: vm.color == preset.params) {
                                vm.color = preset.params
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            SliderRow(title: "AI HDR", value: $vm.color.hdr, range: 0...100)
            SliderRow(title: "Exposure", value: $vm.color.exposure, range: -100...100)
            SliderRow(title: "Contrast", value: $vm.color.contrast, range: -100...100)
            SliderRow(title: "Saturation", value: $vm.color.saturation, range: -100...100)
            SliderRow(title: "Sharpness", value: $vm.color.sharpness, range: 0...100)

            if !vm.color.isNeutral {
                Button {
                    Haptics.tap()
                    withAnimation { vm.color = ColorParams() }
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.app(.footnote, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}


struct ResizePanel: View {
    @ObservedObject var vm: EditorViewModel

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OptionRow(items: modeItems, selection: $vm.resize.mode)

            switch vm.resize.mode {
            case .preset:
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ResizePreset.all) { preset in
                        presetCard(preset)
                    }
                }
            case .custom:
                HStack(spacing: 12) {
                    dimensionField(title: "Width", text: $vm.resize.widthText)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                    dimensionField(title: "Height", text: $vm.resize.heightText)
                }
                Text("Leave one side empty to keep the proportions.")
                    .font(.app(.caption))
                    .foregroundColor(Theme.textTertiary)
            case .percent:
                SliderRow(title: "Scale", value: $vm.resize.percent, range: 25...400, step: 5, suffix: "%")
            }

            if vm.resize.mode != .percent {
                VStack(alignment: .leading, spacing: 8) {
                    PanelLabel(text: "When proportions differ")
                    OptionRow(items: fitItems, selection: $vm.resize.fit)
                    Text(vm.resize.fit.detail)
                        .font(.app(.caption))
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.resize.mode)
    }

    private var modeItems: [OptionItem<ResizeMode>] {
        ResizeMode.allCases.map { OptionItem(title: $0.title, value: $0) }
    }

    private var fitItems: [OptionItem<ResizeFit>] {
        ResizeFit.allCases.map { OptionItem(title: $0.title, value: $0, icon: $0.icon) }
    }

    private func presetCard(_ preset: ResizePreset) -> some View {
        let selected = vm.resize.preset == preset
        let ratio = preset.ratio
        let shapeWidth = 24 * min(1, ratio)
        let shapeHeight = 24 * min(1, 1 / ratio)

        return Button {
            Haptics.select()
            vm.resize.preset = preset
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(selected ? Color.white : Theme.textSecondary, lineWidth: 1.6)
                        .frame(width: shapeWidth, height: shapeHeight)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.name)
                        .font(.app(.footnote, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(preset.sizeLabel)
                        .font(.app(.caption2))
                        .foregroundColor(selected ? Color.white.opacity(0.85) : Theme.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.white.opacity(0.07)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? Color.white.opacity(0.3) : Theme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle(scale: 0.97))
    }

    private func dimensionField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.app(.caption, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            TextField("auto", text: text)
                .keyboardType(.numberPad)
                .panelField()
                .onChange(of: text.wrappedValue) { value in
                    let digits = value.filter { $0.isNumber }
                    let clipped = String(digits.prefix(4))
                    if clipped != value { text.wrappedValue = clipped }
                }
        }
        .frame(maxWidth: .infinity)
    }
}
