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

private final class NyagramProfileArguments {
    let context: AccountContext
    let toggleHideRegularGifts: (Bool) -> Void
    let editUsername: () -> Void
    let previewUsername: () -> Void
    let editNumber: () -> Void
    let previewNumber: () -> Void
    let editRating: () -> Void
    let editPinnedChannel: () -> Void
    let openPinnedChannel: () -> Void
    
    init(
        context: AccountContext,
        toggleHideRegularGifts: @escaping (Bool) -> Void,
        editUsername: @escaping () -> Void,
        previewUsername: @escaping () -> Void,
        editNumber: @escaping () -> Void,
        previewNumber: @escaping () -> Void,
        editRating: @escaping () -> Void,
        editPinnedChannel: @escaping () -> Void,
        openPinnedChannel: @escaping () -> Void
    ) {
        self.context = context
        self.toggleHideRegularGifts = toggleHideRegularGifts
        self.editUsername = editUsername
        self.previewUsername = previewUsername
        self.editNumber = editNumber
        self.previewNumber = previewNumber
        self.editRating = editRating
        self.editPinnedChannel = editPinnedChannel
        self.openPinnedChannel = openPinnedChannel
    }
}

private enum NyagramProfileSection: Int32 {
    case gifts
    case username
    case number
    case rating
    case channel
}

private enum NyagramProfileEntry: ItemListNodeEntry {
    case giftsHeader(PresentationTheme, String)
    case hideRegularGifts(PresentationTheme, String, Bool)
    case hideRegularGiftsNotice(PresentationTheme, String)
    
    case usernameHeader(PresentationTheme, String)
    case usernameItem(PresentationTheme, String, String)
    case usernamePreview(PresentationTheme, String)
    
    case numberHeader(PresentationTheme, String)
    case numberItem(PresentationTheme, String, String)
    case numberPreview(PresentationTheme, String)
    
    case ratingHeader(PresentationTheme, String)
    case ratingItem(PresentationTheme, String, String)
    
    case channelHeader(PresentationTheme, String)
    case channelItem(PresentationTheme, String, String)
    case channelOpen(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .giftsHeader, .hideRegularGifts, .hideRegularGiftsNotice:
            return NyagramProfileSection.gifts.rawValue
        case .usernameHeader, .usernameItem, .usernamePreview:
            return NyagramProfileSection.username.rawValue
        case .numberHeader, .numberItem, .numberPreview:
            return NyagramProfileSection.number.rawValue
        case .ratingHeader, .ratingItem:
            return NyagramProfileSection.rating.rawValue
        case .channelHeader, .channelItem, .channelOpen:
            return NyagramProfileSection.channel.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .giftsHeader: return 0
        case .hideRegularGifts: return 1
        case .hideRegularGiftsNotice: return 2
        case .usernameHeader: return 3
        case .usernameItem: return 4
        case .usernamePreview: return 5
        case .numberHeader: return 6
        case .numberItem: return 7
        case .numberPreview: return 8
        case .ratingHeader: return 9
        case .ratingItem: return 10
        case .channelHeader: return 11
        case .channelItem: return 12
        case .channelOpen: return 13
        }
    }
    
    static func ==(lhs: NyagramProfileEntry, rhs: NyagramProfileEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.giftsHeader(lT, lTxt), .giftsHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.hideRegularGifts(lT, lTxt, lVal), .hideRegularGifts(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.hideRegularGiftsNotice(lT, lTxt), .hideRegularGiftsNotice(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.usernameHeader(lT, lTxt), .usernameHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.usernameItem(lT, lTxt, lVal), .usernameItem(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.usernamePreview(lT, lTxt), .usernamePreview(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.numberHeader(lT, lTxt), .numberHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.numberItem(lT, lTxt, lVal), .numberItem(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.numberPreview(lT, lTxt), .numberPreview(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.ratingHeader(lT, lTxt), .ratingHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.ratingItem(lT, lTxt, lVal), .ratingItem(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.channelHeader(lT, lTxt), .channelHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.channelItem(lT, lTxt, lVal), .channelItem(rT, rTxt, rVal)):
            return lT === rT && lTxt == rTxt && lVal == rVal
        case let (.channelOpen(lT, lTxt), .channelOpen(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        default:
            return false
        }
    }
    
    static func <(lhs: NyagramProfileEntry, rhs: NyagramProfileEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! NyagramProfileArguments
        switch self {
        case let .giftsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .hideRegularGifts(_, text, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: text,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { val in
                    args.toggleHideRegularGifts(val)
                }
            )
        case let .hideRegularGiftsNotice(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .usernameHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .usernameItem(_, text, value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.editUsername()
                }
            )
        case let .usernamePreview(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.previewUsername()
                }
            )
        case let .numberHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .numberItem(_, text, value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.editNumber()
                }
            )
        case let .numberPreview(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.previewNumber()
                }
            )
        case let .ratingHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .ratingItem(_, text, value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.editRating()
                }
            )
        case let .channelHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .channelItem(_, text, value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.editPinnedChannel()
                }
            )
        case let .channelOpen(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.openPinnedChannel()
                }
            )
        }
    }
}

