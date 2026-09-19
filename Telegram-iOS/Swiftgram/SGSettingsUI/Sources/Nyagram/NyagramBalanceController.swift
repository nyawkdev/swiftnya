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

private final class NyagramBalanceArguments {
    let context: AccountContext
    let addStars: (Int64) -> Void
    let addGram: (Int64) -> Void
    let customStars: () -> Void
    let customGram: () -> Void
    let toggleSpendInMarket: (Bool) -> Void
    let resetBalance: () -> Void
    
    init(
        context: AccountContext,
        addStars: @escaping (Int64) -> Void,
        addGram: @escaping (Int64) -> Void,
        customStars: @escaping () -> Void,
        customGram: @escaping () -> Void,
        toggleSpendInMarket: @escaping (Bool) -> Void,
        resetBalance: @escaping () -> Void
    ) {
        self.context = context
        self.addStars = addStars
        self.addGram = addGram
        self.customStars = customStars
        self.customGram = customGram
        self.toggleSpendInMarket = toggleSpendInMarket
        self.resetBalance = resetBalance
    }
}

private enum NyagramBalanceSection: Int32 {
    case stars
    case gram
    case options
    case reset
}

private enum NyagramBalanceEntry: ItemListNodeEntry {
    case starsHeader(PresentationTheme, String)
    case starsCurrent(PresentationTheme, String, String)
    case starsAdd100(PresentationTheme, String)
    case starsAdd1000(PresentationTheme, String)
    case starsAdd10000(PresentationTheme, String)
    case starsCustom(PresentationTheme, String)
    
    case gramHeader(PresentationTheme, String)
    case gramCurrent(PresentationTheme, String, String)
    case gramAdd100(PresentationTheme, String)
    case gramAdd1000(PresentationTheme, String)
    case gramAdd10000(PresentationTheme, String)
    case gramCustom(PresentationTheme, String)
    
    case optionsHeader(PresentationTheme, String)
    case spendInMarket(PresentationTheme, String, Bool)
    case spendInMarketNotice(PresentationTheme, String)
    
