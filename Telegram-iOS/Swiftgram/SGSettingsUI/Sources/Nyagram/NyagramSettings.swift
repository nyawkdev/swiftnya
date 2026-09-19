import Foundation
import SGAppGroupIdentifier

public struct NyagramGift: Codable, Equatable, Identifiable {
    public let id: String
    public var name: String
    public var number: Int
    public var modelIndex: Int
    public var backdropIndex: Int
    public var patternIndex: Int
    public var rarity: Int
    public var tonPrice: Double
    public var creationDate: Double
    public var isWorn: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        number: Int,
        modelIndex: Int,
        backdropIndex: Int,
        patternIndex: Int,
        rarity: Int,
        tonPrice: Double = 15.0,
        creationDate: Double = Date().timeIntervalSince1970,
        isWorn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.number = number
        self.modelIndex = modelIndex
        self.backdropIndex = backdropIndex
        self.patternIndex = patternIndex
        self.rarity = rarity
        self.tonPrice = tonPrice
        self.creationDate = creationDate
        self.isWorn = isWorn
    }
}

public struct NyagramBackupPayload: Codable {
    public let version: String
    public let author: String
    public let timestamp: Double
    public let gifts: [NyagramGift]
    public let hideRegularGifts: Bool
    public let collectibleUsername: String?
    public let usernameTonPrice: Double?
    public let usernameDate: Double?
    public let collectibleNumber: String?
    public let numberTonPrice: Double?
    public let numberDate: Double?
    public let ratingLevel: Int?
    public let ratingPoints: Int64?
    public let pinnedChannelUsername: String?
    public let pinnedChannelTitle: String?
    public let starsBalance: Int64
    public let gramBalance: Int64
    public let spendStarsInMarket: Bool
    public let walletBalances: [String: Double]
}

public final class NyagramSettings {
    public static let shared = NyagramSettings()
    
    private let lock = NSLock()
    private let defaults: UserDefaults
    
    private enum Keys: String {
        case gifts = "nyagram_gifts_v1"
        case hideRegularGifts = "nyagram_hide_regular_gifts"
        case collectibleUsername = "nyagram_collectible_username"
        case usernameTonPrice = "nyagram_username_ton_price"
        case usernameDate = "nyagram_username_date"
        case collectibleNumber = "nyagram_collectible_number"
        case numberTonPrice = "nyagram_number_ton_price"
        case numberDate = "nyagram_number_date"
        case ratingLevel = "nyagram_rating_level"
        case ratingPoints = "nyagram_rating_points"
        case pinnedChannelUsername = "nyagram_pinned_channel_username"
        case pinnedChannelTitle = "nyagram_pinned_channel_title"
        case starsBalance = "nyagram_stars_balance"
        case gramBalance = "nyagram_gram_balance"
        case spendStarsInMarket = "nyagram_spend_stars_in_market"
        case walletBalances = "nyagram_wallet_balances"
    }
    
    private init() {
        let appGroup = sgAppGroupIdentifier()
        if let groupDefaults = UserDefaults(suiteName: appGroup) {
            self.defaults = groupDefaults
        } else {
            self.defaults = UserDefaults.standard
        }
    }
    
    private func save(_ value: Any?, forKey key: Keys) {
        if let value = value {
            self.defaults.set(value, forKey: key.rawValue)
            if self.defaults !== UserDefaults.standard {
                UserDefaults.standard.set(value, forKey: key.rawValue)
            }
        } else {
            self.defaults.removeObject(forKey: key.rawValue)
            if self.defaults !== UserDefaults.standard {
                UserDefaults.standard.removeObject(forKey: key.rawValue)
            }
        }
    }
    
