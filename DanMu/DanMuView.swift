//
//  DanMuView.swift
//  DanMu
//
//  Created by 香饽饽zizizi on 2024/3/28.
//

import SwiftUI

struct DanMuView: View {
    @State var text = "Hello, World!"
    @State private var width: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.title.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: width)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: WidthKey.self, value: geo.size.width)
                }
            )
            .onPreferenceChange(WidthKey.self) { value in
                width = value
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false).delay(TimeInterval(Int.random(in: 0...10)))) {
                    width = -width
                }
            }
    }
}

struct WidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    DanMuView()
}
