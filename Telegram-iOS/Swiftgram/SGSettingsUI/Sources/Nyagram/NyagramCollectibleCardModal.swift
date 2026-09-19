import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext
import OverlayStatusController

public func nyagramCollectibleCardModal(
    context: AccountContext,
    title: String,
    subtitle: String,
    tonPrice: Double,
    date: Date
) -> ViewController {
    var dismissImpl: (() -> Void)?
    let controller = AlertController(
        theme: AlertControllerTheme(presentationData: context.sharedContext.currentPresentationData.with { $0 }),
        contentNode: NyagramCardAlertContentNode(
            context: context,
            title: title,
            subtitle: subtitle,
            tonPrice: tonPrice,
            date: date,
            dismiss: {
                dismissImpl?()
            }
        )
    )
    dismissImpl = { [weak controller] in
        controller?.dismiss(animated: true)
    }
    return controller
}

private final class NyagramCardAlertContentNode: AlertContentNode {
    private let context: AccountContext
    private let titleText: String
    private let subtitleText: String
    private let tonPrice: Double
    private let date: Date
    private let dismissAction: (() -> Void)?
    
    private let containerNode: ASDisplayNode
    private let titleNode: ASTextNode
    private let subtitleNode: ASTextNode
    private let priceLabelNode: ASTextNode
    private let dateLabelNode: ASTextNode
    private let copyButton: HighlightTrackingButton
    
    init(
        context: AccountContext,
        title: String,
        subtitle: String,
        tonPrice: Double,
        date: Date,
        dismiss: (() -> Void)? = nil
    ) {
        self.context = context
        self.titleText = title
        self.subtitleText = subtitle
        self.tonPrice = tonPrice
        self.date = date
        self.dismissAction = dismiss
        
        self.containerNode = ASDisplayNode()
        self.titleNode = ASTextNode()
        self.subtitleNode = ASTextNode()
        self.priceLabelNode = ASTextNode()
        self.dateLabelNode = ASTextNode()
        self.copyButton = HighlightTrackingButton()
        
        super.init()
        
        self.addSubnode(self.containerNode)
        self.containerNode.addSubnode(self.titleNode)
        self.containerNode.addSubnode(self.subtitleNode)
        self.containerNode.addSubnode(self.priceLabelNode)
        self.containerNode.addSubnode(self.dateLabelNode)
        self.containerNode.view.addSubview(self.copyButton)
        
        let theme = context.sharedContext.currentPresentationData.with { $0 }.theme
        
        self.containerNode.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.containerNode.cornerRadius = 16.0
        
        self.titleNode.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .font: Font.bold(22.0),
                .foregroundColor: theme.list.itemPrimaryTextColor
            ]
        )
        
        self.subtitleNode.attributedText = NSAttributedString(
            string: subtitle,
            attributes: [
                .font: Font.regular(15.0),
                .foregroundColor: theme.list.itemAccentColor
            ]
        )
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateString = formatter.string(from: date)
        
        self.priceLabelNode.attributedText = NSAttributedString(
            string: "💎 \(tonPrice) TON",
            attributes: [
                .font: Font.semibold(17.0),
                .foregroundColor: theme.list.itemPrimaryTextColor
            ]
        )
        
        self.dateLabelNode.attributedText = NSAttributedString(
            string: dateString,
            attributes: [
                .font: Font.regular(14.0),
                .foregroundColor: theme.list.itemSecondaryTextColor
            ]
        )
        
        self.copyButton.setTitle(NyagramStrings.get(.copyLink), for: .normal)
        self.copyButton.setTitleColor(theme.list.itemCheckColors.foregroundColor, for: .normal)
        self.copyButton.backgroundColor = theme.list.itemCheckColors.fillColor
        self.copyButton.layer.cornerRadius = 12.0
        self.copyButton.titleLabel?.font = Font.semibold(16.0)
        
        self.copyButton.addTarget(self, action: #selector(self.copyPressed), for: .touchUpInside)
    }
    
    @objc private func copyPressed() {
        let clean = subtitleText.contains("http") ? subtitleText : "https://t.me/\(titleText.replacingOccurrences(of: "@", with: ""))"
        UIPasteboard.general.string = clean
        
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.prepare()
        feedback.impactOccurred()
        
        self.dismissAction?()
    }
    
    override func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) -> CGSize {
        let insets = UIEdgeInsets(top: 20.0, left: 16.0, bottom: 20.0, right: 16.0)
        let contentWidth = size.width - insets.left - insets.right
        
        let titleSize = self.titleNode.measure(CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
        let subSize = self.subtitleNode.measure(CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
        let priceSize = self.priceLabelNode.measure(CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
        let dateSize = self.dateLabelNode.measure(CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
        
        var y: CGFloat = 16.0
        self.titleNode.frame = CGRect(x: 16.0, y: y, width: contentWidth - 32.0, height: titleSize.height)
        y += titleSize.height + 6.0
        
        self.subtitleNode.frame = CGRect(x: 16.0, y: y, width: contentWidth - 32.0, height: subSize.height)
        y += subSize.height + 16.0
        
        self.priceLabelNode.frame = CGRect(x: 16.0, y: y, width: contentWidth - 32.0, height: priceSize.height)
        y += priceSize.height + 4.0
        
        self.dateLabelNode.frame = CGRect(x: 16.0, y: y, width: contentWidth - 32.0, height: dateSize.height)
        y += dateSize.height + 20.0
        
        self.copyButton.frame = CGRect(x: 16.0, y: y, width: contentWidth - 32.0, height: 44.0)
        y += 44.0 + 16.0
        
        self.containerNode.frame = CGRect(x: insets.left, y: 0.0, width: contentWidth, height: y)
        
        return CGSize(width: size.width, height: y + insets.top + insets.bottom)
    }
}
