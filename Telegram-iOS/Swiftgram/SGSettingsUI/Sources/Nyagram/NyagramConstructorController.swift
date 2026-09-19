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

public let nyagramModels: [String] = [
    "Pepe Classic", "Cyber Frog", "Golden Pepe", "Diamond Toad", "Space Explorer",
    "Ninja Kermit", "Samurai Amphibian", "Wizard Pepe", "Vampire Toad", "Pharaoh Frog",
    "King Pepe", "Pixel Toad", "Neon Synthwave", "Hacker Pepe", "Astronaut Frog",
    "Ghost Pepe", "Mecha Toad", "Dragon Frog", "Cyborg Kermit", "Steampunk Pepe",
    "Mafia Boss Frog", "Detective Toad", "Gamer Pepe", "Zombie Frog", "Angel Pepe",
    "Demon Toad", "Pirate Frog", "Viking Pepe", "Knight Toad", "Gladiator Frog",
    "Sensei Pepe", "Baron Toad", "Emperor Frog", "DJ Pepe", "Rockstar Toad",
    "Alien Frog", "Galactic Pepe", "Chrono Toad", "Quantum Frog", "Matrix Pepe",
    "Cosmic Kermit", "Phoenix Toad", "Shadow Frog", "Solar Pepe", "Lunar Toad",
    "Mystic Frog", "Arcane Pepe", "Infinity Toad", "Genesis Frog", "Nyagram Master"
]

public let nyagramBackdrops: [String] = [
    "Neon Violet", "Cyber Blue", "Emerald Green", "Golden Sun", "Ruby Red",
    "Obsidian Dark", "Midnight Aurora", "Pastel Sunset", "Electric Lime", "Deep Space"
]

public let nyagramPatterns: [String] = [
    "⭐️ Stars", "💎 Diamonds", "👑 Crowns", "⚡️ Lightning", "🔥 Flames",
    "🔮 Orbs", "💠 TON Crystals", "🌀 Portals", "⚔️ Crossed Swords", "✨ Sparkles"
]

private final class NyagramConstructorArguments {
    let context: AccountContext
    let selectModel: () -> Void
    let selectBackdrop: () -> Void
    let selectPattern: () -> Void
    let selectCount: () -> Void
    let setNumber: (Int) -> Void
    let randomizeNumber: () -> Void
    let generate: () -> Void
    
    init(
        context: AccountContext,
        selectModel: @escaping () -> Void,
        selectBackdrop: @escaping () -> Void,
        selectPattern: @escaping () -> Void,
        selectCount: @escaping () -> Void,
        setNumber: @escaping (Int) -> Void,
        randomizeNumber: @escaping () -> Void,
        generate: @escaping () -> Void
    ) {
        self.context = context
        self.selectModel = selectModel
        self.selectBackdrop = selectBackdrop
        self.selectPattern = selectPattern
        self.selectCount = selectCount
        self.setNumber = setNumber
        self.randomizeNumber = randomizeNumber
        self.generate = generate
    }
}

private struct NyagramConstructorState: Equatable {
    var modelIndex: Int = 0
    var backdropIndex: Int = 0
    var patternIndex: Int = 0
    var number: Int = Int.random(in: 1...9999)
    var count: Int = 1
    var rarity: Int = 15
    var tonPrice: Double = 15.0
}

private enum NyagramConstructorSection: Int32 {
    case preview
    case options
    case action
}

private enum NyagramConstructorEntry: ItemListNodeEntry {
    case previewHeader(PresentationTheme, String)
    case previewCard(PresentationTheme, String, String)
    
    case optionsHeader(PresentationTheme, String)
    case model(PresentationTheme, String, String)
    case backdrop(PresentationTheme, String, String)
    case pattern(PresentationTheme, String, String)
    case number(PresentationTheme, String, String)
    case randomBtn(PresentationTheme, String)
    case count(PresentationTheme, String, String)
    
