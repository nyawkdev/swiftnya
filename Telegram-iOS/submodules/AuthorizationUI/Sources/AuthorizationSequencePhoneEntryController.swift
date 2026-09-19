import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import PresentationDataUtils
import ProgressNavigationButtonNode
import AccountContext
import CountrySelectionUI
import PhoneNumberFormat
import DebugSettingsUI
import MessageUI
import AuthenticationServices

public final class AuthorizationSequencePhoneEntryController: ViewController, MFMailComposeViewControllerDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var controllerNode: AuthorizationSequencePhoneEntryControllerNode {
        return self.displayNode as! AuthorizationSequencePhoneEntryControllerNode
    }
    
    private var validLayout: ContainerViewLayout?
    
    private let sharedContext: SharedAccountContext
    private var account: UnauthorizedAccount?
    private var apiId: Int32
    private var apiHash: String
    private let isTestingEnvironment: Bool
    private let otherAccountPhoneNumbers: ((String, AccountRecordId, Bool)?, [(String, AccountRecordId, Bool)])
    private let network: Network
    private let presentationData: PresentationData
    private let openUrl: (String) -> Void
    
    private let back: () -> Void
    
    private var currentData: (Int32, String?, String)?
        
    var codeNode: ASDisplayNode {
        return self.controllerNode.codeNode
    }
    
    var numberNode: ASDisplayNode {
        return self.controllerNode.numberNode
    }
    
    var buttonNode: ASDisplayNode {
        return self.controllerNode.buttonNode
    }
    
    public var inProgress: Bool = false {
        didSet {
            self.updateNavigationItems()
            self.controllerNode.inProgress = self.inProgress
            self.confirmationController?.inProgress = self.inProgress
        }
    }
    public var loginWithNumber: ((String, Bool) -> Void)?
    public var loginWithPasskey: ((AuthorizationPasskeyData, Bool) -> Void)?
    var accountUpdated: ((UnauthorizedAccount) -> Void)?
    
    weak var confirmationController: PhoneConfirmationController?
    
    private let termsDisposable = MetaDisposable()
    
    private let hapticFeedback = HapticFeedback()
    
    public init(sharedContext: SharedAccountContext, account: UnauthorizedAccount?, countriesConfiguration: CountriesConfiguration? = nil, apiId: Int32, apiHash: String, isTestingEnvironment: Bool, otherAccountPhoneNumbers: ((String, AccountRecordId, Bool)?, [(String, AccountRecordId, Bool)]), network: Network, presentationData: PresentationData, openUrl: @escaping (String) -> Void, back: @escaping () -> Void) {
        self.sharedContext = sharedContext
        self.account = account
        self.apiId = apiId
        self.apiHash = apiHash
        self.isTestingEnvironment = isTestingEnvironment
        self.otherAccountPhoneNumbers = otherAccountPhoneNumbers
        self.network = network
        self.presentationData = presentationData
        self.openUrl = openUrl
        self.back = back
                
        super.init(navigationBarPresentationData: NavigationBarPresentationData(theme: AuthorizationSequenceController.navigationBarTheme(presentationData.theme), strings: NavigationBarStrings(presentationStrings: presentationData.strings)))
        
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
        
        self.hasActiveInput = true
        
        self.statusBar.statusBarStyle = presentationData.theme.intro.statusBarStyle.style
        self.attemptNavigation = { _ in
            return false
        }
        self.navigationBar?.backPressed = {
            back()
        }
        
        if !otherAccountPhoneNumbers.1.isEmpty {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "___close", style: .plain, target: self, action: #selector(self.cancelPressed))
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "API", style: .plain, target: self, action: #selector(self.apiSettingsPressed))
        }
        
        if let countriesConfiguration {
            AuthorizationSequenceCountrySelectionController.setupCountryCodes(countries: countriesConfiguration.countries, codesByPrefix: countriesConfiguration.countriesByPrefix)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.termsDisposable.dispose()
    }
    
    @objc private func cancelPressed() {
        self.back()
    }
    
    func updateNavigationItems() {
        guard let layout = self.validLayout, layout.size.width < 360.0 else {
            return
        }
                
        if self.inProgress {
            let item = UIBarButtonItem(customDisplayNode: ProgressNavigationButtonNode(color: self.presentationData.theme.rootController.navigationBar.accentTextColor))
            self.navigationItem.rightBarButtonItem = item
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Next, style: .done, target: self, action: #selector(self.nextPressed))
        }
    }
    
    public func updateData(countryCode: Int32, countryName: String?, number: String) {
        self.currentData = (countryCode, countryName, number)
        if self.isNodeLoaded {
            self.controllerNode.codeAndNumber = (countryCode, countryName, number)
        }
    }
    
    private var shouldAnimateIn = false
    private var transitionInArguments: (buttonFrame: CGRect, buttonTitle: String, animationSnapshot: UIView, textSnapshot: UIView)?
    
    func animateWithSplashController(_ controller: AuthorizationSequenceSplashController) {
        self.shouldAnimateIn = true
        
        if let animationSnapshot = controller.animationSnapshot, let textSnapshot = controller.textSnaphot {
            self.transitionInArguments = (controller.buttonFrame, controller.buttonTitle, animationSnapshot, textSnapshot)
        }
    }
    
    override public func loadDisplayNode() {
        self.displayNode = AuthorizationSequencePhoneEntryControllerNode(sharedContext: self.sharedContext, account: self.account, strings: self.presentationData.strings, theme: self.presentationData.theme, debugAction: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.view.endEditing(true)
            self?.present(debugController(sharedContext: strongSelf.sharedContext, context: nil, modal: true), in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        }, hasOtherAccounts: self.otherAccountPhoneNumbers.0 != nil)
        self.controllerNode.accountUpdated = { [weak self] account in
            guard let strongSelf = self else {
                return
            }
            strongSelf.account = account
            strongSelf.accountUpdated?(account)
        }
        self.controllerNode.retryPasskey = { [weak self] in
            guard let self else {
                return
            }
            self.loadAndPresentPasskey(force: true)
        }
        
        if let (code, name, number) = self.currentData {
            self.controllerNode.codeAndNumber = (code, name, number)
        }
        self.displayNodeDidLoad()
        
        self.controllerNode.view.disableAutomaticKeyboardHandling = [.forward, .backward]
        
        self.controllerNode.selectCountryCode = { [weak self] in
            if let strongSelf = self {
                let controller = AuthorizationSequenceCountrySelectionController(strings: strongSelf.presentationData.strings, theme: strongSelf.presentationData.theme, glass: true)
                controller.completeWithCountryCode = { code, name in
                    if let strongSelf = self, let currentData = strongSelf.currentData {
                        strongSelf.updateData(countryCode: Int32(code), countryName: name, number: currentData.2)
                        strongSelf.controllerNode.activateInput()
                    }
                }
                controller.dismissed = { 
                    self?.controllerNode.activateInput()
                }
                strongSelf.push(controller)
            }
        }
        self.controllerNode.checkPhone = { [weak self] in
            self?.nextPressed()
        }
        
        if let account = self.account {
            loadServerCountryCodes(accountManager: sharedContext.accountManager, engine: TelegramEngineUnauthorized(account: account), completion: { [weak self] in
                if let strongSelf = self {
                    strongSelf.controllerNode.updateCountryCode()
                }
            })
        } else {
            self.controllerNode.updateCountryCode()
        }
        
        if #available(iOS 16.0, *) {
            self.controllerNode.updateDisplayPasskeyLoginOption()
        }
        self.loadAndPresentPasskey(force: false)
    }
    
    private func loadAndPresentPasskey(force: Bool) {
        if #available(iOS 16.0, *) {
            Task { @MainActor [weak self] in
                guard let self, let account = self.account else {
                    return
                }
                
                let decodeBase64: (String) -> Data? = { string in
                    var string = string.replacingOccurrences(of: "-", with: "+")
                        .replacingOccurrences(of: "_", with: "/")
                    while string.count % 4 != 0 {
                        string.append("=")
                    }
                    return Data(base64Encoded: string)
                }
                
                let engine = TelegramEngineUnauthorized(account: account)
                let passkeyDataString = await engine.auth.requestPasskeyLoginData(apiId: self.apiId, apiHash: self.apiHash).get()
                guard let passkeyDataString, let passkeyData = passkeyDataString.data(using: .utf8) else {
                    self.controllerNode.updateDisplayPasskeyLoginOption()
                    if let validLayout = self.validLayout {
                        self.containerLayoutUpdated(validLayout, transition: .immediate)
                    }
                    return
                }
                guard let params = try? JSONSerialization.jsonObject(with: passkeyData) as? [String: Any] else {
                    self.controllerNode.updateDisplayPasskeyLoginOption()
                    if let validLayout = self.validLayout {
                        self.containerLayoutUpdated(validLayout, transition: .immediate)
                    }
                    return
                }
                guard let pkDict = params["publicKey"] as? [String: Any] else {
                    self.controllerNode.updateDisplayPasskeyLoginOption()
                    if let validLayout = self.validLayout {
                        self.containerLayoutUpdated(validLayout, transition: .immediate)
                    }
                    return
                }
                
                guard let challengeBase64 = pkDict["challenge"] as? String else {
                    self.controllerNode.updateDisplayPasskeyLoginOption()
                    if let validLayout = self.validLayout {
                        self.containerLayoutUpdated(validLayout, transition: .immediate)
                    }
                    return
                }
                guard let challengeData = decodeBase64(challengeBase64) else {
                    self.controllerNode.updateDisplayPasskeyLoginOption()
                    if let validLayout = self.validLayout {
                        self.containerLayoutUpdated(validLayout, transition: .immediate)
                    }
                    return
                }
                
                let serverRpId = pkDict["rpId"] as? String
                var rpIds: [String] = []
                if let serverRpId, !serverRpId.isEmpty {
                    rpIds.append(serverRpId)
                }
                for candidate in ["telegram.org", "swiftgram.app"] {
                    if !rpIds.contains(candidate) {
                        rpIds.append(candidate)
                    }
                }
                
                let requests: [ASAuthorizationRequest] = rpIds.map { rpId in
                    let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
                    return platformProvider.createCredentialAssertionRequest(challenge: challengeData)
                }
                
                let authController = ASAuthorizationController(authorizationRequests: requests)
                authController.delegate = self
                authController.presentationContextProvider = self
                if force {
                    authController.performRequests()
                } else {
                    authController.performRequests(options: [.preferImmediatelyAvailableCredentials])
                }
            }
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor [weak self] in
            guard let self, let account = self.account else {
                return
            }
            
            let encodeBase64URL: (Data) -> String = { data in
                var string = data.base64EncodedString()
                string = string
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                string = string.replacingOccurrences(of: "=", with: "")
                return string
            }
            
            if #available(iOS 17.0, *) {
                if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
                    guard let clientData = String(data: credential.rawClientDataJSON, encoding: .utf8) else {
                        return
                    }
                    guard let userHandle = String(data: credential.userID, encoding: .utf8) else {
                        return
                    }
                    let passkey = AuthorizationPasskeyData(
                        id: encodeBase64URL(credential.credentialID),
                        clientData: clientData,
                        authenticatorData: credential.rawAuthenticatorData,
                        signature: credential.signature,
                        userHandle: userHandle
                    )
                    self.loginWithPasskey?(passkey, self.controllerNode.syncContacts)
                    
                    /*if let clientData = String(data: credential.rawClientDataJSON, encoding: .utf8), let attestationObject = credential.rawAttestationObject {
                        let passkey = await component.context.engine.auth.requestCreatePasskey(id: encodeBase64URL(credential.credentialID), clientData: clientData, attestationObject: attestationObject).get()
                        if let passkey {
                            if self.passkeysData == nil {
                                self.passkeysData = []
                                self.passkeysData?.insert(passkey, at: 0)
                            }
                            self.state?.updated(transition: .immediate)
                        }
                    }*/
                    let _ = account
                    let _ = credential
                }
            }
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        self.controllerNode.updateDisplayPasskeyLoginOption()
        if let validLayout = self.validLayout {
            self.containerLayoutUpdated(validLayout, transition: .immediate)
        }
    }
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = self.view.window?.windowScene else {
            preconditionFailure()
        }
        return ASPresentationAnchor(windowScene: windowScene)
    }
    
    public func updateCountryCode() {
        self.controllerNode.updateCountryCode()
    }
    
    private var animatingIn = false
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.shouldAnimateIn {
            self.animatingIn = true
            if let (buttonFrame, buttonTitle, animationSnapshot, textSnapshot) = self.transitionInArguments {
                self.controllerNode.willAnimateIn(buttonFrame: buttonFrame, buttonTitle: buttonTitle, animationSnapshot: animationSnapshot, textSnapshot: textSnapshot)
            }
            Queue.mainQueue().justDispatch {
                self.controllerNode.activateInput()
            }
        } else {
            self.controllerNode.activateInput()
        }
    }
    
    @objc private func apiSettingsPressed() {
        self.presentApiCredentialsAlert()
    }
    
    private func sanitizeAndValidateApiCredentials(idString: String, hashString: String) -> (apiId: Int32, apiHash: String, error: String?) {
        var cleanId = idString.trimmingCharacters(in: .whitespacesAndNewlines)
        for ch in ["\"", "'", "«", "»", " ", "\u{00A0}", "\t"] {
            cleanId = cleanId.replacingOccurrences(of: ch, with: "")
        }
        
        var cleanHash = hashString.trimmingCharacters(in: .whitespacesAndNewlines)
        for ch in ["\"", "'", "«", "»", " ", "\u{00A0}", "\t"] {
            cleanHash = cleanHash.replacingOccurrences(of: ch, with: "")
        }
        cleanHash = cleanHash.lowercased()
        
        let isRussian = self.presentationData.strings.baseLanguageCode.hasPrefix("ru")
        
        guard !cleanId.isEmpty else {
            let msg = isRussian ? "Поле App api_id не должно быть пустым." : "App api_id cannot be empty."
            return (0, "", msg)
        }
        
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: cleanId)) else {
            let msg = isRussian ? "App api_id должен содержать только цифры (например: 20401234)." : "App api_id must contain digits only (e.g. 20401234)."
            return (0, "", msg)
        }
        
        guard let parsedId = Int32(cleanId), parsedId > 0 else {
            let msg = isRussian ? "Некорректное значение App api_id (слишком большое число или меньше нуля)." : "Invalid App api_id value."
            return (0, "", msg)
        }
        
        guard !cleanHash.isEmpty else {
            let msg = isRussian ? "Поле App api_hash не должно быть пустым." : "App api_hash cannot be empty."
            return (0, "", msg)
        }
        
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
        guard cleanHash.count == 32 && hexCharacterSet.isSuperset(of: CharacterSet(charactersIn: cleanHash)) else {
            let msg = isRussian ? "App api_hash должен состоять ровно из 32 шестнадцатеричных символов (0-9, a-f)." : "App api_hash must be exactly 32 hex characters (0-9, a-f)."
            return (0, "", msg)
        }
        
        return (parsedId, cleanHash, nil)
    }
    
    private func resetToDefaultApiCredentials(completion: (() -> Void)? = nil) {
        UserDefaults.standard.removeObject(forKey: "custom_telegram_api_id")
        UserDefaults.standard.removeObject(forKey: "custom_telegram_api_hash")
        UserDefaults.standard.set(true, forKey: "custom_telegram_api_prompted")
        UserDefaults.standard.synchronize()
        
        let defaultId: Int32 = 8
        let defaultHash = "7245de8e747a0d6fbe11f7cc14fcc0bb"
        self.apiId = defaultId
        self.apiHash = defaultHash
        self.account?.updateApiCredentials(apiId: defaultId, apiHash: defaultHash, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion?()
            }
        })
        self.loadAndPresentPasskey(force: false)
    }

    private func presentApiCredentialsAlert(initialId: String? = nil, initialHash: String? = nil, completion: (() -> Void)? = nil) {
        let currentApiId = UserDefaults.standard.integer(forKey: "custom_telegram_api_id")
        let currentApiHash = UserDefaults.standard.string(forKey: "custom_telegram_api_hash") ?? ""
        
        let isRussian = self.presentationData.strings.baseLanguageCode.hasPrefix("ru")
        let title = isRussian ? "Настройка Telegram API" : "Telegram API Settings"
        let message = isRussian ? "Введите App api_id и api_hash с сайта my.telegram.org.\nДля использования по умолчанию (ID 8) нажмите «По умолчанию»." : "Enter App api_id and api_hash from my.telegram.org.\nTo use default credentials (ID 8), tap \"Use Default\"."
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "App api_id (например: 12345678)"
            textField.keyboardType = .numberPad
            if let initialId = initialId {
                textField.text = initialId
            } else if currentApiId > 0 {
                textField.text = "\(currentApiId)"
            }
        }
        
        alert.addTextField { textField in
            textField.placeholder = "App api_hash"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            if let initialHash = initialHash {
                textField.text = initialHash
            } else if !currentApiHash.isEmpty {
                textField.text = currentApiHash
            }
        }
        
        let saveTitle = isRussian ? "Сохранить" : "Save"
        alert.addAction(UIAlertAction(title: saveTitle, style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            let idText = alert.textFields?[0].text ?? ""
            let hashText = alert.textFields?[1].text ?? ""
            
            let (parsedId, cleanHash, validationError) = strongSelf.sanitizeAndValidateApiCredentials(idString: idText, hashString: hashText)
            if let validationError = validationError {
                let errorAlert = UIAlertController(title: isRussian ? "Ошибка валидации" : "Validation Error", message: validationError, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: isRussian ? "Исправить" : "Fix", style: .default, handler: { [weak strongSelf] _ in
                    strongSelf?.presentApiCredentialsAlert(initialId: idText, initialHash: hashText, completion: completion)
                }))
                errorAlert.addAction(UIAlertAction(title: isRussian ? "По умолчанию" : "Use Default", style: .destructive, handler: { [weak strongSelf] _ in
                    strongSelf?.resetToDefaultApiCredentials(completion: completion)
                }))
                strongSelf.present(errorAlert, animated: true, completion: nil)
                return
            }
            
            UserDefaults.standard.set(Int(parsedId), forKey: "custom_telegram_api_id")
            UserDefaults.standard.set(cleanHash, forKey: "custom_telegram_api_hash")
            UserDefaults.standard.set(true, forKey: "custom_telegram_api_prompted")
            UserDefaults.standard.synchronize()
            
            strongSelf.apiId = parsedId
            strongSelf.apiHash = cleanHash
            strongSelf.account?.updateApiCredentials(apiId: parsedId, apiHash: cleanHash, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completion?()
                }
            })
            strongSelf.loadAndPresentPasskey(force: false)
        }))
        
        let defaultTitle = isRussian ? "По умолчанию" : "Use Default"
        alert.addAction(UIAlertAction(title: defaultTitle, style: .cancel, handler: { [weak self] _ in
            self?.resetToDefaultApiCredentials(completion: completion)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.animatingIn {
            self.controllerNode.activateInput()
        }
        
        if !UserDefaults.standard.bool(forKey: "custom_telegram_api_prompted") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.presentApiCredentialsAlert()
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let confirmationController = self.confirmationController {
            confirmationController.transitionOut()
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        let hadLayout = self.validLayout != nil
        self.validLayout = layout
        
        if !hadLayout {
            self.updateNavigationItems()
        }
    
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
        
        if self.shouldAnimateIn, let inputHeight = layout.inputHeight, inputHeight > 0.0 {
            if let (buttonFrame, buttonTitle, animationSnapshot, textSnapshot) = self.transitionInArguments {
                self.shouldAnimateIn = false
                self.controllerNode.animateIn(buttonFrame: buttonFrame, buttonTitle: buttonTitle, animationSnapshot: animationSnapshot, textSnapshot: textSnapshot)
            }
        }
    }
    
    public func dismissConfirmation() {
        self.confirmationController?.dismissAnimated()
        self.confirmationController = nil
    }
    
    @objc func nextPressed() {
        guard self.confirmationController == nil else {
            return
        }
        let (_, _, number) = self.controllerNode.codeAndNumber
        if !number.isEmpty {
            if !UserDefaults.standard.bool(forKey: "custom_telegram_api_prompted") {
                self.presentApiCredentialsAlert(completion: { [weak self] in
                    self?.nextPressed()
                })
                return
            }
            let logInNumber = cleanPhoneNumber(self.controllerNode.currentNumber, removePlus: true)
            var existing: (String, AccountRecordId)?
            for (number, id, isTestingEnvironment) in self.otherAccountPhoneNumbers.1 {
                if isTestingEnvironment == self.isTestingEnvironment && cleanPhoneNumber(number, removePlus: true) == logInNumber {
                    existing = (number, id)
                }
            }
            
            if let (_, id) = existing {
                var actions: [TextAlertAction] = []
                if let (current, _, _) = self.otherAccountPhoneNumbers.0, logInNumber != cleanPhoneNumber(current, removePlus: true) {
                    actions.append(TextAlertAction(type: .genericAction, title: self.presentationData.strings.Login_PhoneNumberAlreadyAuthorizedSwitch, action: { [weak self] in
                        self?.sharedContext.switchToAccount(id: id, fromSettingsController: nil, withChatListController: nil)
                        self?.back()
                    }))
                }
                actions.append(TextAlertAction(type: .defaultAction, title: self.presentationData.strings.Common_OK, action: {}))
                self.present(textAlertController(sharedContext: self.sharedContext, title: nil, text: self.presentationData.strings.Login_PhoneNumberAlreadyAuthorized, actions: actions), in: .window(.root))
            } else {
                // MARK: Swiftgram
                if (number == "0000000000") {
                    self.sharedContext.beginNewAuth(testingEnvironment: true)
                    return
                }
                if let validLayout = self.validLayout, validLayout.size.width > 320.0 {
                    let (code, formattedNumber) = self.controllerNode.formattedCodeAndNumber

                    let confirmationController = PhoneConfirmationController(theme: self.presentationData.theme, strings: self.presentationData.strings, code: code, number: formattedNumber, sourceController: self)
                    confirmationController.proceed = { [weak self] in
                        if let strongSelf = self {
                            strongSelf.loginWithNumber?(strongSelf.controllerNode.currentNumber, strongSelf.controllerNode.syncContacts)
                        }
                    }
                    (self.navigationController as? NavigationController)?.presentOverlay(controller: confirmationController, inGlobal: true, blockInteraction: true)
                    self.confirmationController = confirmationController
                } else {
                    var actions: [TextAlertAction] = []
                    actions.append(TextAlertAction(type: .genericAction, title: self.presentationData.strings.Login_Edit, action: {}))
                    actions.append(TextAlertAction(type: .defaultAction, title: self.presentationData.strings.Login_Yes, action: { [weak self] in
                        if let strongSelf = self {
                            strongSelf.loginWithNumber?(strongSelf.controllerNode.currentNumber, strongSelf.controllerNode.syncContacts)
                        }
                    }))
                    self.present(textAlertController(sharedContext: self.sharedContext, title: logInNumber, text: self.presentationData.strings.Login_PhoneNumberConfirmation, actions: actions), in: .window(.root))
                }
            }
        } else {
            self.hapticFeedback.error()
            self.controllerNode.animateError()
        }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
