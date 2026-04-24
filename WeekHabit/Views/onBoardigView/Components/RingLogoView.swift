
import SwiftUI


import SwiftUI

struct RippleLogoView: View {
    let rings = [1.0, 0.82, 0.65, 0.50, 0.37]
    let baseSize: CGFloat = 240

    @State private var isExpanded = false
    @State private var flameScale: CGFloat = 1.0

    var body: some View {
        VStack {
            ZStack {
                ForEach(rings.indices, id: \.self) { i in
                    Circle()
                        .stroke(Color(hex: "#c2573c"), lineWidth: 1.5)
                        .frame(
                            width: baseSize * rings[i] * (isExpanded ? 1.06 : 1.0),
                            height: baseSize * rings[i] * (isExpanded ? 1.06 : 1.0)
                        )
                        .opacity(Double(rings.count - i + 1) * 0.14)
                }

                Circle()
                    .fill(Color(hex: "#c2573c"))
                    .frame(width: 68, height: 68)

                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(flameScale)
            }
            .frame(width: baseSize, height: baseSize)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 3.5).repeatForever(autoreverses: true)
                ) {
                    isExpanded = true
                    flameScale = 1.12
                }
            }
        }
    }
}

#Preview {
    RippleLogoView()
}