    case generateBtn(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .previewHeader, .previewCard:
            return NyagramConstructorSection.preview.rawValue
        case .optionsHeader, .model, .backdrop, .pattern, .number, .randomBtn, .count:
            return NyagramConstructorSection.options.rawValue
        case .generateBtn:
            return NyagramConstructorSection.action.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .previewHeader: return 0
        case .previewCard: return 1
        case .optionsHeader: return 2
        case .model: return 3
        case .backdrop: return 4
        case .pattern: return 5
        case .number: return 6
        case .randomBtn: return 7
        case .count: return 8
        case .generateBtn: return 9
        }
    }
    
    static func ==(lhs: NyagramConstructorEntry, rhs: NyagramConstructorEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.previewHeader(lT, lTxt), .previewHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.previewCard(lT, lTitle, lSub), .previewCard(rT, rTitle, rSub)):
            return lT === rT && lTitle == rTitle && lSub == rSub
        case let (.optionsHeader(lT, lTxt), .optionsHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.model(lT, lTitle, lVal), .model(rT, rTitle, rVal)):
            return lT === rT && lTitle == rTitle && lVal == rVal
        case let (.backdrop(lT, lTitle, lVal), .backdrop(rT, rTitle, rVal)):
            return lT === rT && lTitle == rTitle && lVal == rVal
        case let (.pattern(lT, lTitle, lVal), .pattern(rT, rTitle, rVal)):
            return lT === rT && lTitle == rTitle && lVal == rVal
        case let (.number(lT, lTitle, lVal), .number(rT, rTitle, rVal)):
            return lT === rT && lTitle == rTitle && lVal == rVal
        case let (.randomBtn(lT, lTxt), .randomBtn(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.count(lT, lTitle, lVal), .count(rT, rTitle, rVal)):
            return lT === rT && lTitle == rTitle && lVal == rVal
        case let (.generateBtn(lT, lTxt), .generateBtn(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        default:
            return false
        }
    }
    
    static func <(lhs: NyagramConstructorEntry, rhs: NyagramConstructorEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! NyagramConstructorArguments
        switch self {
        case let .previewHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .previewCard(_, title, subtitle):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: title,
                label: subtitle,
                sectionId: self.section,
                style: .blocks,
                action: nil
            )
        case let .optionsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .model(_, text, val):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: val, sectionId: self.section, style: .blocks, action: {
                args.selectModel()
            })
        case let .backdrop(_, text, val):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: val, sectionId: self.section, style: .blocks, action: {
                args.selectBackdrop()
            })
        case let .pattern(_, text, val):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: val, sectionId: self.section, style: .blocks, action: {
                args.selectPattern()
            })
        case let .number(_, text, val):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: val, sectionId: self.section, style: .blocks, action: {
                args.randomizeNumber()
            })
        case let .randomBtn(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.randomizeNumber()
            })
        case let .count(_, text, val):
            return ItemListDisclosureItem(presentationData: presentationData, title: text, label: val, sectionId: self.section, style: .blocks, action: {
                args.selectCount()
            })
        case let .generateBtn(_, text):
            return ItemListActionItem(presentationData: presentationData, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.generate()
            })
        }
    }
}

