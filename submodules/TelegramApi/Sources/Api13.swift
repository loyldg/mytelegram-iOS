public extension Api {
    enum InputWebFileLocation: TypeConstructorDescription {
        case inputWebFileAudioAlbumThumbLocation(flags: Int32, document: Api.InputDocument?, title: String?, performer: String?)
        case inputWebFileGeoPointLocation(geoPoint: Api.InputGeoPoint, accessHash: Int64, w: Int32, h: Int32, zoom: Int32, scale: Int32)
        case inputWebFileLocation(url: String, accessHash: Int64)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .inputWebFileAudioAlbumThumbLocation(let flags, let document, let title, let performer):
                    if boxed {
                        buffer.appendInt32(-193992412)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 0) != 0 {document!.serialize(buffer, true)}
                    if Int(flags) & Int(1 << 1) != 0 {serializeString(title!, buffer: buffer, boxed: false)}
                    if Int(flags) & Int(1 << 1) != 0 {serializeString(performer!, buffer: buffer, boxed: false)}
                    break
                case .inputWebFileGeoPointLocation(let geoPoint, let accessHash, let w, let h, let zoom, let scale):
                    if boxed {
                        buffer.appendInt32(-1625153079)
                    }
                    geoPoint.serialize(buffer, true)
                    serializeInt64(accessHash, buffer: buffer, boxed: false)
                    serializeInt32(w, buffer: buffer, boxed: false)
                    serializeInt32(h, buffer: buffer, boxed: false)
                    serializeInt32(zoom, buffer: buffer, boxed: false)
                    serializeInt32(scale, buffer: buffer, boxed: false)
                    break
                case .inputWebFileLocation(let url, let accessHash):
                    if boxed {
                        buffer.appendInt32(-1036396922)
                    }
                    serializeString(url, buffer: buffer, boxed: false)
                    serializeInt64(accessHash, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .inputWebFileAudioAlbumThumbLocation(let flags, let document, let title, let performer):
                return ("inputWebFileAudioAlbumThumbLocation", [("flags", flags as Any), ("document", document as Any), ("title", title as Any), ("performer", performer as Any)])
                case .inputWebFileGeoPointLocation(let geoPoint, let accessHash, let w, let h, let zoom, let scale):
                return ("inputWebFileGeoPointLocation", [("geoPoint", geoPoint as Any), ("accessHash", accessHash as Any), ("w", w as Any), ("h", h as Any), ("zoom", zoom as Any), ("scale", scale as Any)])
                case .inputWebFileLocation(let url, let accessHash):
                return ("inputWebFileLocation", [("url", url as Any), ("accessHash", accessHash as Any)])
    }
    }
    
        public static func parse_inputWebFileAudioAlbumThumbLocation(_ reader: BufferReader) -> InputWebFileLocation? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.InputDocument?
            if Int(_1!) & Int(1 << 0) != 0 {if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.InputDocument
            } }
            var _3: String?
            if Int(_1!) & Int(1 << 1) != 0 {_3 = parseString(reader) }
            var _4: String?
            if Int(_1!) & Int(1 << 1) != 0 {_4 = parseString(reader) }
            let _c1 = _1 != nil
            let _c2 = (Int(_1!) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = (Int(_1!) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = (Int(_1!) & Int(1 << 1) == 0) || _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.InputWebFileLocation.inputWebFileAudioAlbumThumbLocation(flags: _1!, document: _2, title: _3, performer: _4)
            }
            else {
                return nil
            }
        }
        public static func parse_inputWebFileGeoPointLocation(_ reader: BufferReader) -> InputWebFileLocation? {
            var _1: Api.InputGeoPoint?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.InputGeoPoint
            }
            var _2: Int64?
            _2 = reader.readInt64()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Int32?
            _4 = reader.readInt32()
            var _5: Int32?
            _5 = reader.readInt32()
            var _6: Int32?
            _6 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            let _c6 = _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.InputWebFileLocation.inputWebFileGeoPointLocation(geoPoint: _1!, accessHash: _2!, w: _3!, h: _4!, zoom: _5!, scale: _6!)
            }
            else {
                return nil
            }
        }
        public static func parse_inputWebFileLocation(_ reader: BufferReader) -> InputWebFileLocation? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.InputWebFileLocation.inputWebFileLocation(url: _1!, accessHash: _2!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum Invoice: TypeConstructorDescription {
        case invoice(flags: Int32, currency: String, prices: [Api.LabeledPrice], maxTipAmount: Int64?, suggestedTipAmounts: [Int64]?, termsUrl: String?)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .invoice(let flags, let currency, let prices, let maxTipAmount, let suggestedTipAmounts, let termsUrl):
                    if boxed {
                        buffer.appendInt32(1572428309)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(currency, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(prices.count))
                    for item in prices {
                        item.serialize(buffer, true)
                    }
                    if Int(flags) & Int(1 << 8) != 0 {serializeInt64(maxTipAmount!, buffer: buffer, boxed: false)}
                    if Int(flags) & Int(1 << 8) != 0 {buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(suggestedTipAmounts!.count))
                    for item in suggestedTipAmounts! {
                        serializeInt64(item, buffer: buffer, boxed: false)
                    }}
                    if Int(flags) & Int(1 << 10) != 0 {serializeString(termsUrl!, buffer: buffer, boxed: false)}
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .invoice(let flags, let currency, let prices, let maxTipAmount, let suggestedTipAmounts, let termsUrl):
                return ("invoice", [("flags", flags as Any), ("currency", currency as Any), ("prices", prices as Any), ("maxTipAmount", maxTipAmount as Any), ("suggestedTipAmounts", suggestedTipAmounts as Any), ("termsUrl", termsUrl as Any)])
    }
    }
    
        public static func parse_invoice(_ reader: BufferReader) -> Invoice? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: [Api.LabeledPrice]?
            if let _ = reader.readInt32() {
                _3 = Api.parseVector(reader, elementSignature: 0, elementType: Api.LabeledPrice.self)
            }
            var _4: Int64?
            if Int(_1!) & Int(1 << 8) != 0 {_4 = reader.readInt64() }
            var _5: [Int64]?
            if Int(_1!) & Int(1 << 8) != 0 {if let _ = reader.readInt32() {
                _5 = Api.parseVector(reader, elementSignature: 570911930, elementType: Int64.self)
            } }
            var _6: String?
            if Int(_1!) & Int(1 << 10) != 0 {_6 = parseString(reader) }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1!) & Int(1 << 8) == 0) || _4 != nil
            let _c5 = (Int(_1!) & Int(1 << 8) == 0) || _5 != nil
            let _c6 = (Int(_1!) & Int(1 << 10) == 0) || _6 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 {
                return Api.Invoice.invoice(flags: _1!, currency: _2!, prices: _3!, maxTipAmount: _4, suggestedTipAmounts: _5, termsUrl: _6)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum JSONObjectValue: TypeConstructorDescription {
        case jsonObjectValue(key: String, value: Api.JSONValue)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .jsonObjectValue(let key, let value):
                    if boxed {
                        buffer.appendInt32(-1059185703)
                    }
                    serializeString(key, buffer: buffer, boxed: false)
                    value.serialize(buffer, true)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .jsonObjectValue(let key, let value):
                return ("jsonObjectValue", [("key", key as Any), ("value", value as Any)])
    }
    }
    
        public static func parse_jsonObjectValue(_ reader: BufferReader) -> JSONObjectValue? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Api.JSONValue?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.JSONValue
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.JSONObjectValue.jsonObjectValue(key: _1!, value: _2!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum JSONValue: TypeConstructorDescription {
        case jsonArray(value: [Api.JSONValue])
        case jsonBool(value: Api.Bool)
        case jsonNull
        case jsonNumber(value: Double)
        case jsonObject(value: [Api.JSONObjectValue])
        case jsonString(value: String)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .jsonArray(let value):
                    if boxed {
                        buffer.appendInt32(-146520221)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(value.count))
                    for item in value {
                        item.serialize(buffer, true)
                    }
                    break
                case .jsonBool(let value):
                    if boxed {
                        buffer.appendInt32(-952869270)
                    }
                    value.serialize(buffer, true)
                    break
                case .jsonNull:
                    if boxed {
                        buffer.appendInt32(1064139624)
                    }
                    
                    break
                case .jsonNumber(let value):
                    if boxed {
                        buffer.appendInt32(736157604)
                    }
                    serializeDouble(value, buffer: buffer, boxed: false)
                    break
                case .jsonObject(let value):
                    if boxed {
                        buffer.appendInt32(-1715350371)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(value.count))
                    for item in value {
                        item.serialize(buffer, true)
                    }
                    break
                case .jsonString(let value):
                    if boxed {
                        buffer.appendInt32(-1222740358)
                    }
                    serializeString(value, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .jsonArray(let value):
                return ("jsonArray", [("value", value as Any)])
                case .jsonBool(let value):
                return ("jsonBool", [("value", value as Any)])
                case .jsonNull:
                return ("jsonNull", [])
                case .jsonNumber(let value):
                return ("jsonNumber", [("value", value as Any)])
                case .jsonObject(let value):
                return ("jsonObject", [("value", value as Any)])
                case .jsonString(let value):
                return ("jsonString", [("value", value as Any)])
    }
    }
    
        public static func parse_jsonArray(_ reader: BufferReader) -> JSONValue? {
            var _1: [Api.JSONValue]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.JSONValue.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonArray(value: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_jsonBool(_ reader: BufferReader) -> JSONValue? {
            var _1: Api.Bool?
            if let signature = reader.readInt32() {
                _1 = Api.parse(reader, signature: signature) as? Api.Bool
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonBool(value: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_jsonNull(_ reader: BufferReader) -> JSONValue? {
            return Api.JSONValue.jsonNull
        }
        public static func parse_jsonNumber(_ reader: BufferReader) -> JSONValue? {
            var _1: Double?
            _1 = reader.readDouble()
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonNumber(value: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_jsonObject(_ reader: BufferReader) -> JSONValue? {
            var _1: [Api.JSONObjectValue]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.JSONObjectValue.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonObject(value: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_jsonString(_ reader: BufferReader) -> JSONValue? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.JSONValue.jsonString(value: _1!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    indirect enum KeyboardButton: TypeConstructorDescription {
        case inputKeyboardButtonRequestPeer(flags: Int32, text: String, buttonId: Int32, peerType: Api.RequestPeerType, maxQuantity: Int32)
        case inputKeyboardButtonUrlAuth(flags: Int32, text: String, fwdText: String?, url: String, bot: Api.InputUser)
        case inputKeyboardButtonUserProfile(text: String, userId: Api.InputUser)
        case keyboardButton(text: String)
        case keyboardButtonBuy(text: String)
        case keyboardButtonCallback(flags: Int32, text: String, data: Buffer)
        case keyboardButtonGame(text: String)
        case keyboardButtonRequestGeoLocation(text: String)
        case keyboardButtonRequestPeer(text: String, buttonId: Int32, peerType: Api.RequestPeerType, maxQuantity: Int32)
        case keyboardButtonRequestPhone(text: String)
        case keyboardButtonRequestPoll(flags: Int32, quiz: Api.Bool?, text: String)
        case keyboardButtonSimpleWebView(text: String, url: String)
        case keyboardButtonSwitchInline(flags: Int32, text: String, query: String, peerTypes: [Api.InlineQueryPeerType]?)
        case keyboardButtonUrl(text: String, url: String)
        case keyboardButtonUrlAuth(flags: Int32, text: String, fwdText: String?, url: String, buttonId: Int32)
        case keyboardButtonUserProfile(text: String, userId: Int64)
        case keyboardButtonWebView(text: String, url: String)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .inputKeyboardButtonRequestPeer(let flags, let text, let buttonId, let peerType, let maxQuantity):
                    if boxed {
                        buffer.appendInt32(-916050683)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeInt32(buttonId, buffer: buffer, boxed: false)
                    peerType.serialize(buffer, true)
                    serializeInt32(maxQuantity, buffer: buffer, boxed: false)
                    break
                case .inputKeyboardButtonUrlAuth(let flags, let text, let fwdText, let url, let bot):
                    if boxed {
                        buffer.appendInt32(-802258988)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(text, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 1) != 0 {serializeString(fwdText!, buffer: buffer, boxed: false)}
                    serializeString(url, buffer: buffer, boxed: false)
                    bot.serialize(buffer, true)
                    break
                case .inputKeyboardButtonUserProfile(let text, let userId):
                    if boxed {
                        buffer.appendInt32(-376962181)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    userId.serialize(buffer, true)
                    break
                case .keyboardButton(let text):
                    if boxed {
                        buffer.appendInt32(-1560655744)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonBuy(let text):
                    if boxed {
                        buffer.appendInt32(-1344716869)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonCallback(let flags, let text, let data):
                    if boxed {
                        buffer.appendInt32(901503851)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeBytes(data, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonGame(let text):
                    if boxed {
                        buffer.appendInt32(1358175439)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonRequestGeoLocation(let text):
                    if boxed {
                        buffer.appendInt32(-59151553)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonRequestPeer(let text, let buttonId, let peerType, let maxQuantity):
                    if boxed {
                        buffer.appendInt32(1406648280)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeInt32(buttonId, buffer: buffer, boxed: false)
                    peerType.serialize(buffer, true)
                    serializeInt32(maxQuantity, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonRequestPhone(let text):
                    if boxed {
                        buffer.appendInt32(-1318425559)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonRequestPoll(let flags, let quiz, let text):
                    if boxed {
                        buffer.appendInt32(-1144565411)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 0) != 0 {quiz!.serialize(buffer, true)}
                    serializeString(text, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonSimpleWebView(let text, let url):
                    if boxed {
                        buffer.appendInt32(-1598009252)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeString(url, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonSwitchInline(let flags, let text, let query, let peerTypes):
                    if boxed {
                        buffer.appendInt32(-1816527947)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeString(query, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 1) != 0 {buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(peerTypes!.count))
                    for item in peerTypes! {
                        item.serialize(buffer, true)
                    }}
                    break
                case .keyboardButtonUrl(let text, let url):
                    if boxed {
                        buffer.appendInt32(629866245)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeString(url, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonUrlAuth(let flags, let text, let fwdText, let url, let buttonId):
                    if boxed {
                        buffer.appendInt32(280464681)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(text, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 0) != 0 {serializeString(fwdText!, buffer: buffer, boxed: false)}
                    serializeString(url, buffer: buffer, boxed: false)
                    serializeInt32(buttonId, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonUserProfile(let text, let userId):
                    if boxed {
                        buffer.appendInt32(814112961)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeInt64(userId, buffer: buffer, boxed: false)
                    break
                case .keyboardButtonWebView(let text, let url):
                    if boxed {
                        buffer.appendInt32(326529584)
                    }
                    serializeString(text, buffer: buffer, boxed: false)
                    serializeString(url, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .inputKeyboardButtonRequestPeer(let flags, let text, let buttonId, let peerType, let maxQuantity):
                return ("inputKeyboardButtonRequestPeer", [("flags", flags as Any), ("text", text as Any), ("buttonId", buttonId as Any), ("peerType", peerType as Any), ("maxQuantity", maxQuantity as Any)])
                case .inputKeyboardButtonUrlAuth(let flags, let text, let fwdText, let url, let bot):
                return ("inputKeyboardButtonUrlAuth", [("flags", flags as Any), ("text", text as Any), ("fwdText", fwdText as Any), ("url", url as Any), ("bot", bot as Any)])
                case .inputKeyboardButtonUserProfile(let text, let userId):
                return ("inputKeyboardButtonUserProfile", [("text", text as Any), ("userId", userId as Any)])
                case .keyboardButton(let text):
                return ("keyboardButton", [("text", text as Any)])
                case .keyboardButtonBuy(let text):
                return ("keyboardButtonBuy", [("text", text as Any)])
                case .keyboardButtonCallback(let flags, let text, let data):
                return ("keyboardButtonCallback", [("flags", flags as Any), ("text", text as Any), ("data", data as Any)])
                case .keyboardButtonGame(let text):
                return ("keyboardButtonGame", [("text", text as Any)])
                case .keyboardButtonRequestGeoLocation(let text):
                return ("keyboardButtonRequestGeoLocation", [("text", text as Any)])
                case .keyboardButtonRequestPeer(let text, let buttonId, let peerType, let maxQuantity):
                return ("keyboardButtonRequestPeer", [("text", text as Any), ("buttonId", buttonId as Any), ("peerType", peerType as Any), ("maxQuantity", maxQuantity as Any)])
                case .keyboardButtonRequestPhone(let text):
                return ("keyboardButtonRequestPhone", [("text", text as Any)])
                case .keyboardButtonRequestPoll(let flags, let quiz, let text):
                return ("keyboardButtonRequestPoll", [("flags", flags as Any), ("quiz", quiz as Any), ("text", text as Any)])
                case .keyboardButtonSimpleWebView(let text, let url):
                return ("keyboardButtonSimpleWebView", [("text", text as Any), ("url", url as Any)])
                case .keyboardButtonSwitchInline(let flags, let text, let query, let peerTypes):
                return ("keyboardButtonSwitchInline", [("flags", flags as Any), ("text", text as Any), ("query", query as Any), ("peerTypes", peerTypes as Any)])
                case .keyboardButtonUrl(let text, let url):
                return ("keyboardButtonUrl", [("text", text as Any), ("url", url as Any)])
                case .keyboardButtonUrlAuth(let flags, let text, let fwdText, let url, let buttonId):
                return ("keyboardButtonUrlAuth", [("flags", flags as Any), ("text", text as Any), ("fwdText", fwdText as Any), ("url", url as Any), ("buttonId", buttonId as Any)])
                case .keyboardButtonUserProfile(let text, let userId):
                return ("keyboardButtonUserProfile", [("text", text as Any), ("userId", userId as Any)])
                case .keyboardButtonWebView(let text, let url):
                return ("keyboardButtonWebView", [("text", text as Any), ("url", url as Any)])
    }
    }
    
        public static func parse_inputKeyboardButtonRequestPeer(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: Api.RequestPeerType?
            if let signature = reader.readInt32() {
                _4 = Api.parse(reader, signature: signature) as? Api.RequestPeerType
            }
            var _5: Int32?
            _5 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.KeyboardButton.inputKeyboardButtonRequestPeer(flags: _1!, text: _2!, buttonId: _3!, peerType: _4!, maxQuantity: _5!)
            }
            else {
                return nil
            }
        }
        public static func parse_inputKeyboardButtonUrlAuth(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            if Int(_1!) & Int(1 << 1) != 0 {_3 = parseString(reader) }
            var _4: String?
            _4 = parseString(reader)
            var _5: Api.InputUser?
            if let signature = reader.readInt32() {
                _5 = Api.parse(reader, signature: signature) as? Api.InputUser
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1!) & Int(1 << 1) == 0) || _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.KeyboardButton.inputKeyboardButtonUrlAuth(flags: _1!, text: _2!, fwdText: _3, url: _4!, bot: _5!)
            }
            else {
                return nil
            }
        }
        public static func parse_inputKeyboardButtonUserProfile(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Api.InputUser?
            if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.InputUser
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.KeyboardButton.inputKeyboardButtonUserProfile(text: _1!, userId: _2!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButton(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.KeyboardButton.keyboardButton(text: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonBuy(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.KeyboardButton.keyboardButtonBuy(text: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonCallback(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: Buffer?
            _3 = parseBytes(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.KeyboardButton.keyboardButtonCallback(flags: _1!, text: _2!, data: _3!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonGame(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.KeyboardButton.keyboardButtonGame(text: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestGeoLocation(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.KeyboardButton.keyboardButtonRequestGeoLocation(text: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestPeer(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Api.RequestPeerType?
            if let signature = reader.readInt32() {
                _3 = Api.parse(reader, signature: signature) as? Api.RequestPeerType
            }
            var _4: Int32?
            _4 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonRequestPeer(text: _1!, buttonId: _2!, peerType: _3!, maxQuantity: _4!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestPhone(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            let _c1 = _1 != nil
            if _c1 {
                return Api.KeyboardButton.keyboardButtonRequestPhone(text: _1!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonRequestPoll(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: Api.Bool?
            if Int(_1!) & Int(1 << 0) != 0 {if let signature = reader.readInt32() {
                _2 = Api.parse(reader, signature: signature) as? Api.Bool
            } }
            var _3: String?
            _3 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = (Int(_1!) & Int(1 << 0) == 0) || _2 != nil
            let _c3 = _3 != nil
            if _c1 && _c2 && _c3 {
                return Api.KeyboardButton.keyboardButtonRequestPoll(flags: _1!, quiz: _2, text: _3!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonSimpleWebView(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.KeyboardButton.keyboardButtonSimpleWebView(text: _1!, url: _2!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonSwitchInline(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: [Api.InlineQueryPeerType]?
            if Int(_1!) & Int(1 << 1) != 0 {if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.InlineQueryPeerType.self)
            } }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = (Int(_1!) & Int(1 << 1) == 0) || _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.KeyboardButton.keyboardButtonSwitchInline(flags: _1!, text: _2!, query: _3!, peerTypes: _4)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonUrl(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.KeyboardButton.keyboardButtonUrl(text: _1!, url: _2!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonUrlAuth(_ reader: BufferReader) -> KeyboardButton? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            if Int(_1!) & Int(1 << 0) != 0 {_3 = parseString(reader) }
            var _4: String?
            _4 = parseString(reader)
            var _5: Int32?
            _5 = reader.readInt32()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = (Int(_1!) & Int(1 << 0) == 0) || _3 != nil
            let _c4 = _4 != nil
            let _c5 = _5 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 {
                return Api.KeyboardButton.keyboardButtonUrlAuth(flags: _1!, text: _2!, fwdText: _3, url: _4!, buttonId: _5!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonUserProfile(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.KeyboardButton.keyboardButtonUserProfile(text: _1!, userId: _2!)
            }
            else {
                return nil
            }
        }
        public static func parse_keyboardButtonWebView(_ reader: BufferReader) -> KeyboardButton? {
            var _1: String?
            _1 = parseString(reader)
            var _2: String?
            _2 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.KeyboardButton.keyboardButtonWebView(text: _1!, url: _2!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum KeyboardButtonRow: TypeConstructorDescription {
        case keyboardButtonRow(buttons: [Api.KeyboardButton])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .keyboardButtonRow(let buttons):
                    if boxed {
                        buffer.appendInt32(2002815875)
                    }
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(buttons.count))
                    for item in buttons {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .keyboardButtonRow(let buttons):
                return ("keyboardButtonRow", [("buttons", buttons as Any)])
    }
    }
    
        public static func parse_keyboardButtonRow(_ reader: BufferReader) -> KeyboardButtonRow? {
            var _1: [Api.KeyboardButton]?
            if let _ = reader.readInt32() {
                _1 = Api.parseVector(reader, elementSignature: 0, elementType: Api.KeyboardButton.self)
            }
            let _c1 = _1 != nil
            if _c1 {
                return Api.KeyboardButtonRow.keyboardButtonRow(buttons: _1!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum LabeledPrice: TypeConstructorDescription {
        case labeledPrice(label: String, amount: Int64)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .labeledPrice(let label, let amount):
                    if boxed {
                        buffer.appendInt32(-886477832)
                    }
                    serializeString(label, buffer: buffer, boxed: false)
                    serializeInt64(amount, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .labeledPrice(let label, let amount):
                return ("labeledPrice", [("label", label as Any), ("amount", amount as Any)])
    }
    }
    
        public static func parse_labeledPrice(_ reader: BufferReader) -> LabeledPrice? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int64?
            _2 = reader.readInt64()
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            if _c1 && _c2 {
                return Api.LabeledPrice.labeledPrice(label: _1!, amount: _2!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum LangPackDifference: TypeConstructorDescription {
        case langPackDifference(langCode: String, fromVersion: Int32, version: Int32, strings: [Api.LangPackString])
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .langPackDifference(let langCode, let fromVersion, let version, let strings):
                    if boxed {
                        buffer.appendInt32(-209337866)
                    }
                    serializeString(langCode, buffer: buffer, boxed: false)
                    serializeInt32(fromVersion, buffer: buffer, boxed: false)
                    serializeInt32(version, buffer: buffer, boxed: false)
                    buffer.appendInt32(481674261)
                    buffer.appendInt32(Int32(strings.count))
                    for item in strings {
                        item.serialize(buffer, true)
                    }
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .langPackDifference(let langCode, let fromVersion, let version, let strings):
                return ("langPackDifference", [("langCode", langCode as Any), ("fromVersion", fromVersion as Any), ("version", version as Any), ("strings", strings as Any)])
    }
    }
    
        public static func parse_langPackDifference(_ reader: BufferReader) -> LangPackDifference? {
            var _1: String?
            _1 = parseString(reader)
            var _2: Int32?
            _2 = reader.readInt32()
            var _3: Int32?
            _3 = reader.readInt32()
            var _4: [Api.LangPackString]?
            if let _ = reader.readInt32() {
                _4 = Api.parseVector(reader, elementSignature: 0, elementType: Api.LangPackString.self)
            }
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            if _c1 && _c2 && _c3 && _c4 {
                return Api.LangPackDifference.langPackDifference(langCode: _1!, fromVersion: _2!, version: _3!, strings: _4!)
            }
            else {
                return nil
            }
        }
    
    }
}
public extension Api {
    enum LangPackLanguage: TypeConstructorDescription {
        case langPackLanguage(flags: Int32, name: String, nativeName: String, langCode: String, baseLangCode: String?, pluralCode: String, stringsCount: Int32, translatedCount: Int32, translationsUrl: String)
    
    public func serialize(_ buffer: Buffer, _ boxed: Swift.Bool) {
    switch self {
                case .langPackLanguage(let flags, let name, let nativeName, let langCode, let baseLangCode, let pluralCode, let stringsCount, let translatedCount, let translationsUrl):
                    if boxed {
                        buffer.appendInt32(-288727837)
                    }
                    serializeInt32(flags, buffer: buffer, boxed: false)
                    serializeString(name, buffer: buffer, boxed: false)
                    serializeString(nativeName, buffer: buffer, boxed: false)
                    serializeString(langCode, buffer: buffer, boxed: false)
                    if Int(flags) & Int(1 << 1) != 0 {serializeString(baseLangCode!, buffer: buffer, boxed: false)}
                    serializeString(pluralCode, buffer: buffer, boxed: false)
                    serializeInt32(stringsCount, buffer: buffer, boxed: false)
                    serializeInt32(translatedCount, buffer: buffer, boxed: false)
                    serializeString(translationsUrl, buffer: buffer, boxed: false)
                    break
    }
    }
    
    public func descriptionFields() -> (String, [(String, Any)]) {
        switch self {
                case .langPackLanguage(let flags, let name, let nativeName, let langCode, let baseLangCode, let pluralCode, let stringsCount, let translatedCount, let translationsUrl):
                return ("langPackLanguage", [("flags", flags as Any), ("name", name as Any), ("nativeName", nativeName as Any), ("langCode", langCode as Any), ("baseLangCode", baseLangCode as Any), ("pluralCode", pluralCode as Any), ("stringsCount", stringsCount as Any), ("translatedCount", translatedCount as Any), ("translationsUrl", translationsUrl as Any)])
    }
    }
    
        public static func parse_langPackLanguage(_ reader: BufferReader) -> LangPackLanguage? {
            var _1: Int32?
            _1 = reader.readInt32()
            var _2: String?
            _2 = parseString(reader)
            var _3: String?
            _3 = parseString(reader)
            var _4: String?
            _4 = parseString(reader)
            var _5: String?
            if Int(_1!) & Int(1 << 1) != 0 {_5 = parseString(reader) }
            var _6: String?
            _6 = parseString(reader)
            var _7: Int32?
            _7 = reader.readInt32()
            var _8: Int32?
            _8 = reader.readInt32()
            var _9: String?
            _9 = parseString(reader)
            let _c1 = _1 != nil
            let _c2 = _2 != nil
            let _c3 = _3 != nil
            let _c4 = _4 != nil
            let _c5 = (Int(_1!) & Int(1 << 1) == 0) || _5 != nil
            let _c6 = _6 != nil
            let _c7 = _7 != nil
            let _c8 = _8 != nil
            let _c9 = _9 != nil
            if _c1 && _c2 && _c3 && _c4 && _c5 && _c6 && _c7 && _c8 && _c9 {
                return Api.LangPackLanguage.langPackLanguage(flags: _1!, name: _2!, nativeName: _3!, langCode: _4!, baseLangCode: _5, pluralCode: _6!, stringsCount: _7!, translatedCount: _8!, translationsUrl: _9!)
            }
            else {
                return nil
            }
        }
    
    }
}
