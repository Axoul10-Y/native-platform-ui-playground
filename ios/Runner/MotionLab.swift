import SwiftUI

struct MotionLab: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glass
    @Namespace private var zoom
    @State private var expanded = false
    @State private var favorite = false
    @State private var zoomed = false
    @State private var phase = false
    @State private var replay = 0
    @State private var spring = "Smooth"
    private var animation: Animation {
        switch spring {
        case "Snappy": return .snappy
        case "Bouncy": return .bouncy
        default: return .smooth
        }
    }

    var body: some View {
        List {
            Section {
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 14) {
                        glyph("square.and.pencil", id: "pencil")
                        if expanded {
                            glyph("highlighter", id: "marker")
                            glyph("eraser", id: "eraser")
                        }
                    }.padding(.vertical, 10)
                }
                Button(expanded ? "Collapse tools" : "Expand tools") {
                    withAnimation(reduceMotion ? nil : .bouncy) { expanded.toggle() }
                }
            } header: { Text("Glass morph") }
            Section("Symbol replacement") {
                Button {
                    withAnimation(reduceMotion ? nil : .default) { favorite.toggle() }
                } label: {
                    HStack {
                        Image(systemName: favorite ? "heart.fill" : "heart")
                            .contentTransition(.symbolEffect(.replace))
                        Text(favorite ? "Remove Favorite" : "Add Favorite")
                    }
                }
            }
            Section("Spring response") {
                Picker("Spring", selection: $spring) {
                    ForEach(["Smooth", "Snappy", "Bouncy"], id: \.self) { Text($0) }
                }.pickerStyle(.segmented)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.quaternary).frame(height: 4)
                        Circle().fill(Color.accentColor).frame(width: 26)
                            .offset(x: phase ? max(0, geometry.size.width - 26) : 0)
                    }.frame(maxHeight: .infinity)
                }.frame(height: 42).accessibilityHidden(true)
                Button("Run spring", systemImage: "play") {
                    withAnimation(reduceMotion ? nil : animation) { phase.toggle() }
                }
            }
            Section("Keyframes") {
                HStack {
                    Image(systemName: "bell")
                        .keyframeAnimator(initialValue: 0.0, trigger: replay) { content, angle in
                            content.rotationEffect(.degrees(reduceMotion ? 0 : angle))
                        } keyframes: { _ in
                            CubicKeyframe(-14.0, duration: 0.12)
                            CubicKeyframe(12.0, duration: 0.16)
                            CubicKeyframe(-6.0, duration: 0.12)
                            CubicKeyframe(0.0, duration: 0.14)
                        }
                    Button("Ring bell") { replay += 1 }
                }
            }
            Section("Zoom transition") {
                Button { zoomed = true } label: {
                    Label("Open map preview", systemImage: "map.fill")
                        .matchedTransitionSource(id: "map", in: zoom)
                }.fullScreenCover(isPresented: $zoomed) {
                    VStack(spacing: 22) {
                        Image(systemName: "map.fill").font(.system(size: 82)).foregroundStyle(.blue)
                        Text("Map preview").font(.title.bold())
                        Button("Done") { zoomed = false }.buttonStyle(.glass)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                     .navigationTransition(.zoom(sourceID: "map", in: zoom))
                }
            }
        }
    }

    private func glyph(_ symbol: String, id: String) -> some View {
        Image(systemName: symbol)
            .font(.title2)
            .frame(width: 48, height: 48)
            .glassEffect(.regular, in: .circle)
            .glassEffectID(id, in: glass)
            .glassEffectTransition(.matchedGeometry)
            .accessibilityHidden(true)
    }
}
