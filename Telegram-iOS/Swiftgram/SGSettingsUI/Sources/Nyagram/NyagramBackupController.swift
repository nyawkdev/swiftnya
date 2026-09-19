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
import UniformTypeIdentifiers

private final class NyagramBackupArguments {
    let context: AccountContext
    let createBackup: () -> Void
    let restoreBackup: () -> Void
    let deleteAllData: () -> Void
    
    init(
        context: AccountContext,
        createBackup: @escaping () -> Void,
        restoreBackup: @escaping () -> Void,
        deleteAllData: @escaping () -> Void
    ) {
        self.context = context
        self.createBackup = createBackup
        self.restoreBackup = restoreBackup
        self.deleteAllData = deleteAllData
    }
}

private enum NyagramBackupSection: Int32 {
    case actions
    case danger
}

private enum NyagramBackupEntry: ItemListNodeEntry {
    case actionsHeader(PresentationTheme, String)
    case createBackup(PresentationTheme, String)
    case restoreBackup(PresentationTheme, String)
    
    case dangerHeader(PresentationTheme, String)
    case deleteAll(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .actionsHeader, .createBackup, .restoreBackup:
            return NyagramBackupSection.actions.rawValue
        case .dangerHeader, .deleteAll:
            return NyagramBackupSection.danger.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .actionsHeader: return 0
        case .createBackup: return 1
        case .restoreBackup: return 2
        case .dangerHeader: return 3
        case .deleteAll: return 4
        }
    }
    
    static func ==(lhs: NyagramBackupEntry, rhs: NyagramBackupEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.actionsHeader(lT, lTxt), .actionsHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.createBackup(lT, lTxt), .createBackup(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.restoreBackup(lT, lTxt), .restoreBackup(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.dangerHeader(lT, lTxt), .dangerHeader(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        case let (.deleteAll(lT, lTxt), .deleteAll(rT, rTxt)):
            return lT === rT && lTxt == rTxt
        default:
            return false
        }
    }
    
    static func <(lhs: NyagramBackupEntry, rhs: NyagramBackupEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! NyagramBackupArguments
        switch self {
        case let .actionsHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .createBackup(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.createBackup()
                }
            )
        case let .restoreBackup(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .generic,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.restoreBackup()
                }
            )
        case let .dangerHeader(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .deleteAll(_, text):
            return ItemListActionItem(
                presentationData: presentationData,
                title: text,
                kind: .destructive,
                alignment: .natural,
                sectionId: self.section,
                style: .blocks,
                action: {
                    args.deleteAllData()
                }
            )
        }
    }
}

private func nyagramBackupEntries(presentationData: PresentationData) -> [NyagramBackupEntry] {
    var entries: [NyagramBackupEntry] = []
    let theme = presentationData.theme
    
    entries.append(.actionsHeader(theme, NyagramStrings.get(.backupTitle)))
    entries.append(.createBackup(theme, "📦 " + NyagramStrings.get(.backupCreate)))
    entries.append(.restoreBackup(theme, "📥 " + NyagramStrings.get(.backupRestore)))
    
    entries.append(.dangerHeader(theme, NyagramStrings.get(.backupDeleteAll)))
    entries.append(.deleteAll(theme, "🗑 " + NyagramStrings.get(.backupDeleteAll)))
    
    return entries
}

public func nyagramBackupController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    let updatedState = ValuePromise<Bool>(true, ignoreRepeated: false)
    
    let documentPickerDelegate = DocumentPickerDelegate(onPicked: { data in
        if NyagramSettings.shared.restoreFromPayload(data: data) {
            let feedback = UINotificationFeedbackGenerator()
            feedback.prepare()
            feedback.notificationOccurred(.success)
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            presentControllerImpl?(OverlayStatusController(theme: presentationData.theme, type: .success), nil)
            updatedState.set(true)
        }
    })
    
    let arguments = NyagramBackupArguments(
        context: context,
        createBackup: {
            guard let data = NyagramSettings.shared.createBackupPayload() else { return }
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("Nyagram_Backup.nyaprofile")
            try? data.write(to: fileURL)
            
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            (context.sharedContext.mainWindow?.viewController as? ViewController)?.present(activityVC, in: .window(.root))
        },
        restoreBackup: {
            let picker: UIDocumentPickerViewController
            if #available(iOS 14.0, *) {
                picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .data, .item])
            } else {
                picker = UIDocumentPickerViewController(documentTypes: ["public.json", "public.data"], in: .import)
            }
            picker.delegate = documentPickerDelegate
            picker.allowsMultipleSelection = false
            (context.sharedContext.mainWindow?.viewController as? ViewController)?.present(picker, in: .window(.root))
        },
        deleteAllData: {
            let alert = UIAlertController(
                title: NyagramStrings.get(.backupDeleteAllConfirmTitle),
                message: NyagramStrings.get(.backupDeleteAllConfirmBody),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.cancel), style: .cancel))
            alert.addAction(UIAlertAction(title: NyagramStrings.get(.delete), style: .destructive, handler: { _ in
                NyagramSettings.shared.deleteAllData()
                let feedback = UINotificationFeedbackGenerator()
                feedback.prepare()
                feedback.notificationOccurred(.warning)
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                presentControllerImpl?(OverlayStatusController(theme: presentationData.theme, type: .success), nil)
                updatedState.set(true)
            }))
            (context.sharedContext.mainWindow?.viewController as? ViewController)?.present(alert, in: .window(.root))
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, updatedState.get())
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = nyagramBackupEntries(presentationData: presentationData)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(NyagramStrings.get(.backupTitle)),
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

private final class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    let onPicked: (Data) -> Void
    
    init(onPicked: @escaping (Data) -> Void) {
        self.onPicked = onPicked
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let shouldStop = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStop {
                url.stopAccessingSecurityScopedResource()
            }
        }
        if let data = try? Data(contentsOf: url) {
            self.onPicked(data)
        }
    }
}
