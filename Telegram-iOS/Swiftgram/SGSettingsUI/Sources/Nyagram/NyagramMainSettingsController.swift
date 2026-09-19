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

private final class NyagramMainArguments {
    let context: AccountContext
    let openGifts: () -> Void
    let openProfile: () -> Void
    let openBalance: () -> Void
    let openBackup: () -> Void
    let openAbout: () -> Void
    
    init(
        context: AccountContext,
        openGifts: @escaping () -> Void,
        openProfile: @escaping () -> Void,
        openBalance: @escaping () -> Void,
        openBackup: @escaping () -> Void,
        openAbout: @escaping () -> Void
    ) {
        self.context = context
        self.openGifts = openGifts
        self.openProfile = openProfile
        self.openBalance = openBalance
        self.openBackup = openBackup
        self.openAbout = openAbout
    }
}

private enum NyagramMainSection: Int32 {
    case main
    case more
}

private enum NyagramMainEntry: ItemListNodeEntry {
    case mainHeader(PresentationTheme, String)
    case gifts(PresentationTheme, String, String)
    case profile(PresentationTheme, String, String)
    case balance(PresentationTheme, String, String)
    case backup(PresentationTheme, String, String)
    
    case moreHeader(PresentationTheme, String)
    case about(PresentationTheme, String, String)
    
    var section: ItemListSectionId {
        switch self {
        case .mainHeader, .gifts, .profile, .balance, .backup:
            return NyagramMainSection.main.rawValue
        case .moreHeader, .about:
            return NyagramMainSection.more.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .mainHeader: return 0
        case .gifts: return 1
        case .profile: return 2
        case .balance: return 3
        case .backup: return 4
        case .moreHeader: return 5
        case .about: return 6
        }
    }
    
    static func ==(lhs: NyagramMainEntry, rhs: NyagramMainEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.mainHeader(lhsTheme, lhsText), .mainHeader(rhsTheme, rhsText)):
            return lhsTheme === rhsTheme && lhsText == rhsText
        case let (.gifts(lhsTheme, lhsText, lhsSub), .gifts(rhsTheme, rhsText, rhsSub)):
            return lhsTheme === rhsTheme && lhsText == rhsText && lhsSub == rhsSub
        case let (.profile(lhsTheme, lhsText, lhsSub), .profile(rhsTheme, rhsText, rhsSub)):
            return lhsTheme === rhsTheme && lhsText == rhsText && lhsSub == rhsSub
        case let (.balance(lhsTheme, lhsText, lhsSub), .balance(rhsTheme, rhsText, rhsSub)):
            return lhsTheme === rhsTheme && lhsText == rhsText && lhsSub == rhsSub
        case let (.backup(lhsTheme, lhsText, lhsSub), .backup(rhsTheme, rhsText, rhsSub)):
            return lhsTheme === rhsTheme && lhsText == rhsText && lhsSub == rhsSub
        case let (.moreHeader(lhsTheme, lhsText), .moreHeader(rhsTheme, rhsText)):
            return lhsTheme === rhsTheme && lhsText == rhsText
        case let (.about(lhsTheme, lhsText, lhsSub), .about(rhsTheme, rhsText, rhsSub)):
            return lhsTheme === rhsTheme && lhsText == rhsText && lhsSub == rhsSub
        default:
            return false
        }
    }
    
    static func <(lhs: NyagramMainEntry, rhs: NyagramMainEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! NyagramMainArguments
        switch self {
        case let .mainHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .gifts(_, text, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                args.openGifts()
            })
        case let .profile(_, text, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                args.openProfile()
            })
        case let .balance(_, text, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                args.openBalance()
            })
        case let .backup(_, text, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                args.openBackup()
            })
        case let .moreHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .about(_, text, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                args.openAbout()
            })
        }
    }
}

private func nyagramMainEntries(presentationData: PresentationData) -> [NyagramMainEntry] {
    var entries: [NyagramMainEntry] = []
    let theme = presentationData.theme
    let settings = NyagramSettings.shared
    
    let giftsCount = settings.gifts.count
    let wornGiftText: String
    if let worn = settings.activeGift {
        wornGiftText = "#\(worn.number)"
    } else {
        wornGiftText = ""
    }
    let giftsLabel = giftsCount > 0 ? "\(giftsCount) NFT\(wornGiftText.isEmpty ? "" : " · " + wornGiftText)" : ""
    
    let profileLabel: String
    if settings.collectibleUsername != nil || settings.collectibleNumber != nil || settings.ratingLevel != nil {
        profileLabel = NyagramStrings.get(.save)
    } else {
        profileLabel = ""
    }
    
    let balanceLabel = "\(settings.starsBalance) ⭐️ · \(settings.gramBalance) GRAM"
    
    entries.append(.mainHeader(theme, NyagramStrings.get(.sectionMain)))
    entries.append(.gifts(theme, NyagramStrings.get(.gifts), giftsLabel))
    entries.append(.profile(theme, NyagramStrings.get(.profile), profileLabel))
    entries.append(.balance(theme, NyagramStrings.get(.balance), balanceLabel))
    entries.append(.backup(theme, NyagramStrings.get(.backup), ""))
    
    entries.append(.moreHeader(theme, NyagramStrings.get(.sectionMore)))
    entries.append(.about(theme, NyagramStrings.get(.about), "v1.0"))
    
    return entries
}

public func nyagramMainSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    
    let arguments = NyagramMainArguments(
        context: context,
        openGifts: {
            pushControllerImpl?(nyagramGiftsController(context: context))
        },
        openProfile: {
            pushControllerImpl?(nyagramProfileController(context: context))
        },
        openBalance: {
            pushControllerImpl?(nyagramBalanceController(context: context))
        },
        openBackup: {
            pushControllerImpl?(nyagramBackupController(context: context))
        },
        openAbout: {
            let alert = textAlertController(
                context: context,
                title: NyagramStrings.get(.title),
                text: NyagramStrings.get(.aboutDescription),
                actions: [
                    TextAlertAction(type: .defaultAction, title: NyagramStrings.get(.close), action: {})
                ]
            )
            presentControllerImpl?(alert, nil)
        }
    )
    
    let signal = context.sharedContext.presentationData
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, NyagramMainArguments)) in
        let entries = nyagramMainEntries(presentationData: presentationData)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(NyagramStrings.get(.title)),
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