private func nyagramProfileEntries(presentationData: PresentationData) -> [NyagramProfileEntry] {
    var entries: [NyagramProfileEntry] = []
    let theme = presentationData.theme
    let settings = NyagramSettings.shared
    
    // Gifts Section
    entries.append(.giftsHeader(theme, NyagramStrings.get(.giftsTitle)))
    entries.append(.hideRegularGifts(theme, NyagramStrings.get(.hideRegularGifts), settings.hideRegularGifts))
    entries.append(.hideRegularGiftsNotice(theme, NyagramStrings.get(.hideRegularGiftsSub)))
    
    // Username Section
    entries.append(.usernameHeader(theme, NyagramStrings.get(.collectibleUsername)))
    let usernameVal = settings.collectibleUsername.map { "@\($0)" } ?? "—"
    entries.append(.usernameItem(theme, NyagramStrings.get(.collectibleUsername), usernameVal))
    if settings.collectibleUsername != nil {
        entries.append(.usernamePreview(theme, "🔍 " + NyagramStrings.get(.previewCard)))
    }
    
    // Number Section
    entries.append(.numberHeader(theme, NyagramStrings.get(.collectibleNumber)))
    let numberVal = settings.collectibleNumber ?? "—"
    entries.append(.numberItem(theme, NyagramStrings.get(.collectibleNumber), numberVal))
    if settings.collectibleNumber != nil {
        entries.append(.numberPreview(theme, "🔍 " + NyagramStrings.get(.previewCard)))
    }
    
    // Rating Section
    entries.append(.ratingHeader(theme, NyagramStrings.get(.rating)))
    let ratingVal: String
    if let level = settings.ratingLevel {
        let pts = settings.ratingPoints ?? Int64(level * 50)
        ratingVal = "lvl \(level) • \(pts)"
    } else {
        ratingVal = "—"
    }
    entries.append(.ratingItem(theme, NyagramStrings.get(.rating), ratingVal))
    
    // Pinned Channel Section
    entries.append(.channelHeader(theme, NyagramStrings.get(.pinnedChannel)))
    let channelVal = settings.pinnedChannelUsername ?? "—"
    entries.append(.channelItem(theme, NyagramStrings.get(.pinnedChannel), channelVal))
    if settings.pinnedChannelUsername != nil {
        entries.append(.channelOpen(theme, "↗️ " + NyagramStrings.get(.pinnedChannel)))
    }
    
    return entries
}

