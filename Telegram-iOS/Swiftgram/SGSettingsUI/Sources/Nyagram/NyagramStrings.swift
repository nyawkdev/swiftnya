import Foundation

public enum NyagramLanguage {
    case ru
    case en
    
    public static var current: NyagramLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "ru"
        if preferred.hasPrefix("ru") || preferred.hasPrefix("uk") || preferred.hasPrefix("be") {
            return .ru
        }
        return .en
    }
}

public struct NyagramStrings {
    public static func get(_ key: Key, _ lang: NyagramLanguage = NyagramLanguage.current) -> String {
        switch lang {
        case .ru:
            return ruStrings[key] ?? enStrings[key] ?? key.rawValue
        case .en:
            return enStrings[key] ?? key.rawValue
        }
    }
    
    public enum Key: String {
        // Main Menu
        case title = "nyagram_title"
        case version = "nyagram_version"
        case sectionMain = "nyagram_section_main"
        case sectionMore = "nyagram_section_more"
        case gifts = "nyagram_gifts"
        case giftsSub = "nyagram_gifts_sub"
        case profile = "nyagram_profile"
        case profileSub = "nyagram_profile_sub"
        case balance = "nyagram_balance"
        case balanceSub = "nyagram_balance_sub"
        case backup = "nyagram_backup"
        case backupSub = "nyagram_backup_sub"
        case about = "nyagram_about"
        case aboutSub = "nyagram_about_sub"
        
        // Gifts & Constructor
        case giftsTitle = "nyagram_gifts_title"
        case giftsEmpty = "nyagram_gifts_empty"
        case giftsCreate = "nyagram_gifts_create"
        case giftsWear = "nyagram_gifts_wear"
        case giftsTakeOff = "nyagram_gifts_take_off"
        case giftsWorn = "nyagram_gifts_worn"
        case giftsDelete = "nyagram_gifts_delete"
        case giftsRarity = "nyagram_gifts_rarity"
        case giftsModel = "nyagram_gifts_model"
        case giftsBackdrop = "nyagram_gifts_backdrop"
        case giftsPattern = "nyagram_gifts_pattern"
        case giftsNumber = "nyagram_gifts_number"
        case giftsPrice = "nyagram_gifts_price"
        case giftsCount = "nyagram_gifts_count"
        case giftsGenerate = "nyagram_gifts_generate"
        case giftsRandomNumber = "nyagram_gifts_random_number"
        case giftsSuccessCreated = "nyagram_gifts_success_created"
        
        // Profile
        case profileTitle = "nyagram_profile_title"
        case hideRegularGifts = "nyagram_hide_regular_gifts"
        case hideRegularGiftsSub = "nyagram_hide_regular_gifts_sub"
        case collectibleUsername = "nyagram_collectible_username"
        case collectibleUsernameSub = "nyagram_collectible_username_sub"
        case collectibleNumber = "nyagram_collectible_number"
        case collectibleNumberSub = "nyagram_collectible_number_sub"
        case rating = "nyagram_rating"
        case ratingSub = "nyagram_rating_sub"
        case ratingLevel = "nyagram_rating_level"
        case ratingPoints = "nyagram_rating_points"
        case pinnedChannel = "nyagram_pinned_channel"
        case pinnedChannelSub = "nyagram_pinned_channel_sub"
        case priceInTon = "nyagram_price_in_ton"
        case purchaseDate = "nyagram_purchase_date"
        case previewCard = "nyagram_preview_card"
        case remove = "nyagram_remove"
        case save = "nyagram_save"
        case copyLink = "nyagram_copy_link"
        case linkCopied = "nyagram_link_copied"
        
        // Balance
        case balanceTitle = "nyagram_balance_title"
        case starsBalance = "nyagram_stars_balance"
        case gramBalance = "nyagram_gram_balance"
        case add100 = "nyagram_add_100"
        case add1000 = "nyagram_add_1000"
        case add10000 = "nyagram_add_10000"
        case customAmount = "nyagram_custom_amount"
        case spendInMarket = "nyagram_spend_in_market"
        case spendInMarketSub = "nyagram_spend_in_market_sub"
        case resetBalance = "nyagram_reset_balance"
        
