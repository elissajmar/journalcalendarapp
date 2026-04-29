//
//  ImageViewer.swift
//  journalcalendar
//
//  Fullscreen image viewer with fade + scale animation.
//

import SwiftUI

struct ImageViewer: View {
    @Environment(\.dismiss) var dismiss
    let data: Data?
    
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Blurred background — tap to dismiss
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        appeared = false
                    } completion: {
                        dismiss()
                    }
                }
            
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(24)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .background(ClearBackground())
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                appeared = true
            }
        }
    }
}

// Removes the default fullScreenCover background
private struct ClearBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = InnerView()
        DispatchQueue.main.async {
            if let parentView = view.superview?.superview {
                parentView.backgroundColor = .clear
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private class InnerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }
}
