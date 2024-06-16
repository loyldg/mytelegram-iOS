import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ContextUI
import TelegramCore
import TextFormat
import ReactionSelectionNode
import WallpaperBackgroundNode

public enum SendMessageActionSheetControllerParams {
    public final class SendMessage {
        public let isScheduledMessages: Bool
        public let mediaPreview: ChatSendMessageContextScreenMediaPreview?
        public let mediaCaptionIsAbove: (Bool, (Bool) -> Void)?
        public let attachment: Bool
        public let canSendWhenOnline: Bool
        public let forwardMessageIds: [EngineMessage.Id]
        
        public init(
            isScheduledMessages: Bool,
            mediaPreview: ChatSendMessageContextScreenMediaPreview?,
            mediaCaptionIsAbove: (Bool, (Bool) -> Void)?,
            attachment: Bool,
            canSendWhenOnline: Bool,
            forwardMessageIds: [EngineMessage.Id]
        ) {
            self.isScheduledMessages = isScheduledMessages
            self.mediaPreview = mediaPreview
            self.mediaCaptionIsAbove = mediaCaptionIsAbove
            self.attachment = attachment
            self.canSendWhenOnline = canSendWhenOnline
            self.forwardMessageIds = forwardMessageIds
        }
    }
    
    public final class EditMessage {
        public let messages: [EngineMessage]
        public let mediaPreview: ChatSendMessageContextScreenMediaPreview?
        public let mediaCaptionIsAbove: (Bool, (Bool) -> Void)?
        
        public init(messages: [EngineMessage], mediaPreview: ChatSendMessageContextScreenMediaPreview?, mediaCaptionIsAbove: (Bool, (Bool) -> Void)?) {
            self.messages = messages
            self.mediaPreview = mediaPreview
            self.mediaCaptionIsAbove = mediaCaptionIsAbove
        }
    }
    
    case sendMessage(SendMessage)
    case editMessage(EditMessage)
}

public func makeChatSendMessageActionSheetController(
    context: AccountContext,
    updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)? = nil,
    peerId: EnginePeer.Id?,
    params: SendMessageActionSheetControllerParams,
    hasEntityKeyboard: Bool,
    gesture: ContextGesture,
    sourceSendButton: ASDisplayNode,
    textInputView: UITextView,
    emojiViewProvider: ((ChatTextInputTextCustomEmojiAttribute) -> UIView)?,
    wallpaperBackgroundNode: WallpaperBackgroundNode? = nil,
    completion: @escaping () -> Void,
    sendMessage: @escaping (ChatSendMessageActionSheetController.SendMode, ChatSendMessageActionSheetController.SendParameters?) -> Void,
    schedule: @escaping (ChatSendMessageActionSheetController.SendParameters?) -> Void,
    openPremiumPaywall: @escaping (ViewController) -> Void,
    reactionItems: [ReactionItem]? = nil,
    availableMessageEffects: AvailableMessageEffects? = nil,
    isPremium: Bool = false
) -> ChatSendMessageActionSheetController {
    return ChatSendMessageContextScreen(
        context: context,
        updatedPresentationData: updatedPresentationData,
        peerId: peerId,
        params: params,
        hasEntityKeyboard: hasEntityKeyboard,
        gesture: gesture,
        sourceSendButton: sourceSendButton,
        textInputView: textInputView,
        emojiViewProvider: emojiViewProvider,
        wallpaperBackgroundNode: wallpaperBackgroundNode,
        completion: completion,
        sendMessage: sendMessage,
        schedule: schedule,
        openPremiumPaywall: openPremiumPaywall,
        reactionItems: reactionItems,
        availableMessageEffects: availableMessageEffects,
        isPremium: isPremium
    )
}