public func nyagramProfileController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    let updatedState = ValuePromise<Bool>(true, ignoreRepeated: false)
    
    let arguments = NyagramProfileArguments(
        context: context,
        toggleHideRegularGifts: { val in
            NyagramSettings.shared.hideRegularGifts = val
            updatedState.set(true)
        },
        editUsername: {
            let settings = NyagramSettings.shared
            let alert = UIAlertController(
                title: NyagramStrings.get(.collectibleUsername),
                message: NyagramStrings.get(.collectibleUsernameSub),
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.placeholder = "username"
                tf.text = settings.collectibleUsername
            }
            alert.addTextField { tf in
                tf.placeholder = "Price (TON), e.g. 500"
                tf.keyboardType = .decimalPad
                if let p = settings.usernameTonPrice {
                    tf.text = "\(p)"
                }
            }
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.remove), style: .destructive, handler: { _ in
                settings.collectibleUsername = nil
                settings.usernameTonPrice = nil
                settings.usernameDate = nil
                updatedState.set(true)
            }))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.save), style: .default, handler: { _ in
                let u = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
                let p = Double(alert.textFields?[1].text ?? "") ?? 250.0
                if let u = u, !u.isEmpty {
                    settings.collectibleUsername = u
                    settings.usernameTonPrice = p
                    settings.usernameDate = Date().timeIntervalSince1970
                } else {
                    settings.collectibleUsername = nil
                }
                updatedState.set(true)
            }))
            context.sharedContext.applicationBindings.presentNativeController(alert)
        },
        previewUsername: {
            if let u = NyagramSettings.shared.collectibleUsername {
                let modal = nyagramCollectibleCardModal(
                    context: context,
                    title: "@\(u)",
                    subtitle: "\(u).t.me",
                    tonPrice: NyagramSettings.shared.usernameTonPrice ?? 250.0,
                    date: Date(timeIntervalSince1970: NyagramSettings.shared.usernameDate ?? Date().timeIntervalSince1970)
                )
                presentControllerImpl?(modal, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
            }
        },
        editNumber: {
            let settings = NyagramSettings.shared
            let alert = UIAlertController(
                title: NyagramStrings.get(.collectibleNumber),
                message: NyagramStrings.get(.collectibleNumberSub),
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.placeholder = "+888 0413 6929"
                tf.text = settings.collectibleNumber
            }
            alert.addTextField { tf in
                tf.placeholder = "Price (TON), e.g. 1000"
                tf.keyboardType = .decimalPad
                if let p = settings.numberTonPrice {
                    tf.text = "\(p)"
                }
            }
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.remove), style: .destructive, handler: { _ in
                settings.collectibleNumber = nil
                settings.numberTonPrice = nil
                settings.numberDate = nil
                updatedState.set(true)
            }))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.save), style: .default, handler: { _ in
                let n = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines)
                let p = Double(alert.textFields?[1].text ?? "") ?? 500.0
                if let n = n, !n.isEmpty {
                    settings.collectibleNumber = n
                    settings.numberTonPrice = p
                    settings.numberDate = Date().timeIntervalSince1970
                } else {
                    settings.collectibleNumber = nil
                }
                updatedState.set(true)
            }))
            context.sharedContext.applicationBindings.presentNativeController(alert)
        },
        previewNumber: {
            if let num = NyagramSettings.shared.collectibleNumber {
                let modal = nyagramCollectibleCardModal(
                    context: context,
                    title: num,
                    subtitle: "Fragment Anonymous Number",
                    tonPrice: NyagramSettings.shared.numberTonPrice ?? 500.0,
                    date: Date(timeIntervalSince1970: NyagramSettings.shared.numberDate ?? Date().timeIntervalSince1970)
                )
                presentControllerImpl?(modal, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
            }
        },
        editRating: {
            let settings = NyagramSettings.shared
            let alert = UIAlertController(
                title: NyagramStrings.get(.rating),
                message: NyagramStrings.get(.ratingSub),
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.placeholder = "Level (1 - 100)"
                tf.keyboardType = .numberPad
                if let lvl = settings.ratingLevel {
                    tf.text = "\(lvl)"
                }
            }
            alert.addTextField { tf in
                tf.placeholder = "Points, e.g. 2500"
                tf.keyboardType = .numberPad
                if let pts = settings.ratingPoints {
                    tf.text = "\(pts)"
                }
            }
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.remove), style: .destructive, handler: { _ in
                settings.ratingLevel = nil
                settings.ratingPoints = nil
                updatedState.set(true)
            }))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.save), style: .default, handler: { _ in
                let lvl = Int(alert.textFields?[0].text ?? "")
                let pts = Int64(alert.textFields?[1].text ?? "")
                if let lvl = lvl, lvl > 0 {
                    settings.ratingLevel = min(100, max(1, lvl))
                    settings.ratingPoints = pts ?? Int64(lvl * 100)
                } else {
                    settings.ratingLevel = nil
                    settings.ratingPoints = nil
                }
                updatedState.set(true)
            }))
            context.sharedContext.applicationBindings.presentNativeController(alert)
        },
        editPinnedChannel: {
            let settings = NyagramSettings.shared
            let alert = UIAlertController(
                title: NyagramStrings.get(.pinnedChannel),
                message: NyagramStrings.get(.pinnedChannelSub),
                preferredStyle: .alert
            )
            alert.addTextField { tf in
                tf.placeholder = "@channel or link"
                tf.text = settings.pinnedChannelUsername
            }
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.remove), style: .destructive, handler: { _ in
                settings.pinnedChannelUsername = nil
                updatedState.set(true)
            }))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.save), style: .default, handler: { _ in
                let ch = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let ch = ch, !ch.isEmpty {
                    settings.pinnedChannelUsername = ch
                } else {
                    settings.pinnedChannelUsername = nil
                }
                updatedState.set(true)
            }))
            context.sharedContext.applicationBindings.presentNativeController(alert)
        },
        openPinnedChannel: {
            if let ch = NyagramSettings.shared.pinnedChannelUsername {
                let clean = ch.replacingOccurrences(of: "@", with: "").replacingOccurrences(of: "https://t.me/", with: "").replacingOccurrences(of: "t.me/", with: "")
                context.sharedContext.applicationBindings.openUrl("https://t.me/\(clean)")
            }
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, updatedState.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, NyagramProfileArguments)) in
        let entries = nyagramProfileEntries(presentationData: presentationData)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(NyagramStrings.get(.profileTitle)),
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
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    
    return controller
}