        // Backup
        case backupTitle = "nyagram_backup_title"
        case backupCreate = "nyagram_backup_create"
        case backupRestore = "nyagram_backup_restore"
        case backupDeleteAll = "nyagram_backup_delete_all"
        case backupDeleteAllConfirmTitle = "nyagram_backup_delete_all_confirm_title"
        case backupDeleteAllConfirmBody = "nyagram_backup_delete_all_confirm_body"
        case backupRestoreSuccess = "nyagram_backup_restore_success"
        case backupExportSuccess = "nyagram_backup_export_success"
        
        // Wallet
        case walletSecretTitle = "nyagram_wallet_secret_title"
        case walletSecretSub = "nyagram_wallet_secret_sub"
        case walletSaved = "nyagram_wallet_saved"
        
        // General
        case cancel = "nyagram_cancel"
        case done = "nyagram_done"
        case close = "nyagram_close"
        case delete = "nyagram_delete"
        case author = "nyagram_author"
        case aboutDescription = "nyagram_about_description"
    }
    
    private static let ruStrings: [Key: String] = [
        .title: "Nyagram",
        .version: "Версия 1.0 · nyawkdev",
        .sectionMain: "Nyagram",
        .sectionMore: "Дополнительно",
        .gifts: "Мои подарки",
        .giftsSub: "Библиотека, активный подарок и конструктор",
        .profile: "NFT-профиль",
        .profileSub: "Юзернейм, номер, рейтинг и закреплённый канал",
        .balance: "Баланс",
        .balanceSub: "Настройка Stars и GRAM",
        .backup: "Резервная копия",
        .backupSub: "Экспорт и восстановление профиля",
        .about: "О плагине",
        .aboutSub: "Версия 1.0 от nyawkdev",
        
        .giftsTitle: "Мои подарки",
        .giftsEmpty: "Пока нет созданных подарков",
        .giftsCreate: "NFT-конструктор",
        .giftsWear: "Надеть",
        .giftsTakeOff: "Снять",
        .giftsWorn: "Надет",
        .giftsDelete: "Удалить",
        .giftsRarity: "Редкость",
        .giftsModel: "Модель",
        .giftsBackdrop: "Фон",
        .giftsPattern: "Узор",
        .giftsNumber: "Номер подарка",
        .giftsPrice: "Цена (TON)",
        .giftsCount: "Количество",
        .giftsGenerate: "Создать подарок",
        .giftsRandomNumber: "Случайный номер",
        .giftsSuccessCreated: "Подарок успешно создан!",
        
        .profileTitle: "NFT-профиль",
        .hideRegularGifts: "Скрыть обычные подарки",
        .hideRegularGiftsSub: "Скрывать в профиле все подарки, кроме NFT",
        .collectibleUsername: "Коллекционный юзернейм",
        .collectibleUsernameSub: "Отображается в профиле и чатах",
        .collectibleNumber: "Коллекционный номер",
        .collectibleNumberSub: "Анонимный номер в формате +888...",
        .rating: "Рейтинг профиля",
        .ratingSub: "Звёздный бейдж уровня в профиле",
        .ratingLevel: "Уровень",
        .ratingPoints: "Очки рейтинга",
        .pinnedChannel: "Закреплённый канал",
        .pinnedChannelSub: "Ссылка или @username канала в профиле",
        .priceInTon: "Цена покупки (TON)",
        .purchaseDate: "Дата приобретения",
        .previewCard: "Предпросмотр карточки",
        .remove: "Удалить",
        .save: "Сохранить",
        .copyLink: "Скопировать ссылку",
        .linkCopied: "Ссылка скопирована в буфер обмена",
        
        .balanceTitle: "Баланс",
        .starsBalance: "Баланс Stars ⭐️",
        .gramBalance: "Баланс GRAM",
        .add100: "+100",
        .add1000: "+1 000",
        .add10000: "+10 000",
        .customAmount: "Произвольная сумма",
        .spendInMarket: "Тратить звёзды в маркете",
        .spendInMarketSub: "Покупки в маркете списывают баланс. Если выключить, покупки бесплатны — баланс остаётся на месте.",
        .resetBalance: "Сбросить баланс",
        
        .backupTitle: "Резервная копия",
        .backupCreate: "Создать резервную копию",
        .backupRestore: "Восстановить из файла",
        .backupDeleteAll: "Удалить все мои данные",
        .backupDeleteAllConfirmTitle: "Удалить все данные?",
        .backupDeleteAllConfirmBody: "Подарки, юзернейм, номер, рейтинг, закреплённый канал и баланс будут сброшены. Восстановить их можно будет только из файла резервной копии.",
        .backupRestoreSuccess: "Данные успешно восстановлены!",
        .backupExportSuccess: "Копия готова к сохранению",
        
        .walletSecretTitle: "Баланс Кошелька",
        .walletSecretSub: "Настройка отображаемых балансов монет",
        .walletSaved: "Баланс обновлён!",
        
        .cancel: "Отмена",
        .done: "Готово",
        .close: "Закрыть",
        .delete: "Удалить",
        .author: "Автор: nyawkdev",
        .aboutDescription: "Nyagram v1.0\nРазработано nyawkdev.\nПолная автономность, локальная обработка данных без сторонних серверов и телеметрии. Поддержка LiveContainer."
    ]
    
