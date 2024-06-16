public extension Api {
    enum SendAsPeer: TypeConstructorDescription {
        case sendAsPeer(flags: Int32, peer: Api.Peer)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .sendAsPeer(let flags, let peer):
                    if boxed {
                        buffer.appendInt32(-1206095820)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    peer.serialize(buffer, true)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .sendAsPeer(let flags, let peer):
                return ("sendAsPeer", [("flags", flags as Any), ("peer", peer as Any)])
    }
    }
    
        public static func parse_sendAsPeer(_ reader: BufferReader) -> SendAsPeer? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.Peer?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.Peer
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.SendAsPeer.sendAsPeer(flags: _1!, peer: _2!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum SendMessageAction: TypeConstructorDescription {
        case sendMessageCancelAction
        case sendMessageChooseContactAction
        case sendMessageChooseStickerAction
        case sendMessageEmojiInteraction(emoticon: String, msgId: Int32, interaction: Api.DataJSON)
        case sendMessageEmojiInteractionSeen(emoticon: String)
        case sendMessageGamePlayAction
        case sendMessageGeoLocationAction
        case sendMessageHistoryImportAction(progress: Int32)
        case sendMessageRecordAudioAction
        case sendMessageRecordRoundAction
        case sendMessageRecordVideoAction
        case sendMessageTypingAction
        case sendMessageUploadAudioAction(progress: Int32)
        case sendMessageUploadDocumentAction(progress: Int32)
        case sendMessageUploadPhotoAction(progress: Int32)
        case sendMessageUploadRoundAction(progress: Int32)
        case sendMessageUploadVideoAction(progress: Int32)
        case speakingInGroupCallAction
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .sendMessageCancelAction:
                    if boxed {
                        buffer.appendInt32(-44119819)
                    }
                    
                    break
                case .sendMessageChooseContactAction:
                    if boxed {
                        buffer.appendInt32(1653390447)
                    }
                    
                    break
                case .sendMessageChooseStickerAction:
                    if boxed {
                        buffer.appendInt32(-1336228175)
                    }
                    
                    break
                case .sendMessageEmojiInteraction(let emoticon, let msgId, let interaction):
                    if boxed {
                        buffer.appendInt32(630664139)
                    }
                    serializeString(emoticon, buffer: buffer, boxed: false)
                    serializeInt32(msgId, buffer: buffer, boxed: false)
                    interaction.serialize(buffer, true)
                    break
                case .sendMessageEmojiInteractionSeen(let emoticon):
                    if boxed {
                        buffer.appendInt32(-1234857938)
                    }
                    serializeString(emoticon, buffer: buffer, boxed: false)
                    break
                case .sendMessageGamePlayAction:
                    if boxed {
                        buffer.appendInt32(-580219064)
                    }
                    
                    break
                case .sendMessageGeoLocationAction:
                    if boxed {
                        buffer.appendInt32(393186209)
                    }
                    
                    break
                case .sendMessageHistoryImportAction(let progress):
                    if boxed {
                        buffer.appendInt32(-606432698)
                    }
                    serializeInt32(progress, buffer: buffer, boxed: false)
                    break
                case .sendMessageRecordAudioAction:
                    if boxed {
                        buffer.appendInt32(-718310409)
                    }
                    
                    break
                case .sendMessageRecordRoundAction:
                    if boxed {
                        buffer.appendInt32(-1997373508)
                    }
                    
                    break
                case .sendMessageRecordVideoAction:
                    if boxed {
                        buffer.appendInt32(-1584933265)
                    }
                    
                    break
                case .sendMessageTypingAction:
                    if boxed {
                        buffer.appendInt32(381645902)
                    }
                    
                    break
                case .sendMessageUploadAudioAction(let progress):
                    if boxed {
                        buffer.appendInt32(-212740181)
                    }
                    serializeInt32(progress, buffer: buffer, boxed: false)
                    break
                case .sendMessageUploadDocumentAction(let progress):
                    if boxed {
                        buffer.appendInt32(-1441998364)
                    }
                    serializeInt32(progress, buffer: buffer, boxed: false)
                    break
                case .sendMessageUploadPhotoAction(let progress):
                    if boxed {
                        buffer.appendInt32(-774682074)
                    }
                    serializeInt32(progress, buffer: buffer, boxed: false)
                    break
                case .sendMessageUploadRoundAction(let progress):
                    if boxed {
                        buffer.appendInt32(608050278)
                    }
                    serializeInt32(progress, buffer: buffer, boxed: false)
                    break
                case .sendMessageUploadVideoAction(let progress):
                    if boxed {
                        buffer.appendInt32(-378127636)
                    }
                    serializeInt32(progress, buffer: buffer, boxed: false)
                    break
                case .speakingInGroupCallAction:
                    if boxed {
                        buffer.appendInt32(-651419003)
                    }
                    
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .sendMessageCancelAction:
                return ("sendMessageCancelAction", [])
                case .sendMessageChooseContactAction:
                return ("sendMessageChooseContactAction", [])
                case .sendMessageChooseStickerAction:
                return ("sendMessageChooseStickerAction", [])
                case .sendMessageEmojiInteraction(let emoticon, let msgId, let interaction):
                return ("sendMessageEmojiInteraction", [("emoticon", emoticon as Any), ("msgId", msgId as Any), ("interaction", interaction as Any)])
                case .sendMessageEmojiInteractionSeen(let emoticon):
                return ("sendMessageEmojiInteractionSeen", [("emoticon", emoticon as Any)])
                case .sendMessageGamePlayAction:
                return ("sendMessageGamePlayAction", [])
                case .sendMessageGeoLocationAction:
                return ("sendMessageGeoLocationAction", [])
                case .sendMessageHistoryImportAction(let progress):
                return ("sendMessageHistoryImportAction", [("progress", progress as Any)])
                case .sendMessageRecordAudioAction:
                return ("sendMessageRecordAudioAction", [])
                case .sendMessageRecordRoundAction:
                return ("sendMessageRecordRoundAction", [])
                case .sendMessageRecordVideoAction:
                return ("sendMessageRecordVideoAction", [])
                case .sendMessageTypingAction:
                return ("sendMessageTypingAction", [])
                case .sendMessageUploadAudioAction(let progress):
                return ("sendMessageUploadAudioAction", [("progress", progress as Any)])
                case .sendMessageUploadDocumentAction(let progress):
                return ("sendMessageUploadDocumentAction", [("progress", progress as Any)])
                case .sendMessageUploadPhotoAction(let progress):
                return ("sendMessageUploadPhotoAction", [("progress", progress as Any)])
                case .sendMessageUploadRoundAction(let progress):
                return ("sendMessageUploadRoundAction", [("progress", progress as Any)])
                case .sendMessageUploadVideoAction(let progress):
                return ("sendMessageUploadVideoAction", [("progress", progress as Any)])
                case .speakingInGroupCallAction:
                return ("speakingInGroupCallAction", [])
    }
    }
    
        public static func parse_sendMessageCancelAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageCancelAction
        }
        public static func parse_sendMessageChooseContactAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageChooseContactAction
        }
        public static func parse_sendMessageChooseStickerAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageChooseStickerAction
        }
        public static func parse_sendMessageEmojiInteraction(_ reader: BufferReader) -> SendMessageAction? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Api.DataJSON?
            if let signature = reader.readInt32() {
                _3 = Api.parse(reader, signature: signature) as? Api.DataJSON
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.SendMessageAction.sendMessageEmojiInteraction(emoticon: _1!, msgId: _2!, interaction: _3!)
            }
            else {
                return nil
            }
        }
        public static func parse_sendMessageEmojiInteractionSeen(_ reader: BufferReader) -> SendMessageAction? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.SendMessageAction.sendMessageEmojiInteractionSeen(emoticon: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_sendMessageGamePlayAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageGamePlayAction
        }
        public static func parse_sendMessageGeoLocationAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageGeoLocationAction
        }
        public static func parse_sendMessageHistoryImportAction(_ reader: BufferReader) -> SendMessageAction? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.SendMessageAction.sendMessageHistoryImportAction(progress: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_sendMessageRecordAudioAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageRecordAudioAction
        }
        public static func parse_sendMessageRecordRoundAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageRecordRoundAction
        }
        public static func parse_sendMessageRecordVideoAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageRecordVideoAction
        }
        public static func parse_sendMessageTypingAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.sendMessageTypingAction
        }
        public static func parse_sendMessageUploadAudioAction(_ reader: BufferReader) -> SendMessageAction? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.SendMessageAction.sendMessageUploadAudioAction(progress: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_sendMessageUploadDocumentAction(_ reader: BufferReader) -> SendMessageAction? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.SendMessageAction.sendMessageUploadDocumentAction(progress: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_sendMessageUploadPhotoAction(_ reader: BufferReader) -> SendMessageAction? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.SendMessageAction.sendMessageUploadPhotoAction(progress: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_sendMessageUploadRoundAction(_ reader: BufferReader) -> SendMessageAction? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.SendMessageAction.sendMessageUploadRoundAction(progress: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_sendMessageUploadVideoAction(_ reader: BufferReader) -> SendMessageAction? {
            var _1: Int32?
            _1 = reader.readInt32()
            let _c1 = _1 != nil
            if _c1 {
                return Api.SendMessageAction.sendMessageUploadVideoAction(progress: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_speakingInGroupCallAction(_ reader: BufferReader) -> SendMessageAction? {
            return Api.SendMessageAction.speakingInGroupCallAction
        }
    
    }
}
public extension Api {
    enum ShippingOption: TypeConstructorDescription {
        case shippingOption(id: String, title: String, prices: [Api.LabeledPrice])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .shippingOption(let id, let title, let prices):
                    if boxed {
                        buffer.appendInt32(-1239335713)
                    }
                    serializeString(id, buffer: buffer, boxed: false)
                    serializeString(title, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(prices.count))
                    for item in prices {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .shippingOption(let id, let title, let prices):
                return ("shippingOption", [("id", id as Any), ("title", title as Any), ("prices", prices as Any)])
    }
    }
    
        public static func parse_shippingOption(_ reader: BufferReader) -> ShippingOption? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            var _3: [Api.LabeledPrice]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.LabeledPrice.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.ShippingOption.shippingOption(id: _1!, title: _2!, prices: _3!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum SimpleWebViewResult: TypeConstructorDescription {
        case simpleWebViewResultUrl(url: String)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .simpleWebViewResultUrl(let url):
                    if boxed {
                        buffer.appendInt32(-2010155333)
                    }
                    serializeString(url, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .simpleWebViewResultUrl(let url):
                return ("simpleWebViewResultUrl", [("url", url as Any)])
    }
    }
    
        public static func parse_simpleWebViewResultUrl(_ reader: BufferReader) -> SimpleWebViewResult? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.SimpleWebViewResult.simpleWebViewResultUrl(url: _1!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum SmsJob: TypeConstructorDescription {
        case smsJob(jobId: String, phoneNumber: String, text: String)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .smsJob(let jobId, let phoneNumber, let text):
                    if boxed {
                        buffer.appendInt32(-425595208)
                    }
                    serializeString(jobId, buffer: buffer, boxed: false)
                    serializeString(phoneNumber, buffer: buffer, boxed: false)
                    serializeString(text, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .smsJob(let jobId, let phoneNumber, let text):
                return ("smsJob", [("jobId", jobId as Any), ("phoneNumber", phoneNumber as Any), ("text", text as Any)])
    }
    }
    
        public static func parse_smsJob(_ reader: BufferReader) -> SmsJob? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.SmsJob.smsJob(jobId: _1!, phoneNumber: _2!, text: _3!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum SponsoredMessage: TypeConstructorDescription {
        case sponsoredMessage(flags: Int32, randomId: Buffer, url: String, title: String, message: String, entities: [Api.MessageEntity]?, photo: Api.Photo?, color: Api.PeerColor?, buttonText: String, sponsorInfo: String?, additionalInfo: String?)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .sponsoredMessage(let flags, let randomId, let url, let title, let message, let entities, let photo, let color, let buttonText, let sponsorInfo, let additionalInfo):
                    if boxed {
                        buffer.appendInt32(-1108478618)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeBytes(randomId, buffer: buffer, boxed: false)
                    serializeString(url, buffer: buffer, boxed: false)
                    serializeString(title, buffer: buffer, boxed: false)
                    serializeString(message, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 1) != 0 {buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(entities!.count))
                    for item in entities! {
                        item.serialize(buffer, true)
                    }}
                    if Int(flags) & Int(1 << 6) != 0 {photo!.serialize(buffer, true)}
                    if Int(flags) & Int(1 << 13) != 0 {color!.serialize(buffer, true)}
                    serializeString(buttonText, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 7) != 0 {serializeString(sponsorInfo!, buffer: buffer, boxed: false)}
                    if Int(flags) & Int(1 << 8) != 0 {serializeString(additionalInfo!, buffer: buffer, boxed: false)}
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .sponsoredMessage(let flags, let randomId, let url, let title, let message, let entities, let photo, let color, let buttonText, let sponsorInfo, let additionalInfo):
                return ("sponsoredMessage", [("flags", flags as Any), ("randomId", randomId as Any), ("url", url as Any), ("title", title as Any), ("message", message as Any), ("entities", entities as Any), ("photo", photo as Any), ("color", color as Any), ("buttonText", buttonText as Any), ("sponsorInfo", sponsorInfo as Any), ("additionalInfo", additionalInfo as Any)])
    }
    }
    
        public static func parse_sponsoredMessage(_ reader: BufferReader) -> SponsoredMessage? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Buffer?
            _2 = parseBytes(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            var _5: String?
            _5 = parseString(reader)
            var _6: [Api.MessageEntity]?
            if Int(_1!) & Int(1 << 1) != 0 {if let _ = reader.readInt32() {
                _6 = Api.parseVector(reader, elementSignature: 0, elementType: Api.MessageEntity.self)
            } }
            var _7: Api.Photo?
            if Int(_1!) & Int(1 << 6) != 0 {if let signature = reader.readInt32() {
                _7 = Api.parse(reader, signature: signature) as? Api.Photo
            } }
            var _8: Api.PeerColor?
            if Int(_1!) & Int(1 << 13) != 0 {if let signature = reader.readInt32() {
                _8 = Api.parse(reader, signature: signature) as? Api.PeerColor
            } }
            var _9: String?
            _9 = parseString(reader)
            var _10: String?
            if Int(_1!) & Int(1 << 7) != 0 {_10 = parseString(reader) }
            var _11: String?
            if Int(_1!) & Int(1 << 8) != 0 {_11 = parseString(reader) }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1!) & Int(1 << 1) == 0) || _6 != nil
            let _c7 = (Int(_1!) & Int(1 << 6) == 0) || _7 != nil
            let _c8 = (Int(_1!) & Int(1 << 13) == 0) || _8 != nil
            let _c9 = _9 != nil
            let _c10 = (Int(_1!) & Int(1 << 7) == 0) || _10 != nil
            let _c11 = (Int(_1!) & Int(1 << 8) == 0) || _11 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 && _c10 && _c11 {
                return Api.SponsoredMessage.sponsoredMessage(flags: _1!, randomId: _2!, url: _3!, title: _4!, message: _5!, entities: _6, photo: _7, color: _8, buttonText: _9!, sponsorInfo: _10, additionalInfo: _11)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum SponsoredMessageReportOption: TypeConstructorDescription {
        case sponsoredMessageReportOption(text: String, option: Buffer)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .sponsoredMessageReportOption(let text, let option):
                    if boxed {
                        buffer.appendInt32(1124938064)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeBytes(option, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .sponsoredMessageReportOption(let text, let option):
                return ("sponsoredMessageReportOption", [("text", text as Any), ("option", option as Any)])
    }
    }
    
        public static func parse_sponsoredMessageReportOption(_ reader: BufferReader) -> SponsoredMessageReportOption? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Buffer?
            _2 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.SponsoredMessageReportOption.sponsoredMessageReportOption(text: _1!, option: _2!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum StarsTopupOption: TypeConstructorDescription {
        case starsTopupOption(flags: Int32, stars: Int64, storeProduct: String?, currency: String, amount: Int64)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .starsTopupOption(let flags, let stars, let storeProduct, let currency, let amount):
                    if boxed {
                        buffer.appendInt32(198776256)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeInt64(stars, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 0) != 0 {serializeString(storeProduct!, buffer: buffer, boxed: false)}
                    serializeString(currency, buffer: buffer, boxed: false)
                    serializeInt64(amount, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .starsTopupOption(let flags, let stars, let storeProduct, let currency, let amount):
                return ("starsTopupOption", [("flags", flags as Any), ("stars", stars as Any), ("storeProduct", storeProduct as Any), ("currency", currency as Any), ("amount", amount as Any)])
    }
    }
    
        public static func parse_starsTopupOption(_ reader: BufferReader) -> StarsTopupOption? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: String?
            if Int(_1!) & Int(1 << 0) != 0 {_3 = parseString(reader) }
            var _4: String?
            _4 = parseString(reader)
            var _5: Int64?
            _5 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1!) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.StarsTopupOption.starsTopupOption(flags: _1!, stars: _2!, storeProduct: _3, currency: _4!, amount: _5!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum StarsTransaction: TypeConstructorDescription {
        case starsTransaction(flags: Int32, id: String, stars: Int64, date: Int32, peer: Api.StarsTransactionPeer, title: String?, description: String?, photo: Api.WebDocument?)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .starsTransaction(let flags, let id, let stars, let date, let peer, let title, let description, let photo):
                    if boxed {
                        buffer.appendInt32(-865044046)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(id, buffer: buffer, boxed: false)
                    serializeInt64(stars, buffer: buffer, boxed: false)
                    serializeInt32(date, buffer: buffer, boxed: false)
                    peer.serialize(buffer, true)
                    if Int(flags) & Int(1 << 0) != 0 {serializeString(title!, buffer: buffer, boxed: false)}
                    if Int(flags) & Int(1 << 1) != 0 {serializeString(description!, buffer: buffer, boxed: false)}
                    if Int(flags) & Int(1 << 2) != 0 {photo!.serialize(buffer, true)}
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .starsTransaction(let flags, let id, let stars, let date, let peer, let title, let description, let photo):
                return ("starsTransaction", [("flags", flags as Any), ("id", id as Any), ("stars", stars as Any), ("date", date as Any), ("peer", peer as Any), ("title", title as Any), ("description", description as Any), ("photo", photo as Any)])
    }
    }
    
        public static func parse_starsTransaction(_ reader: BufferReader) -> StarsTransaction? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: Int64?
            _3 = reader.readInt64()
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Api.StarsTransactionPeer?
            if let signature = reader.readInt32() {
                _5 = Api.parse(reader, signature: signature) as? Api.StarsTransactionPeer
            }
            var _6: String?
            if Int(_1!) & Int(1 << 0) != 0 {_6 = parseString(reader) }
            var _7: String?
            if Int(_1!) & Int(1 << 1) != 0 {_7 = parseString(reader) }
            var _8: Api.WebDocument?
            if Int(_1!) & Int(1 << 2) != 0 {if let signature = reader.readInt32() {
                _8 = Api.parse(reader, signature: signature) as? Api.WebDocument
            } }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = (Int(_1!) & Int(1 << 0) == 0) || _6 != nil
            let _c7 = (Int(_1!) & Int(1 << 1) == 0) || _7 != nil
            let _c8 = (Int(_1!) & Int(1 << 2) == 0) || _8 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 {
                return Api.StarsTransaction.starsTransaction(flags: _1!, id: _2!, stars: _3!, date: _4!, peer: _5!, title: _6, description: _7, photo: _8)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum StarsTransactionPeer: TypeConstructorDescription {
        case starsTransactionPeer(peer: Api.Peer)
        case starsTransactionPeerAppStore
        case starsTransactionPeerFragment
        case starsTransactionPeerPlayMarket
        case starsTransactionPeerPremiumBot
        case starsTransactionPeerUnsupported
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .starsTransactionPeer(let peer):
                    if boxed {
                        buffer.appendInt32(-670195363)
                    }
                    peer.serialize(buffer, true)
                    break
                case .starsTransactionPeerAppStore:
                    if boxed {
                        buffer.appendInt32(-1269320843)
                    }
                    
                    break
                case .starsTransactionPeerFragment:
                    if boxed {
                        buffer.appendInt32(-382740222)
                    }
                    
                    break
                case .starsTransactionPeerPlayMarket:
                    if boxed {
                        buffer.appendInt32(2069236235)
                    }
                    
                    break
                case .starsTransactionPeerPremiumBot:
                    if boxed {
                        buffer.appendInt32(621656824)
                    }
                    
                    break
                case .starsTransactionPeerUnsupported:
                    if boxed {
                        buffer.appendInt32(-1779253276)
                    }
                    
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .starsTransactionPeer(let peer):
                return ("starsTransactionPeer", [("peer", peer as Any)])
                case .starsTransactionPeerAppStore:
                return ("starsTransactionPeerAppStore", [])
                case .starsTransactionPeerFragment:
                return ("starsTransactionPeerFragment", [])
                case .starsTransactionPeerPlayMarket:
                return ("starsTransactionPeerPlayMarket", [])
                case .starsTransactionPeerPremiumBot:
                return ("starsTransactionPeerPremiumBot", [])
                case .starsTransactionPeerUnsupported:
                return ("starsTransactionPeerUnsupported", [])
    }
    }
    
        public static func parse_starsTransactionPeer(_ reader: BufferReader) -> StarsTransactionPeer? {
            var _1: Api.Peer?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.Peer
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.StarsTransactionPeer.starsTransactionPeer(peer: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_starsTransactionPeerAppStore(_ reader: BufferReader) -> StarsTransactionPeer? {
            return Api.StarsTransactionPeer.starsTransactionPeerAppStore
        }
        public static func parse_starsTransactionPeerFragment(_ reader: BufferReader) -> StarsTransactionPeer? {
            return Api.StarsTransactionPeer.starsTransactionPeerFragment
        }
        public static func parse_starsTransactionPeerPlayMarket(_ reader: BufferReader) -> StarsTransactionPeer? {
            return Api.StarsTransactionPeer.starsTransactionPeerPlayMarket
        }
        public static func parse_starsTransactionPeerPremiumBot(_ reader: BufferReader) -> StarsTransactionPeer? {
            return Api.StarsTransactionPeer.starsTransactionPeerPremiumBot
        }
        public static func parse_starsTransactionPeerUnsupported(_ reader: BufferReader) -> StarsTransactionPeer? {
            return Api.StarsTransactionPeer.starsTransactionPeerUnsupported
        }
    
    }
}
