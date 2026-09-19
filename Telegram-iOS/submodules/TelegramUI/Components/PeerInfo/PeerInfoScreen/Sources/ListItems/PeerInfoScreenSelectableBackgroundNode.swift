import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData

final class PeerInfoScreenSelectableBackgroundNode: ASDisplayNode {
    private let backgroundNode: ASDisplayNode
    private let button: HighlightTrackingButton
    
    let bringToFrontForHighlight: () -> Void
    
    private var isHighlighted: Bool = false
    
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    var longPressed: (() -> Void)? {
        didSet {
            if self.longPressed != nil {
                if self.longPressGestureRecognizer == nil {
                    let gesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
                    gesture.minimumPressDuration = 0.5
                    self.longPressGestureRecognizer = gesture
                    self.button.addGestureRecognizer(gesture)
                }
            } else if let gesture = self.longPressGestureRecognizer {
                self.button.removeGestureRecognizer(gesture)
                self.longPressGestureRecognizer = nil
            }
        }
    }
    
    var pressed: (() -> Void)? {
        didSet {
            self.button.isUserInteractionEnabled = self.pressed != nil || self.longPressed != nil
        }
    }
    
    init(bringToFrontForHighlight: @escaping () -> Void) {
        self.bringToFrontForHighlight = bringToFrontForHighlight
        
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.alpha = 0.0
        
        self.button = HighlightTrackingButton()
        self.button.isAccessibilityElement = false
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
        self.view.addSubview(self.button)
        
        self.button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        self.button.highligthedChanged = { [weak self] highlighted in
            self?.updateIsHighlighted(highlighted)
        }
    }
    
    @objc private func buttonPressed() {
        self.pressed?()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()
            self.longPressed?()
        }
    }
    
    func updateIsHighlighted(_ isHighlighted: Bool) {
        if self.isHighlighted != isHighlighted {
            self.isHighlighted = isHighlighted
            if isHighlighted {
                self.bringToFrontForHighlight()
                self.backgroundNode.layer.removeAnimation(forKey: "opacity")
                self.backgroundNode.alpha = 1.0
            } else {
                self.backgroundNode.alpha = 0.0
                self.backgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25)
            }
        }
    }
    
    func update(size: CGSize, theme: PresentationTheme, transition: ContainedViewLayoutTransition) {
        self.backgroundNode.backgroundColor = theme.list.itemHighlightedBackgroundColor
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(), size: size))
        transition.updateFrame(view: self.button, frame: CGRect(origin: CGPoint(), size: size))
    }
}