private func nyagramConstructorEntries(presentationData: PresentationData, state: NyagramConstructorState) -> [NyagramConstructorEntry] {
    var entries: [NyagramConstructorEntry] = []
    let theme = presentationData.theme
    
    let currentModel = nyagramModels[safe: state.modelIndex] ?? "Pepe"
    let currentBackdrop = nyagramBackdrops[safe: state.backdropIndex] ?? "Classic"
    let currentPattern = nyagramPatterns[safe: state.patternIndex] ?? "Stars"
    
    entries.append(.previewHeader(theme, NyagramStrings.get(.previewCard)))
    entries.append(.previewCard(theme, "\(currentModel) #\(state.number)", "\(currentBackdrop) · \(currentPattern)"))
    
    entries.append(.optionsHeader(theme, NyagramStrings.get(.giftsModel)))
    entries.append(.model(theme, NyagramStrings.get(.giftsModel), currentModel))
    entries.append(.backdrop(theme, NyagramStrings.get(.giftsBackdrop), currentBackdrop))
    entries.append(.pattern(theme, NyagramStrings.get(.giftsPattern), currentPattern))
    entries.append(.number(theme, NyagramStrings.get(.giftsNumber), "#\(state.number)"))
    entries.append(.randomBtn(theme, "🎲 " + NyagramStrings.get(.giftsRandomNumber)))
    entries.append(.count(theme, NyagramStrings.get(.giftsCount), "\(state.count)"))
    
    entries.append(.generateBtn(theme, "🚀 " + NyagramStrings.get(.giftsGenerate)))
    
    return entries
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public func nyagramConstructorController(context: AccountContext, onCreated: @escaping () -> Void) -> ViewController {
    let statePromise = ValuePromise(NyagramConstructorState(), ignoreRepeated: false)
    let stateValue = Atomic(value: NyagramConstructorState())
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    
    let updateState: ((inout NyagramConstructorState) -> Void) -> Void = { f in
        statePromise.set(stateValue.modify { var s = $0; f(&s); return s })
    }
    
    let arguments = NyagramConstructorArguments(
        context: context,
        selectModel: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let actionSheet = ActionSheetController(presentationData: presentationData)
            var items: [ActionSheetItem] = []
            for (idx, name) in nyagramModels.prefix(25).enumerated() {
                items.append(ActionSheetButtonItem(title: name, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    updateState { $0.modelIndex = idx }
                }))
            }
            items.append(ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            }))
            actionSheet.setItemGroups([ActionSheetItemGroup(items: items)])
            presentControllerImpl?(actionSheet, nil)
        },
        selectBackdrop: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let actionSheet = ActionSheetController(presentationData: presentationData)
            var items: [ActionSheetItem] = []
            for (idx, name) in nyagramBackdrops.enumerated() {
                items.append(ActionSheetButtonItem(title: name, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    updateState { $0.backdropIndex = idx }
                }))
            }
            items.append(ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            }))
            actionSheet.setItemGroups([ActionSheetItemGroup(items: items)])
            presentControllerImpl?(actionSheet, nil)
        },
        selectPattern: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let actionSheet = ActionSheetController(presentationData: presentationData)
            var items: [ActionSheetItem] = []
            for (idx, name) in nyagramPatterns.enumerated() {
                items.append(ActionSheetButtonItem(title: name, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    updateState { $0.patternIndex = idx }
                }))
            }
            items.append(ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            }))
            actionSheet.setItemGroups([ActionSheetItemGroup(items: items)])
            presentControllerImpl?(actionSheet, nil)
        },
        selectCount: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let actionSheet = ActionSheetController(presentationData: presentationData)
            let counts = [1, 5, 10, 25]
            var items: [ActionSheetItem] = []
            for c in counts {
                items.append(ActionSheetButtonItem(title: "\(c)", action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    updateState { $0.count = c }
                }))
            }
            items.append(ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            }))
            actionSheet.setItemGroups([ActionSheetItemGroup(items: items)])
            presentControllerImpl?(actionSheet, nil)
        },
        setNumber: { num in
            updateState { $0.number = num }
        },
        randomizeNumber: {
            updateState { $0.number = Int.random(in: 1...9999) }
        },
        generate: {
            let state = stateValue.with { $0 }
            let modelName = nyagramModels[safe: state.modelIndex] ?? "Pepe"
            let settings = NyagramSettings.shared
            
            for i in 0..<state.count {
                let giftNum = (state.count == 1) ? state.number : Int.random(in: 1...9999)
                let gift = NyagramGift(
                    name: modelName,
                    number: giftNum,
                    modelIndex: state.modelIndex,
                    backdropIndex: state.backdropIndex,
                    patternIndex: state.patternIndex,
                    rarity: Int.random(in: 5...99),
                    tonPrice: state.tonPrice,
                    creationDate: Date().timeIntervalSince1970 + Double(i),
                    isWorn: (i == 0 && settings.gifts.isEmpty)
                )
                settings.addGift(gift)
            }
            
            let feedback = UINotificationFeedbackGenerator()
            feedback.prepare()
            feedback.notificationOccurred(.success)
            
            onCreated()
            
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            presentControllerImpl?(
                OverlayStatusController(theme: presentationData.theme, type: .success),
                nil
            )
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, NyagramConstructorArguments)) in
        let entries = nyagramConstructorEntries(presentationData: presentationData, state: state)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(NyagramStrings.get(.giftsCreate)),
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
