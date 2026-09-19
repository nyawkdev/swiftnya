import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import OverlayStatusController

private final class NyagramWalletArguments {
    let context: AccountContext
    let editCoin: (String) -> Void
    let save: () -> Void
    let reset: () -> Void
    
    init(
        context: AccountContext,
        editCoin: @escaping (String) -> Void,
        save: @escaping () -> Void,
        reset: @escaping () -> Void
    ) {
        self.context = context
        self.editCoin = editCoin
        self.save = save
        self.reset = reset
    }
}

private enum NyagramWalletSection: Int32 {
    case coins
    case actions
}

private enum NyagramWalletEntry: ItemListNodeEntry {
    case coinsHeader(PresentationTheme, String)
    case coinItem(Int32, PresentationTheme, String, Double)
    case saveButton(PresentationTheme, String)
    case resetButton(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .coinsHeader, .coinItem:
            return NyagramWalletSection.coins.rawValue
        case .saveButton, .resetButton:
            return NyagramWalletSection.actions.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .coinsHeader: return 0
        case let .coinItem(idx, _, _, _): return 1 + idx
        case .saveButton: return 100
        case .resetButton: return 101
        }
    }
    
    static func ==(lhs: NyagramWalletEntry, rhs: NyagramWalletEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.coinsHeader(lT, lTxt), .coinsHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.coinItem(lIdx, lT, lSym, lVal), .coinItem(rIdx, rT, rSym, rVal)):
            return lIdx == rIdx && lT === rT && lSym == rSym && lVal == rVal
        case let (.saveButton(lT, lTxt), .saveButton(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.resetButton(lT, lTxt), .resetButton(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        default:
            return false
        }
    }
    
    static func <(lhs: NyagramWalletEntry, rhs: NyagramWalletEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! NyagramWalletArguments
        switch self {
        case let .coinsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .coinItem(_, _, symbol, value):
            let formatted: String
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                formatted = String(format: "%.0f", value)
            } else {
                formatted = String(format: "%.4f", value)
            }
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: symbol,
                label: "\(formatted) \(symbol)",
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.editCoin(symbol)
                }
            )
        case let .saveButton(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.save()
                }
            )
        case let .resetButton(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .destructive,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.reset()
                }
            )
        }
    }
}

private let walletCoinList = ["TON", "USDT", "BTC", "NOT", "DOGE", "TRX", "ETH", "SOL"]

private func nyagramWalletEntries(presentationData: PresentationData, balances: [String: Double]) -> [NyagramWalletEntry] {
    var entries: [NyagramWalletEntry] = []
    let theme = presentationData.theme
    
    entries.append(.coinsHeader(theme, NyagramStrings.get(.walletSecretTitle)))
    
    for (index, coin) in walletCoinList.enumerated() {
        let val = balances[coin] ?? 0.0
        entries.append(.coinItem(Int32(index), theme, coin, val))
    }
    
    entries.append(.saveButton(theme, "💾 " + NyagramStrings.get(.save)))
    entries.append(.resetButton(theme, NyagramStrings.get(.resetBalance)))
    
    return entries
}

public func nyagramWalletBalanceController(
    context: AccountContext,
    onSaved: @escaping ([String: Double]) -> Void
) -> ViewController {
    let balancesPromise = ValuePromise<[String: Double]>(NyagramSettings.shared.walletBalances, ignoreRepeated: false)
    let balancesValue = Atomic<[String: Double]>(value: NyagramSettings.shared.walletBalances)
    var dismissImpl: (() -> Void)?
    
    let arguments = NyagramWalletArguments(
        context: context,
        editCoin: { coin in
            let currentVal = balancesValue.with { $0[coin] ?? 0.0 }
            let alert = UIAlertController(
                title: "\(coin)",
                message: "Enter custom balance for \(coin):",
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.keyboardType = .decimalPad
                tf.text = "\(currentVal)"
            }
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.save), style: .default, handler: { _ in
                if let t = alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: "."), let v = Double(t) {
                    let updated = balancesValue.modify { dict in
                        var d = dict
                        d[coin] = max(0, v)
                        return d
                    }
                    balancesPromise.set(updated)
                }
            }))
            context.sharedContext.applicationBindings.presentNativeController(alert)
        },
        save: {
            let finalBalances = balancesValue.with { $0 }
            NyagramSettings.shared.walletBalances = finalBalances
            
            let feedback = UINotificationFeedbackGenerator()
            feedback.prepare()
            feedback.notificationOccurred(.success)
            
            onSaved(finalBalances)
            dismissImpl?()
        },
        reset: {
            let defaults = NyagramSettings.defaultWalletBalances
            let _ = balancesValue.swap(defaults)
            balancesPromise.set(defaults)
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, balancesPromise.get())
    |> map { presentationData, balances -> (ItemListControllerState, (ItemListNodeState, NyagramWalletArguments)) in
        let entries = nyagramWalletEntries(presentationData: presentationData, balances: balances)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(NyagramStrings.get(.walletSecretTitle)),
            leftNavigationButton: nil,
            rightNavigationButton: ItemListNavigationButton(content: .text(NyagramStrings.get(.done)), style: .bold, enabled: true, action: {
                arguments.save()
            }),
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks
        )
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    
    return controller
}
