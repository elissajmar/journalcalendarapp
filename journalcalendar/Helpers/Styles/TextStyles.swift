//
//  TextStyles.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/13/26.
//

import SwiftUI

// MARK: - Custom Fonts

extension Font {
    /// Heading style - Large, bold text for titles
    static var heading: Font {
        .system(size: 28, weight: .bold)
    }
    
    /// Paragraph 1 style - Primary body text
    static var paragraph1: Font {
        .system(size: 17, weight: .regular)
    }
    
    /// Paragraph 2 style - Secondary body text
    static var paragraph2: Font {
        .system(size: 15, weight: .regular)
    }
    
    /// Label style - Small text for captions and labels using Geist Mono
    static var label: Font {
        .custom("GeistMono-Regular", size: 13, relativeTo: .caption)
    }
}

// MARK: - Text Style Modifiers (Optional but powerful)

struct HeadingTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.heading)
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

struct Paragraph2TextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.paragraph2)
            .foregroundStyle(.secondary)
            .lineSpacing(2)
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

// MARK: - View Extensions for Easy Access

extension View {
    func headingStyle() -> some View {
        modifier(HeadingTextStyle())
    }
    
    func paragraph1Style() -> some View {
        modifier(Paragraph1TextStyle())
    }
    
    func paragraph2Style() -> some View {
        modifier(Paragraph2TextStyle())
    }
    
    func labelStyle() -> some View {
        modifier(LabelTextStyle())
    }
}

// MARK: - Custom Font Loading (if using custom font files)

/*
 If you want to use custom font files (.ttf or .otf):
 
 1. Add your font files to your Xcode project
 2. Add them to Info.plist under "Fonts provided by application"
 3. Update the font definitions above:
 
 extension Font {
     static var heading: Font {
         .custom("YourFontName-Bold", size: 28)
     }
     
     static var paragraph1: Font {
         .custom("YourFontName-Regular", size: 17)
     }
     
     static var paragraph2: Font {
         .custom("YourFontName-Regular", size: 15)
     }
     
     static var label: Font {
         .custom("YourFontName-Semibold", size: 13)
     }
 }
 
 To use with dynamic type (recommended):
 
 extension Font {
     static var heading: Font {
         .custom("YourFontName-Bold", size: 28, relativeTo: .largeTitle)
     }
     
     static var paragraph1: Font {
         .custom("YourFontName-Regular", size: 17, relativeTo: .body)
     }
     
     static var paragraph2: Font {
         .custom("YourFontName-Regular", size: 15, relativeTo: .callout)
     }
     
     static var label: Font {
         .custom("YourFontName-Semibold", size: 13, relativeTo: .caption)
     }
 }
 */