    case reset(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .starsHeader, .starsCurrent, .starsAdd100, .starsAdd1000, .starsAdd10000, .starsCustom:
            return NyagramBalanceSection.stars.rawValue
        case .gramHeader, .gramCurrent, .gramAdd100, .gramAdd1000, .gramAdd10000, .gramCustom:
            return NyagramBalanceSection.gram.rawValue
        case .optionsHeader, .spendInMarket, .spendInMarketNotice:
            return NyagramBalanceSection.options.rawValue
        case .reset:
            return NyagramBalanceSection.reset.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .starsHeader: return 0
        case .starsCurrent: return 1
        case .starsAdd100: return 2
        case .starsAdd1000: return 3
        case .starsAdd10000: return 4
        case .starsCustom: return 5
        case .gramHeader: return 6
        case .gramCurrent: return 7
        case .gramAdd100: return 8
        case .gramAdd1000: return 9
        case .gramAdd10000: return 10
        case .gramCustom: return 11
        case .optionsHeader: return 12
        case .spendInMarket: return 13
        case .spendInMarketNotice: return 14
        case .reset: return 15
        }
    }
    
    static func ==(lhs: NyagramBalanceEntry, rhs: NyagramBalanceEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.starsHeader(lT, lTxt), .starsHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.starsCurrent(lT, lTxt, lVal), .starsCurrent(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.starsAdd100(lT, lTxt), .starsAdd100(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.starsAdd1000(lT, lTxt), .starsAdd1000(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.starsAdd10000(lT, lTxt), .starsAdd10000(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.starsCustom(lT, lTxt), .starsCustom(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.gramHeader(lT, lTxt), .gramHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.gramCurrent(lT, lTxt, lVal), .gramCurrent(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.gramAdd100(lT, lTxt), .gramAdd100(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.gramAdd1000(lT, lTxt), .gramAdd1000(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.gramAdd10000(lT, lTxt), .gramAdd10000(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.gramCustom(lT, lTxt), .gramCustom(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.optionsHeader(lT, lTxt), .optionsHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.spendInMarket(lT, lTxt, lVal), .spendInMarket(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.spendInMarketNotice(lT, lTxt), .spendInMarketNotice(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.reset(lT, lTxt), .reset(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        default:
            return false
        }
    }
    
    static func <(lhs: NyagramBalanceEntry, rhs: NyagramBalanceEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! NyagramBalanceArguments
        switch self {
        case let .starsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .starsCurrent(_, text, val):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: val, sectionId: self.section, style: .blocks, action: nil)
        case let .starsAdd100(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.addStars(100)
            })
        case let .starsAdd1000(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.addStars(1000)
            })
        case let .starsAdd10000(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.addStars(10000)
            })
        case let .starsCustom(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.customStars()
            })
        case let .gramHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .gramCurrent(_, text, val):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: val, sectionId: self.section, style: .blocks, action: nil)
        case let .gramAdd100(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.addGram(100)
            })
        case let .gramAdd1000(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.addGram(1000)
            })
        case let .gramAdd10000(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.addGram(10000)
            })
        case let .gramCustom(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.customGram()
            })
        case let .optionsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .spendInMarket(_, text, val):
            return ItemListSwitchItem(presentationData: presentationData, title: text, value: val, sectionId: self.section, style: .blocks, updated: { v in
                args.toggleSpendInMarket(v)
            })
        case let .spendInMarketNotice(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .reset(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.resetBalance()
            })
        }
    }
}

private func nyagramBalanceEntries(presentationData: PresentationData) -> [NyagramBalanceEntry] {
    var entries: [NyagramBalanceEntry] = []
    let theme = presentationData.theme
    let settings = NyagramSettings.shared
    
    // Stars
    entries.append(.starsHeader(theme, NyagramStrings.get(.starsBalance)))
    entries.append(.starsCurrent(theme, NyagramStrings.get(.balanceTitle), "\(settings.starsBalance) ⭐️"))
    entries.append(.starsAdd100(theme, "+100 ⭐️"))
    entries.append(.starsAdd1000(theme, "+1 000 ⭐️"))
    entries.append(.starsAdd10000(theme, "+10 000 ⭐️"))
    entries.append(.starsCustom(theme, "✏️ " + NyagramStrings.get(.customAmount)))
    
    // GRAM
    entries.append(.gramHeader(theme, NyagramStrings.get(.gramBalance)))
    entries.append(.gramCurrent(theme, NyagramStrings.get(.balanceTitle), "\(settings.gramBalance) GRAM"))
    entries.append(.gramAdd100(theme, "+100 GRAM"))
    entries.append(.gramAdd1000(theme, "+1 000 GRAM"))
    entries.append(.gramAdd10000(theme, "+10 000 GRAM"))
    entries.append(.gramCustom(theme, "✏️ " + NyagramStrings.get(.customAmount)))
    
    // Options
    entries.append(.optionsHeader(theme, NyagramStrings.get(.spendInMarket)))
    entries.append(.spendInMarket(theme, NyagramStrings.get(.spendInMarket), settings.spendStarsInMarket))
    entries.append(.spendInMarketNotice(theme, NyagramStrings.get(.spendInMarketSub)))
    
    // Reset
    entries.append(.reset(theme, NyagramStrings.get(.resetBalance)))
    
    return entries
}

public func nyagramBalanceController(context: AccountContext) -> ViewController {
    let updatedState = ValuePromise<Bool>(true, ignoreRepeated: false)
    
    let arguments = NyagramBalanceArguments(
        context: context,
        addStars: { amount in
            let settings = NyagramSettings.shared
            settings.starsBalance += amount
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()
            updatedState.set(true)
        },
        addGram: { amount in
            let settings = NyagramSettings.shared
            settings.gramBalance += amount
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()
            updatedState.set(true)
        },
        customStars: {
            let settings = NyagramSettings.shared
            let alert = UIAlertController(
                title: NyagramStrings.get(.starsBalance),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.placeholder = "Stars"
                tf.keyboardType = .numberPad
                tf.text = "\(settings.starsBalance)"
            }
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.save), style: .default, handler: { _ in
                if let t = alert.textFields?.first?.text, let val = Int64(t) {
                    settings.starsBalance = val
                    updatedState.set(true)
                }
            }))
            context.sharedContext.applicationBindings.presentNativeController(alert)
        },
        customGram: {
            let settings = NyagramSettings.shared
            let alert = UIAlertController(
                title: NyagramStrings.get(.gramBalance),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.placeholder = "GRAM"
                tf.keyboardType = .numberPad
                tf.text = "\(settings.gramBalance)"
            }
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.save), style: .default, handler: { _ in
                if let t = alert.textFields?.first?.text, let val = Int64(t) {
                    settings.gramBalance = val
                    updatedState.set(true)
                }
            }))
            context.sharedContext.applicationBindings.presentNativeController(alert)
        },
        toggleSpendInMarket: { val in
            NyagramSettings.shared.spendStarsInMarket = val
            updatedState.set(true)
        },
        resetBalance: {
            NyagramSettings.shared.starsBalance = 0
            NyagramSettings.shared.gramBalance = 0
            let feedback = UINotificationFeedbackGenerator()
            feedback.prepare()
            feedback.notificationOccurred(.warning)
            updatedState.set(true)
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, updatedState.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, NyagramBalanceArguments)) in
        let entries = nyagramBalanceEntries(presentationData: presentationData)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(NyagramStrings.get(.balanceTitle)),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
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
    
    return controller
}
