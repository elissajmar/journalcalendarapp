//
//  OutlineBrownButtonStyle.swift
//  journalcalendar
//

import SwiftUI

struct OutlineBrownButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(Color("ButtonPrimary"))
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color("ButtonPrimary"), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension ButtonStyle where Self == OutlineBrownButtonStyle {
    static var outlineBrown: OutlineBrownButtonStyle { OutlineBrownButtonStyle() }
}
