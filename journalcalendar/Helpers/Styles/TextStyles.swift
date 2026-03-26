//
//  TextStyles.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/13/26.
//

import SwiftUI

// MARK: - Custom Fonts

extension Font {
    /// Heading 2 - Page/section headers (e.g. date in calendar header)
    static var heading2: Font {
        .system(size: 24, weight: .regular)
    }
    
    /// Heading 3 - Content titles (e.g. event title in detail/edit views)
    static var heading3: Font {
        .system(size: 18, weight: .regular)
    }
    
    /// Paragraph 1 - Primary body text (e.g. event titles in blocks, journal text)
    static var paragraph1: Font {
        .system(size: 14, weight: .regular)
    }
    
    /// Label - Small text for captions, labels, and buttons using Geist Mono
    static var label: Font {
        .custom("GeistMono-Regular", size: 13, relativeTo: .caption)
    }
}

// MARK: - Text Style Modifiers

struct Heading2TextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.heading2)
            .foregroundStyle(.primary)
    }
}

struct Heading3TextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.heading3)
            .foregroundStyle(.primary)
    }
}

struct Paragraph1TextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.paragraph1)
            .foregroundStyle(.primary)
            .lineSpacing(4)
    }
}

struct LabelTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.label)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - View Extensions

extension View {
    func heading2Style() -> some View {
        modifier(Heading2TextStyle())
    }
    
    func heading3Style() -> some View {
        modifier(Heading3TextStyle())
    }
    
    func paragraph1Style() -> some View {
        modifier(Paragraph1TextStyle())
    }
    
    func labelStyle() -> some View {
        modifier(LabelTextStyle())
    }
}