    private static let enStrings: [Key: String] = [
        .title: "Nyagram",
        .version: "Version 1.0 · nyawkdev",
        .sectionMain: "Nyagram",
        .sectionMore: "More",
        .gifts: "My gifts",
        .giftsSub: "Library, active gift and constructor",
        .profile: "NFT profile",
        .profileSub: "Username, number, rating and pinned channel",
        .balance: "Balance",
        .balanceSub: "Set up Stars and GRAM",
        .backup: "Backup",
        .backupSub: "Export and restore profile",
        .about: "About",
        .aboutSub: "Version 1.0 by nyawkdev",
        
        .giftsTitle: "My gifts",
        .giftsEmpty: "No created gifts yet",
        .giftsCreate: "NFT Constructor",
        .giftsWear: "Wear",
        .giftsTakeOff: "Take off",
        .giftsWorn: "Worn",
        .giftsDelete: "Delete",
        .giftsRarity: "Rarity",
        .giftsModel: "Model",
        .giftsBackdrop: "Backdrop",
        .giftsPattern: "Pattern",
        .giftsNumber: "Gift number",
        .giftsPrice: "Price (TON)",
        .giftsCount: "Quantity",
        .giftsGenerate: "Create gift",
        .giftsRandomNumber: "Random number",
        .giftsSuccessCreated: "Gift created successfully!",
        
        .profileTitle: "NFT profile",
        .hideRegularGifts: "Hide regular gifts",
        .hideRegularGiftsSub: "Hide all non-NFT gifts on your profile",
        .collectibleUsername: "Collectible username",
        .collectibleUsernameSub: "Displayed across profile and chats",
        .collectibleNumber: "Collectible number",
        .collectibleNumberSub: "Anonymous number in +888... format",
        .rating: "Profile rating",
        .ratingSub: "Star level badge on profile",
        .ratingLevel: "Level",
        .ratingPoints: "Rating points",
        .pinnedChannel: "Pinned channel",
        .pinnedChannelSub: "Channel link or @username on profile",
        .priceInTon: "Purchase price (TON)",
        .purchaseDate: "Purchase date",
        .previewCard: "Preview card",
        .remove: "Remove",
        .save: "Save",
        .copyLink: "Copy link",
        .linkCopied: "Link copied to clipboard",
        
        .balanceTitle: "Balance",
        .starsBalance: "Stars ⭐️ Balance",
        .gramBalance: "GRAM Balance",
        .add100: "+100",
        .add1000: "+1 000",
        .add10000: "+10 000",
        .customAmount: "Custom amount",
        .spendInMarket: "Spend stars in the market",
        .spendInMarketSub: "Market purchases deduct balance. When off, purchases are free and balance stays put.",
        .resetBalance: "Reset balance",
        
        .backupTitle: "Backup",
        .backupCreate: "Create a backup",
        .backupRestore: "Restore from backup",
        .backupDeleteAll: "Delete all my data",
        .backupDeleteAllConfirmTitle: "Delete all data?",
        .backupDeleteAllConfirmBody: "Gifts, username, number, rating, pinned channel and balance will be reset. A backup is the only way back.",
        .backupRestoreSuccess: "Data successfully restored!",
        .backupExportSuccess: "Backup is ready",
        
        .walletSecretTitle: "Wallet Balance",
        .walletSecretSub: "Configure displayed coin balances",
        .walletSaved: "Balances updated!",
        
        .cancel: "Cancel",
        .done: "Done",
        .close: "Close",
        .delete: "Delete",
        .author: "Author: nyawkdev",
        .aboutDescription: "Nyagram v1.0\nDeveloped by nyawkdev.\nFully offline, local processing without external servers or telemetry. Compatible with LiveContainer."
    ]
}
