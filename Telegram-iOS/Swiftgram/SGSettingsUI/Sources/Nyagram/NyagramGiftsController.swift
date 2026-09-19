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

private final class NyagramGiftsArguments {
    let context: AccountContext
    let openConstructor: () -> Void
    let toggleWearGift: (String) -> Void
    let deleteGift: (String) -> Void
    
    init(
        context: AccountContext,
        openConstructor: @escaping () -> Void,
        toggleWearGift: @escaping (String) -> Void,
        deleteGift: @escaping (String) -> Void
    ) {
        self.context = context
        self.openConstructor = openConstructor
        self.toggleWearGift = toggleWearGift
        self.deleteGift = deleteGift
    }
}

private enum NyagramGiftsSection: Int32 {
    case create
    case list
}

private enum NyagramGiftsEntry: ItemListNodeEntry {
    case createGift(PresentationTheme, String)
    case giftsHeader(PresentationTheme, String)
    case empty(PresentationTheme, String)
    case giftItem(Int32, PresentationTheme, NyagramGift)
    
    var section: ItemListSectionId {
        switch self {
        case .createGift:
            return NyagramGiftsSection.create.rawValue
        case .giftsHeader, .empty, .giftItem:
            return NyagramGiftsSection.list.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .createGift: return 0
        case .giftsHeader: return 1
        case .empty: return 2
        case let .giftItem(index, _, _): return 10 + index
        }
    }
    
    static func ==(lhs: NyagramGiftsEntry, rhs: NyagramGiftsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.createGift(lhsTheme, lhsText), .createGift(rhsTheme, rhsText)):
            return lhsTheme === rhsTheme && lhsText == rhsText
        case let (.giftsHeader(lhsTheme, lhsText), .giftsHeader(rhsTheme, rhsText)):
            return lhsTheme === rhsTheme && lhsText == rhsText
        case let (.empty(lhsTheme, lhsText), .empty(rhsTheme, rhsText)):
            return lhsTheme === rhsTheme && lhsText == rhsText
        case let (.giftItem(lhsIdx, lhsTheme, lhsGift), .giftItem(rhsIdx, rhsTheme, rhsGift)):
            return lhsIdx == rhsIdx && lhsTheme === rhsTheme && lhsGift == rhsGift
        default:
            return false
        }
    }
    
    static func <(lhs: NyagramGiftsEntry, rhs: NyagramGiftsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! NyagramGiftsArguments
        switch self {
        case let .createGift(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.openConstructor()
                }
            )
        case let .giftsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .empty(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .giftItem(_, _, gift):
            let wornLabel = gift.isWorn ? "⭐️ \(NyagramStrings.get(.giftsWorn))" : NyagramStrings.get(.giftsWear)
            let subtitle = "№\(gift.number) · \(gift.rarity)% · \(gift.tonPrice) TON"
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "\(gift.name)",
                label: wornLabel,
                additionalDetail: subtitle,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.toggleWearGift(gift.id)
                }
            )
        }
    }
}

private func nyagramGiftsEntries(presentationData: PresentationData) -> [NyagramGiftsEntry] {
    var entries: [NyagramGiftsEntry] = []
    let theme = presentationData.theme
    let gifts = NyagramSettings.shared.gifts
    
    entries.append(.createGift(theme, "✨ " + NyagramStrings.get(.giftsCreate)))
    entries.append(.giftsHeader(theme, NyagramStrings.get(.giftsTitle)))
    
    if gifts.isEmpty {
        entries.append(.empty(theme, NyagramStrings.get(.giftsEmpty)))
    } else {
        for (index, gift) in gifts.enumerated() {
            entries.append(.giftItem(Int32(index), theme, gift))
        }
    }
    
    return entries
}

public func nyagramGiftsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    let updatedState = ValuePromise<Bool>(true, ignoreRepeated: false)
    
    let arguments = NyagramGiftsArguments(
        context: context,
        openConstructor: {
            pushControllerImpl?(nyagramConstructorController(context: context, onCreated: {
                updatedState.set(true)
            }))
        },
        toggleWearGift: { id in
            let settings = NyagramSettings.shared
            if let gift = settings.gifts.first(where: { $0.id == id }) {
                settings.setGiftWorn(id: id, worn: !gift.isWorn)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
                updatedState.set(true)
            }
        },
        deleteGift: { id in
            NyagramSettings.shared.removeGift(id: id)
            updatedState.set(true)
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, updatedState.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = nyagramGiftsEntries(presentationData: presentationData)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(NyagramStrings.get(.giftsTitle)),
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
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    
    return controller
}