    // MARK: - Gifts
    public var gifts: [NyagramGift] {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            let data = self.defaults.data(forKey: Keys.gifts.rawValue) ?? UserDefaults.standard.data(forKey: Keys.gifts.rawValue)
            guard let data = data,
                  let items = try? JSONDecoder().decode([NyagramGift].self, from: data) else {
                return []
            }
            return items
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let data = try? JSONEncoder().encode(newValue) {
                self.save(data, forKey: Keys.gifts)
            }
        }
    }
    
    public var activeGift: NyagramGift? {
        return self.gifts.first(where: { $0.isWorn })
    }
    
    public func setGiftWorn(id: String, worn: Bool) {
        var current = self.gifts
        for i in 0..<current.count {
            if current[i].id == id {
                current[i].isWorn = worn
            } else if worn {
                // Only one gift can be worn at a time
                current[i].isWorn = false
            }
        }
        self.gifts = current
    }
    
    public func addGift(_ gift: NyagramGift) {
        var current = self.gifts
        current.insert(gift, at: 0)
        self.gifts = current
    }
    
    public func removeGift(id: String) {
        var current = self.gifts
        current.removeAll(where: { $0.id == id })
        self.gifts = current
    }
    
    // MARK: - Profile Settings
    public var hideRegularGifts: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.bool(forKey: Keys.hideRegularGifts.rawValue) || UserDefaults.standard.bool(forKey: Keys.hideRegularGifts.rawValue)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.hideRegularGifts)
        }
    }
    
    public var collectibleUsername: String? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.collectibleUsername.rawValue) ?? UserDefaults.standard.string(forKey: Keys.collectibleUsername.rawValue)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.collectibleUsername)
        }
    }
    
    public var usernameTonPrice: Double? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            let val = self.defaults.double(forKey: Keys.usernameTonPrice.rawValue)
            if val > 0 { return val }
            let std = UserDefaults.standard.double(forKey: Keys.usernameTonPrice.rawValue)
            return std > 0 ? std : nil
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.usernameTonPrice)
        }
    }
    
    public var usernameDate: Double? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            let val = self.defaults.double(forKey: Keys.usernameDate.rawValue)
            if val > 0 { return val }
            let std = UserDefaults.standard.double(forKey: Keys.usernameDate.rawValue)
            return std > 0 ? std : nil
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.usernameDate)
        }
    }
    
    public var collectibleNumber: String? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.collectibleNumber.rawValue) ?? UserDefaults.standard.string(forKey: Keys.collectibleNumber.rawValue)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.collectibleNumber)
        }
    }
    
    public var numberTonPrice: Double? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            let val = self.defaults.double(forKey: Keys.numberTonPrice.rawValue)
            if val > 0 { return val }
            let std = UserDefaults.standard.double(forKey: Keys.numberTonPrice.rawValue)
            return std > 0 ? std : nil
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.numberTonPrice)
        }
    }
    
    public var numberDate: Double? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            let val = self.defaults.double(forKey: Keys.numberDate.rawValue)
            if val > 0 { return val }
            let std = UserDefaults.standard.double(forKey: Keys.numberDate.rawValue)
            return std > 0 ? std : nil
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.numberDate)
        }
    }
    
    public var ratingLevel: Int? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            let val = self.defaults.integer(forKey: Keys.ratingLevel.rawValue)
            if val > 0 { return val }
            let std = UserDefaults.standard.integer(forKey: Keys.ratingLevel.rawValue)
            return std > 0 ? std : nil
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.ratingLevel)
        }
    }
    
    public var ratingPoints: Int64? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let obj = (self.defaults.object(forKey: Keys.ratingPoints.rawValue) ?? UserDefaults.standard.object(forKey: Keys.ratingPoints.rawValue)) as? NSNumber {
                return obj.int64Value
            }
            return nil
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let val = newValue {
                self.save(NSNumber(value: val), forKey: Keys.ratingPoints)
            } else {
                self.save(nil as Any?, forKey: Keys.ratingPoints)
            }
        }
    }
    
    public var pinnedChannelUsername: String? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.pinnedChannelUsername.rawValue) ?? UserDefaults.standard.string(forKey: Keys.pinnedChannelUsername.rawValue)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.pinnedChannelUsername)
        }
    }
    
    public var pinnedChannelTitle: String? {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.string(forKey: Keys.pinnedChannelTitle.rawValue) ?? UserDefaults.standard.string(forKey: Keys.pinnedChannelTitle.rawValue)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.pinnedChannelTitle)
        }
    }
    
    // MARK: - Balance
    public var starsBalance: Int64 {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let obj = (self.defaults.object(forKey: Keys.starsBalance.rawValue) ?? UserDefaults.standard.object(forKey: Keys.starsBalance.rawValue)) as? NSNumber {
                return obj.int64Value
            }
            return 0
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(NSNumber(value: max(0, newValue)), forKey: Keys.starsBalance)
        }
    }
    
    public var gramBalance: Int64 {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let obj = (self.defaults.object(forKey: Keys.gramBalance.rawValue) ?? UserDefaults.standard.object(forKey: Keys.gramBalance.rawValue)) as? NSNumber {
                return obj.int64Value
            }
            return 0
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(NSNumber(value: max(0, newValue)), forKey: Keys.gramBalance)
        }
    }
    
    public var spendStarsInMarket: Bool {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.defaults.bool(forKey: Keys.spendStarsInMarket.rawValue) || UserDefaults.standard.bool(forKey: Keys.spendStarsInMarket.rawValue)
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.spendStarsInMarket)
        }
    }
    
    // MARK: - Wallet Balances
    public static let defaultWalletBalances: [String: Double] = [
        "TON": 125.0,
        "USDT": 2500.0,
        "BTC": 0.15,
        "NOT": 120000.0,
        "DOGE": 30000.0,
        "TRX": 15000.0,
        "ETH": 1.5,
        "SOL": 25.0
    ]
    
    public var walletBalances: [String: Double] {
        get {
            self.lock.lock()
            defer { self.lock.unlock() }
            if let dict = (self.defaults.dictionary(forKey: Keys.walletBalances.rawValue) ?? UserDefaults.standard.dictionary(forKey: Keys.walletBalances.rawValue)) as? [String: Double] {
                return dict
            }
            return NyagramSettings.defaultWalletBalances
        }
        set {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.save(newValue, forKey: Keys.walletBalances)
        }
    }
    
    // MARK: - Backup & Restore
    public func createBackupPayload() -> Data? {
        let payload = NyagramBackupPayload(
            version: "1.0",
            author: "nyawkdev",
            timestamp: Date().timeIntervalSince1970,
            gifts: self.gifts,
            hideRegularGifts: self.hideRegularGifts,
            collectibleUsername: self.collectibleUsername,
            usernameTonPrice: self.usernameTonPrice,
            usernameDate: self.usernameDate,
            collectibleNumber: self.collectibleNumber,
            numberTonPrice: self.numberTonPrice,
            numberDate: self.numberDate,
            ratingLevel: self.ratingLevel,
            ratingPoints: self.ratingPoints,
            pinnedChannelUsername: self.pinnedChannelUsername,
            pinnedChannelTitle: self.pinnedChannelTitle,
            starsBalance: self.starsBalance,
            gramBalance: self.gramBalance,
            spendStarsInMarket: self.spendStarsInMarket,
            walletBalances: self.walletBalances
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(payload)
    }
    
    public func restoreFromPayload(data: Data) -> Bool {
        guard let payload = try? JSONDecoder().decode(NyagramBackupPayload.self, from: data) else {
            return false
        }
        self.gifts = payload.gifts
        self.hideRegularGifts = payload.hideRegularGifts
        self.collectibleUsername = payload.collectibleUsername
        self.usernameTonPrice = payload.usernameTonPrice
        self.usernameDate = payload.usernameDate
        self.collectibleNumber = payload.collectibleNumber
        self.numberTonPrice = payload.numberTonPrice
        self.numberDate = payload.numberDate
        self.ratingLevel = payload.ratingLevel
        self.ratingPoints = payload.ratingPoints
        self.pinnedChannelUsername = payload.pinnedChannelUsername
        self.pinnedChannelTitle = payload.pinnedChannelTitle
        self.starsBalance = payload.starsBalance
        self.gramBalance = payload.gramBalance
        self.spendStarsInMarket = payload.spendStarsInMarket
        self.walletBalances = payload.walletBalances
        return true
    }
    
    public func deleteAllData() {
        self.gifts = []
        self.hideRegularGifts = false
        self.collectibleUsername = nil
        self.usernameTonPrice = nil
        self.usernameDate = nil
        self.collectibleNumber = nil
        self.numberTonPrice = nil
        self.numberDate = nil
        self.ratingLevel = nil
        self.ratingPoints = nil
        self.pinnedChannelUsername = nil
        self.pinnedChannelTitle = nil
        self.starsBalance = 0
        self.gramBalance = 0
        self.spendStarsInMarket = false
        self.walletBalances = NyagramSettings.defaultWalletBalances
    }
}
