//
//  PinchGestureOverlay.swift
//  journalcalendar
//
//  Attaches a UIPinchGestureRecognizer to the UIScrollView that
//  backs a SwiftUI ScrollView, enabling anchor-point pinch-to-zoom.
//

import SwiftUI
import UIKit

// MARK: - View Modifier

struct ScrollViewPinchZoom: ViewModifier {
    @Binding var hourHeight: CGFloat
    let minHourHeight: CGFloat
    let maxHourHeight: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay {
                ScrollViewPinchAttacher(
                    hourHeight: $hourHeight,
                    minHourHeight: minHourHeight,
                    maxHourHeight: maxHourHeight
                )
                .allowsHitTesting(false)
            }
    }
}

// MARK: - UIViewRepresentable

/// An invisible UIView that finds the nearest UIScrollView in its
/// ancestor hierarchy and attaches a UIPinchGestureRecognizer to it.
/// The recognizer lives on the scroll view itself, so there are no
/// touch-passthrough issues.
private struct ScrollViewPinchAttacher: UIViewRepresentable {
    @Binding var hourHeight: CGFloat
    let minHourHeight: CGFloat
    let maxHourHeight: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        context.coordinator.hourHeight = $hourHeight
        context.coordinator.minHourHeight = minHourHeight
        context.coordinator.maxHourHeight = maxHourHeight
        context.coordinator.anchorView = view
        
        // Wait for the view hierarchy to be fully established
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(from: view)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.hourHeight = $hourHeight
        context.coordinator.minHourHeight = minHourHeight
        context.coordinator.maxHourHeight = maxHourHeight
        
        // Retry attachment in case the hierarchy changed
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(from: uiView)
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var hourHeight: Binding<CGFloat>?
        var minHourHeight: CGFloat = 40
        var maxHourHeight: CGFloat = 240
        weak var anchorView: UIView?
        
        private var baseHourHeight: CGFloat = 120
        private var pinchAnchorContentY: CGFloat = 0
        private var pinchAnchorScreenY: CGFloat = 0
        private weak var scrollView: UIScrollView?
        private var isAttached = false
        
        func attachIfNeeded(from view: UIView) {
            guard !isAttached else { return }
            guard let sv = Self.findScrollView(from: view) else { return }
            
            scrollView = sv
            isAttached = true
            
            let pinch = UIPinchGestureRecognizer(
                target: self,
                action: #selector(handlePinch(_:))
            )
            pinch.delegate = self
            sv.addGestureRecognizer(pinch)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let scrollView = scrollView,
                  let hourHeight = hourHeight else { return }
            
            switch gesture.state {
            case .began:
                baseHourHeight = hourHeight.wrappedValue
                // Pinch location in the scroll view's content coordinate space
                let locationInScrollView = gesture.location(in: scrollView)
                pinchAnchorContentY = locationInScrollView.y
                // Screen Y = content Y minus scroll offset
                pinchAnchorScreenY = locationInScrollView.y - scrollView.contentOffset.y
                
            case .changed:
                let newHeight = min(
                    max(baseHourHeight * gesture.scale, minHourHeight),
                    maxHourHeight
                )
                
                // What fractional hour was under the fingers at gesture start
                let anchorFractionalHour = pinchAnchorContentY / baseHourHeight
                
                // Where that fractional hour lands at the new scale
                let newAnchorContentY = anchorFractionalHour * newHeight
                
                // Scroll offset to keep the anchor at the same screen Y
                let newOffset = newAnchorContentY - pinchAnchorScreenY
                let maxOffset = max(0, (24.0 * newHeight) - scrollView.bounds.height)
                let clampedOffset = min(max(newOffset, 0), maxOffset)
                
                hourHeight.wrappedValue = newHeight
                
                // Let SwiftUI resize the content, then reposition
                DispatchQueue.main.async {
                    scrollView.setContentOffset(
                        CGPoint(x: 0, y: clampedOffset),
                        animated: false
                    )
                }
                
            case .ended, .cancelled:
                baseHourHeight = hourHeight.wrappedValue
                
            default:
                break
            }
        }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }
        
        /// Walk up from the given view to find the nearest UIScrollView ancestor.
        private static func findScrollView(from view: UIView) -> UIScrollView? {
            var candidate: UIView? = view.superview
            while let current = candidate {
                if let sv = current as? UIScrollView {
                    return sv
                }
                candidate = current.superview
            }
            return nil
        }
    }
}

// MARK: - View Extension

extension View {
    func pinchToZoom(
        hourHeight: Binding<CGFloat>,
        min minHeight: CGFloat = 40,
        max maxHeight: CGFloat = 240
    ) -> some View {
        modifier(ScrollViewPinchZoom(
            hourHeight: hourHeight,
            minHourHeight: minHeight,
            maxHourHeight: maxHeight
        ))
    }
}
