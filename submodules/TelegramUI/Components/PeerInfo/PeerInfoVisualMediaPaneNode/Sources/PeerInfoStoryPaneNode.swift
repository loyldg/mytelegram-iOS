import AsyncDisplayKit
import AVFoundation
import Display
import TelegramCore
import SwiftSignalKit
import Postbox
import TelegramPresentationData
import AccountContext
import ContextUI
import PhotoResources
import RadialStatusNode
import TelegramStringFormatting
import GridMessageSelectionNode
import UniversalMediaPlayer
import ListMessageItem
import ChatMessageInteractiveMediaBadge
import SparseItemGrid
import ShimmerEffect
import QuartzCore
import DirectMediaImageCache
import ComponentFlow
import TelegramNotices
import TelegramUIPreferences
import CheckNode
import AppBundle
import InvisibleInkDustNode
import MediaPickerUI
import StoryContainerScreen
import EmptyStateIndicatorComponent
import UIKitRuntimeUtils
import PeerInfoPaneNode
import ShareController
import UndoUI
import PlainButtonComponent
import ComponentDisplayAdapters
import MediaEditorScreen
import AvatarNode

private let mediaBadgeBackgroundColor = UIColor(white: 0.0, alpha: 0.6)
private let mediaBadgeTextColor = UIColor.white

private final class VisualMediaItemInteraction {
    let openItem: (EngineStoryItem) -> Void
    let openItemContextActions: (EngineStoryItem, ASDisplayNode, CGRect, ContextGesture?) -> Void
    let toggleSelection: (Int32, Bool) -> Void
    
    var hiddenMedia = Set<Int32>()
    var selectedIds: Set<Int32>?
    
    init(
        openItem: @escaping (EngineStoryItem) -> Void,
        openItemContextActions: @escaping (EngineStoryItem, ASDisplayNode, CGRect, ContextGesture?) -> Void,
        toggleSelection: @escaping (Int32, Bool) -> Void
    ) {
        self.openItem = openItem
        self.openItemContextActions = openItemContextActions
        self.toggleSelection = toggleSelection
    }
}

private final class VisualMediaHoleAnchor: SparseItemGrid.HoleAnchor {
    let storyId: Int32
    override var id: AnyHashable {
        return AnyHashable(self.storyId)
    }

    let indexValue: Int
    override var index: Int {
        return self.indexValue
    }

    let localMonthTimestamp: Int32
    override var tag: Int32 {
        return self.localMonthTimestamp
    }

    init(index: Int, storyId: Int32, localMonthTimestamp: Int32) {
        self.indexValue = index
        self.storyId = storyId
        self.localMonthTimestamp = localMonthTimestamp
    }
}

private final class VisualMediaItem: SparseItemGrid.Item {
    let indexValue: Int
    override var index: Int {
        return self.indexValue
    }
    let localMonthTimestamp: Int32
    let peer: PeerReference
    let story: EngineStoryItem
    let authorPeer: EnginePeer?
    let isPinned: Bool

    override var id: AnyHashable {
        return AnyHashable(self.story.id)
    }

    override var tag: Int32 {
        return self.localMonthTimestamp
    }

    override var holeAnchor: SparseItemGrid.HoleAnchor {
        return VisualMediaHoleAnchor(index: self.index, storyId: self.story.id, localMonthTimestamp: self.localMonthTimestamp)
    }
    
    init(index: Int, peer: PeerReference, story: EngineStoryItem, authorPeer: EnginePeer?, isPinned: Bool, localMonthTimestamp: Int32) {
        self.indexValue = index
        self.peer = peer
        self.story = story
        self.authorPeer = authorPeer
        self.isPinned = isPinned
        self.localMonthTimestamp = localMonthTimestamp
    }
}

private struct Month: Equatable {
    var packedValue: Int32

    init(packedValue: Int32) {
        self.packedValue = packedValue
    }

    init(localTimestamp: Int32) {
        var time: time_t = time_t(localTimestamp)
        var timeinfo: tm = tm()
        gmtime_r(&time, &timeinfo)

        let year = UInt32(timeinfo.tm_year)
        let month = UInt32(timeinfo.tm_mon)

        self.packedValue = Int32(bitPattern: year | (month << 16))
    }

    var year: Int32 {
        return Int32(bitPattern: (UInt32(bitPattern: self.packedValue) >> 0) & 0xffff)
    }

    var month: Int32 {
        return Int32(bitPattern: (UInt32(bitPattern: self.packedValue) >> 16) & 0xffff)
    }
}

private let durationFont: UIFont = {
    Font.semibold(11.0)
}()

private let avatarFont: UIFont = {
    avatarPlaceholderFont(size: 10.0)
}()

private let minDurationImage: UIImage = {
    let image = generateImage(CGSize(width: 20.0, height: 20.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setFillColor(UIColor(white: 0.0, alpha: 0.5).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
        if let image = UIImage(bundleImageName: "Chat/GridPlayIcon") {
            UIGraphicsPushContext(context)
            image.draw(in: CGRect(origin: CGPoint(x: (size.width - image.size.width) / 2.0, y: (size.height - image.size.height) / 2.0), size: image.size))
            UIGraphicsPopContext()
        }
    })
    return image!
}()

private let leftShadowImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Peer Info/MediaGridShadow")!
    let image = generateImage(baseImage.size, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
        context.scaleBy(x: -1.0, y: 1.0)
        context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private let rightShadowImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Peer Info/MediaGridShadow")!
    let image = generateImage(baseImage.size, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private let topRightShadowImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Peer Info/MediaGridShadow")!
    let image = generateImage(baseImage.size, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private let topLeftShadowImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Peer Info/MediaGridShadow")!
    let image = generateImage(baseImage.size, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
        context.scaleBy(x: -1.0, y: -1.0)
        context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private let viewCountImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Peer Info/MediaGridViewCount")!
    let image = generateImage(baseImage.size, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private let privacyTypeImageScaleFactor: CGFloat = {
    return 0.9
}()

private let topRightIconPinnedImage: UIImage = {
    let baseImage = generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/Pinned"), color: .white)!
    let imageSize = CGSize(width: floor(baseImage.size.width * 1.0), height: floor(baseImage.size.width * 1.0))
    let image = generateImage(CGSize(width: imageSize.width + 4.0, height: imageSize.height + 4.0), rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(x: 0.0, y: 4.0), size: imageSize))
        UIGraphicsPopContext()
    })
    return image!
}()

private let privacyTypeContactsImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Stories/PrivacyContacts")!
    let imageSize = CGSize(width: floor(baseImage.size.width * privacyTypeImageScaleFactor), height: floor(baseImage.size.width * privacyTypeImageScaleFactor))
    let image = generateImage(imageSize, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private let privacyTypeCloseFriendsImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Stories/PrivacyCloseFriends")!
    let imageSize = CGSize(width: floor(baseImage.size.width * privacyTypeImageScaleFactor), height: floor(baseImage.size.width * privacyTypeImageScaleFactor))
    let image = generateImage(imageSize, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private let privacyTypeSelectedImage: UIImage = {
    let baseImage = UIImage(bundleImageName: "Stories/PrivacySelectedContacts")!
    let imageSize = CGSize(width: floor(baseImage.size.width * privacyTypeImageScaleFactor), height: floor(baseImage.size.width * privacyTypeImageScaleFactor))
    let image = generateImage(imageSize, rotatedContext: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        
        UIGraphicsPushContext(context)
        baseImage.draw(in: CGRect(origin: CGPoint(), size: size))
        UIGraphicsPopContext()
    })
    return image!
}()

private enum ItemTopRightIcon {
    case privacyContacts
    case privacyCloseFriends
    case privacySelected
    case pinned
}

private final class DurationLayer: SimpleLayer {
    private var authorPeerId: EnginePeer.Id?
    private var avatarLayer: SimpleLayer?
    private var disposable: Disposable?
    
    override init() {
        super.init()

        self.contentsGravity = .topRight
        self.contentsScale = UIScreenScale
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.disposable?.dispose()
    }

    override func action(forKey event: String) -> CAAction? {
        return nullAction
    }
    
    func update(viewCount: Int32, isMin: Bool) {
        if isMin {
            self.contents = nil
        } else {
            let countString: String
            if viewCount > 1000000 {
                countString = "\(viewCount / 1000000)M"
            } else if viewCount > 1000 {
                countString = "\(viewCount / 1000)K"
            } else {
                countString = "\(viewCount)"
            }
            let string = NSAttributedString(string: countString, font: durationFont, textColor: .white)
            let bounds = string.boundingRect(with: CGSize(width: 100.0, height: 100.0), options: .usesLineFragmentOrigin, context: nil)
            let textSize = CGSize(width: ceil(bounds.width), height: ceil(bounds.height))
            let sideInset: CGFloat = 6.0
            let verticalInset: CGFloat = 2.0
            let iconSpacing: CGFloat = -3.0
            let image = generateImage(CGSize(width: viewCountImage.size.width + iconSpacing + textSize.width + sideInset * 2.0, height: textSize.height + verticalInset * 2.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.setBlendMode(.normal)
                
                context.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: 2.5, color: UIColor(rgb: 0x000000, alpha: 0.22).cgColor)
                
                UIGraphicsPushContext(context)
                
                viewCountImage.draw(in: CGRect(origin: CGPoint(x: 0.0, y: (size.height - viewCountImage.size.height) * 0.5), size: viewCountImage.size))
                
                string.draw(in: bounds.offsetBy(dx: sideInset + viewCountImage.size.width + iconSpacing, dy: verticalInset))
                UIGraphicsPopContext()
            })
            self.contents = image?.cgImage
        }
    }

    func update(duration: Int32, isMin: Bool) {
        if isMin {
            self.contents = minDurationImage.cgImage
        } else {
            let string = NSAttributedString(string: stringForDuration(duration), font: durationFont, textColor: .white)
            let bounds = string.boundingRect(with: CGSize(width: 100.0, height: 100.0), options: .usesLineFragmentOrigin, context: nil)
            let textSize = CGSize(width: ceil(bounds.width), height: ceil(bounds.height))
            let sideInset: CGFloat = 6.0
            let verticalInset: CGFloat = 2.0
            let image = generateImage(CGSize(width: textSize.width + sideInset * 2.0, height: textSize.height + verticalInset * 2.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.setBlendMode(.normal)
                
                context.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: 2.5, color: UIColor(rgb: 0x000000, alpha: 0.22).cgColor)
                
                UIGraphicsPushContext(context)
                string.draw(in: bounds.offsetBy(dx: sideInset, dy: verticalInset))
                UIGraphicsPopContext()
            })
            self.contents = image?.cgImage
        }
    }
    
    func update(topRightIcon: ItemTopRightIcon, isMin: Bool) {
        if isMin {
            self.contents = nil
        } else {
            let iconImage: UIImage
            switch topRightIcon {
            case .pinned:
                iconImage = topRightIconPinnedImage
            case .privacyContacts:
                iconImage = privacyTypeContactsImage
            case .privacyCloseFriends:
                iconImage = privacyTypeCloseFriendsImage
            case .privacySelected:
                iconImage = privacyTypeSelectedImage
            }
            
            let sideInset: CGFloat = 0.0
            let verticalInset: CGFloat = 0.0
            let image = generateImage(CGSize(width: iconImage.size.width + sideInset * 2.0, height: iconImage.size.height + verticalInset * 2.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.setBlendMode(.normal)
                
                context.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: 2.5, color: UIColor(rgb: 0x000000, alpha: 0.22).cgColor)
                
                UIGraphicsPushContext(context)
                
                iconImage.draw(in: CGRect(origin: CGPoint(x: (size.width - iconImage.size.width) * 0.5, y: (size.height - iconImage.size.height) * 0.5), size: iconImage.size))
                
                UIGraphicsPopContext()
            })
            self.contents = image?.cgImage
        }
    }
    
    func copyAuthor(from other: DurationLayer) {
        self.contents = other.contents
        
        let avatarLayer: SimpleLayer
        if let current = self.avatarLayer {
            avatarLayer = current
        } else {
            avatarLayer = SimpleLayer()
            self.avatarLayer = avatarLayer
            self.addSublayer(avatarLayer)
            
            avatarLayer.frame = CGRect(origin: CGPoint(x: -11.0, y: 2.0), size: CGSize(width: 13.0, height: 13.0))
            avatarLayer.cornerRadius = 13.0 * 0.5
            avatarLayer.masksToBounds = true
        }
        avatarLayer.contents = other.avatarLayer?.contents
    }
    
    func update(directMediaImageCache: DirectMediaImageCache, author: EnginePeer, synchronous: SparseItemGrid.Synchronous) {
        let avatarLayer: SimpleLayer
        if let current = self.avatarLayer {
            avatarLayer = current
        } else {
            avatarLayer = SimpleLayer()
            self.avatarLayer = avatarLayer
            self.addSublayer(avatarLayer)
            
            avatarLayer.frame = CGRect(origin: CGPoint(x: -11.0, y: 2.0), size: CGSize(width: 13.0, height: 13.0))
            avatarLayer.cornerRadius = 13.0 * 0.5
            avatarLayer.masksToBounds = true
        }
        
        if self.authorPeerId != author.id {
            let string = NSAttributedString(string: author.debugDisplayTitle, font: durationFont, textColor: .white)
            let bounds = string.boundingRect(with: CGSize(width: 100.0, height: 100.0), options: .usesLineFragmentOrigin, context: nil)
            let textSize = CGSize(width: ceil(bounds.width), height: ceil(bounds.height))
            let sideInset: CGFloat = 6.0
            let verticalInset: CGFloat = 2.0
            let image = generateImage(CGSize(width: textSize.width + sideInset * 2.0, height: textSize.height + verticalInset * 2.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                context.setBlendMode(.normal)
                
                context.setShadow(offset: CGSize(width: 0.0, height: 0.0), blur: 2.5, color: UIColor(rgb: 0x000000, alpha: 0.22).cgColor)
                
                UIGraphicsPushContext(context)
                string.draw(in: bounds.offsetBy(dx: sideInset, dy: verticalInset))
                UIGraphicsPopContext()
            })
            self.contents = image?.cgImage
            
            if let smallProfileImage = author.smallProfileImage, let peerReference = PeerReference(author._asPeer()) {
                if let result = directMediaImageCache.getAvatarImage(peer: peerReference, resource: MediaResourceReference.avatar(peer: peerReference, resource: smallProfileImage.resource), immediateThumbnail: smallProfileImage.immediateThumbnailData, size: 24, includeBlurred: true, synchronous: synchronous == .full) {
                    if let image = result.image {
                        avatarLayer.contents = image.cgImage
                    } else if let image = result.blurredImage {
                        avatarLayer.contents = image.cgImage
                    }
                    if let loadSignal = result.loadSignal {
                        self.disposable?.dispose()
                        self.disposable = (loadSignal
                        |> deliverOnMainQueue).start(next: { [weak self] image in
                            guard let self else {
                                return
                            }
                            self.avatarLayer?.contents = image?.cgImage
                        })
                    }
                }
            } else {
                self.avatarLayer?.contents = generateImage(CGSize(width: 24.0, height: 24.0), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))
                    
                    drawPeerAvatarLetters(context: context, size: size, font: avatarFont, letters: author.displayLetters, peerId: author.id, nameColor: author.nameColor)
                })?.cgImage
            }
        }
    }
}

private final class ItemLayer: CALayer, SparseItemGridLayer {
    var item: VisualMediaItem?
    var viewCountLayer: DurationLayer?
    var durationLayer: DurationLayer?
    var privacyTypeLayer: DurationLayer?
    var authorLayer: DurationLayer?
    var leftShadowLayer: SimpleLayer?
    var rightShadowLayer: SimpleLayer?
    var topRightShadowLayer: SimpleLayer?
    var topLeftShadowLayer: SimpleLayer?
    var minFactor: CGFloat = 1.0
    var selectionLayer: GridMessageSelectionLayer?
    var dustLayer: MediaDustLayer?
    var disposable: Disposable?

    var hasContents: Bool = false

    override init() {
        super.init()

        self.contentsGravity = .resize
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.disposable?.dispose()
    }
    
    func getContents() -> Any? {
        return self.contents
    }
    
    func setContents(_ contents: Any?) {
        if let image = contents as? UIImage {
            self.contents = image.cgImage
        }
    }
    
    func setSpoilerContents(_ contents: Any?) {
        if let image = contents as? UIImage {
            self.dustLayer?.contents = image.cgImage
        }
    }

    override func action(forKey event: String) -> CAAction? {
        return nullAction
    }

    func bind(item: VisualMediaItem) {
        self.item = item
    }

    func updateDuration(viewCount: Int32?, duration: Int32?, topRightIcon: ItemTopRightIcon?, author: EnginePeer?, isMin: Bool, minFactor: CGFloat, directMediaImageCache: DirectMediaImageCache, synchronous: SparseItemGrid.Synchronous) {
        self.minFactor = minFactor
        
        if let viewCount {
            if let viewCountLayer = self.viewCountLayer {
                viewCountLayer.update(viewCount: viewCount, isMin: isMin)
            } else {
                let viewCountLayer = DurationLayer()
                viewCountLayer.contentsGravity = .topLeft
                viewCountLayer.update(viewCount: viewCount, isMin: isMin)
                self.addSublayer(viewCountLayer)
                viewCountLayer.frame = CGRect(origin: CGPoint(x: 7.0, y: self.bounds.height - 4.0), size: CGSize())
                viewCountLayer.transform = CATransform3DMakeScale(minFactor, minFactor, 1.0)
                self.viewCountLayer = viewCountLayer
            }
        } else if let viewCountLayer = self.viewCountLayer {
            self.viewCountLayer = nil
            viewCountLayer.removeFromSuperlayer()
        }

        if let duration {
            if let durationLayer = self.durationLayer {
                durationLayer.update(duration: duration, isMin: isMin)
            } else {
                let durationLayer = DurationLayer()
                durationLayer.update(duration: duration, isMin: isMin)
                self.addSublayer(durationLayer)
                durationLayer.frame = CGRect(origin: CGPoint(x: self.bounds.width - 3.0, y: self.bounds.height - 4.0), size: CGSize())
                durationLayer.transform = CATransform3DMakeScale(minFactor, minFactor, 1.0)
                self.durationLayer = durationLayer
            }
        } else if let durationLayer = self.durationLayer {
            self.durationLayer = nil
            durationLayer.removeFromSuperlayer()
        }
        
        if let topRightIcon {
            if let privacyTypeLayer = self.privacyTypeLayer {
                privacyTypeLayer.update(topRightIcon: topRightIcon, isMin: isMin)
            } else {
                let privacyTypeLayer = DurationLayer()
                privacyTypeLayer.contentsGravity = .bottomRight
                privacyTypeLayer.update(topRightIcon: topRightIcon, isMin: isMin)
                self.addSublayer(privacyTypeLayer)
                privacyTypeLayer.frame = CGRect(origin: CGPoint(x: self.bounds.width - 2.0, y: 3.0), size: CGSize())
                privacyTypeLayer.transform = CATransform3DMakeScale(minFactor, minFactor, 1.0)
                self.privacyTypeLayer = privacyTypeLayer
            }
        } else if let privacyTypeLayer = self.privacyTypeLayer {
            self.privacyTypeLayer = nil
            privacyTypeLayer.removeFromSuperlayer()
        }
        
        if let author {
            if let authorLayer = self.authorLayer {
                authorLayer.update(directMediaImageCache: directMediaImageCache, author: author, synchronous: synchronous)
            } else {
                let authorLayer = DurationLayer()
                authorLayer.contentsGravity = .bottomLeft
                authorLayer.update(directMediaImageCache: directMediaImageCache, author: author, synchronous: synchronous)
                self.addSublayer(authorLayer)
                authorLayer.frame = CGRect(origin: CGPoint(x: 17.0, y: 3.0), size: CGSize())
                authorLayer.transform = CATransform3DMakeScale(minFactor, minFactor, 1.0)
                self.authorLayer = authorLayer
            }
        } else if let authorLayer = self.authorLayer {
            self.authorLayer = nil
            authorLayer.removeFromSuperlayer()
        }
        
        let size = self.bounds.size
        
        if self.viewCountLayer != nil {
            if self.leftShadowLayer == nil {
                let leftShadowLayer = SimpleLayer()
                self.leftShadowLayer = leftShadowLayer
                self.insertSublayer(leftShadowLayer, at: 0)
                leftShadowLayer.contents = leftShadowImage.cgImage
                let shadowSize = CGSize(width: min(size.width, leftShadowImage.size.width), height: min(size.height, leftShadowImage.size.height))
                leftShadowLayer.frame = CGRect(origin: CGPoint(x: 0.0, y: size.height - shadowSize.height), size: shadowSize)
            }
        } else {
            if let leftShadowLayer = self.leftShadowLayer {
                self.leftShadowLayer = nil
                leftShadowLayer.removeFromSuperlayer()
            }
        }
        
        if self.durationLayer != nil {
            if self.rightShadowLayer == nil {
                let rightShadowLayer = SimpleLayer()
                self.rightShadowLayer = rightShadowLayer
                self.insertSublayer(rightShadowLayer, at: 0)
                rightShadowLayer.contents = rightShadowImage.cgImage
                let shadowSize = CGSize(width: min(size.width, rightShadowImage.size.width), height: min(size.height, rightShadowImage.size.height))
                rightShadowLayer.frame = CGRect(origin: CGPoint(x: size.width - shadowSize.width, y: size.height - shadowSize.height), size: shadowSize)
            }
        } else {
            if let rightShadowLayer = self.rightShadowLayer {
                self.rightShadowLayer = nil
                rightShadowLayer.removeFromSuperlayer()
            }
        }
        
        if self.privacyTypeLayer != nil {
            if self.topRightShadowLayer == nil {
                let topRightShadowLayer = SimpleLayer()
                self.topRightShadowLayer = topRightShadowLayer
                self.insertSublayer(topRightShadowLayer, at: 0)
                topRightShadowLayer.contents = topRightShadowImage.cgImage
                let shadowSize = CGSize(width: min(size.width, topRightShadowImage.size.width), height: min(size.height, topRightShadowImage.size.height))
                topRightShadowLayer.frame = CGRect(origin: CGPoint(x: size.width - shadowSize.width, y: 0.0), size: shadowSize)
            }
        } else {
            if let topRightShadowLayer = self.topRightShadowLayer {
                self.topRightShadowLayer = nil
                topRightShadowLayer.removeFromSuperlayer()
            }
        }
        
        if self.authorLayer != nil {
            if self.topLeftShadowLayer == nil {
                let topLeftShadowLayer = SimpleLayer()
                self.topLeftShadowLayer = topLeftShadowLayer
                self.insertSublayer(topLeftShadowLayer, at: 0)
                topLeftShadowLayer.contents = topLeftShadowImage.cgImage
                let shadowSize = CGSize(width: min(size.width, topLeftShadowImage.size.width), height: min(size.height, topLeftShadowImage.size.height))
                topLeftShadowLayer.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: shadowSize)
            }
        } else {
            if let topLeftShadowLayer = self.topLeftShadowLayer {
                self.topLeftShadowLayer = nil
                topLeftShadowLayer.removeFromSuperlayer()
            }
        }
    }

    func updateSelection(theme: CheckNodeTheme, isSelected: Bool?, animated: Bool) {
        if let isSelected = isSelected {
            if let selectionLayer = self.selectionLayer {
                selectionLayer.updateSelected(isSelected, animated: animated)
            } else {
                let selectionLayer = GridMessageSelectionLayer(theme: theme)
                selectionLayer.updateSelected(isSelected, animated: false)
                self.selectionLayer = selectionLayer
                self.addSublayer(selectionLayer)
                if !self.bounds.isEmpty {
                    selectionLayer.frame = CGRect(origin: CGPoint(), size: self.bounds.size)
                    selectionLayer.updateLayout(size: self.bounds.size)
                    if animated {
                        selectionLayer.animateIn()
                    }
                }
            }
        } else if let selectionLayer = self.selectionLayer {
            self.selectionLayer = nil
            if animated {
                selectionLayer.animateOut { [weak selectionLayer] in
                    selectionLayer?.removeFromSuperlayer()
                }
            } else {
                selectionLayer.removeFromSuperlayer()
            }
        }
        
        if let privacyTypeLayer = self.privacyTypeLayer {
            let privacyAlpha: Float = isSelected == nil ? 1.0 : 0.0
            if privacyAlpha != privacyTypeLayer.opacity {
                let previousAlpha = privacyTypeLayer.opacity
                privacyTypeLayer.opacity = privacyAlpha
                privacyTypeLayer.animateAlpha(from: CGFloat(previousAlpha), to: CGFloat(privacyAlpha), duration: 0.2)
            }
        }
        
        if let authorLayer = self.authorLayer {
            let authorAlpha: Float = isSelected == nil ? 1.0 : 0.0
            if authorAlpha != authorLayer.opacity {
                let previousAlpha = authorLayer.opacity
                authorLayer.opacity = authorAlpha
                authorLayer.animateAlpha(from: CGFloat(previousAlpha), to: CGFloat(authorAlpha), duration: 0.2)
            }
        }
    }
    
    func updateHasSpoiler(hasSpoiler: Bool) {
        if hasSpoiler {
            if let _ = self.dustLayer {
            } else {
                let dustLayer = MediaDustLayer()
                self.dustLayer = dustLayer
                self.addSublayer(dustLayer)
                if !self.bounds.isEmpty {
                    dustLayer.frame = CGRect(origin: CGPoint(), size: self.bounds.size)
                    dustLayer.updateLayout(size: self.bounds.size)
                }
            }
        } else if let dustLayer = self.dustLayer {
            self.dustLayer = nil
            dustLayer.removeFromSuperlayer()
        }
    }

    func unbind() {
        self.item = nil
    }

    func needsShimmer() -> Bool {
        return !self.hasContents
    }

    func update(size: CGSize, insets: UIEdgeInsets, displayItem: SparseItemGridDisplayItem, binding: SparseItemGridBinding, item: SparseItemGrid.Item?) {
        if let viewCountLayer = self.viewCountLayer {
            viewCountLayer.frame = CGRect(origin: CGPoint(x: 7.0, y: size.height - 4.0), size: CGSize())
        }
        if let durationLayer = self.durationLayer {
            durationLayer.frame = CGRect(origin: CGPoint(x: size.width - 3.0, y: size.height - 4.0), size: CGSize())
        }
        if let privacyTypeLayer = self.privacyTypeLayer {
            privacyTypeLayer.frame = CGRect(origin: CGPoint(x: size.width - 2.0, y: 3.0), size: CGSize())
        }
        if let authorLayer = self.authorLayer {
            authorLayer.frame = CGRect(origin: CGPoint(x: 17.0, y: 3.0), size: CGSize())
        }
        
        if let leftShadowLayer = self.leftShadowLayer {
            let shadowSize = CGSize(width: min(size.width, leftShadowImage.size.width), height: min(size.height, leftShadowImage.size.height))
            leftShadowLayer.frame = CGRect(origin: CGPoint(x: 0.0, y: size.height - shadowSize.height), size: shadowSize)
        }
        
        if let rightShadowLayer = self.rightShadowLayer {
            let shadowSize = CGSize(width: min(size.width, rightShadowImage.size.width), height: min(size.height, rightShadowImage.size.height))
            rightShadowLayer.frame = CGRect(origin: CGPoint(x: size.width - shadowSize.width, y: size.height - shadowSize.height), size: shadowSize)
        }
        
        if let topRightShadowLayer = self.topRightShadowLayer {
            let shadowSize = CGSize(width: min(size.width, topRightShadowImage.size.width), height: min(size.height, topRightShadowImage.size.height))
            topRightShadowLayer.frame = CGRect(origin: CGPoint(x: size.width - shadowSize.width, y: 0.0), size: shadowSize)
        }
        
        if let topLeftShadowLayer = self.topLeftShadowLayer {
            let shadowSize = CGSize(width: min(size.width, topLeftShadowImage.size.width), height: min(size.height, topLeftShadowImage.size.height))
            topLeftShadowLayer.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: shadowSize)
        }
        
        if let binding = binding as? SparseItemGridBindingImpl, let item = item as? VisualMediaItem, let previousItem = self.item {
            if previousItem.story.media.id != item.story.media.id {
                binding.bindLayers(items: [item], layers: [displayItem], size: size, insets: insets, synchronous: .none)
            } else {
                if let layer = displayItem.layer as? ItemLayer {
                    var selectedMedia: Media?
                    if let image = item.story.media._asMedia() as? TelegramMediaImage {
                        selectedMedia = image
                    } else if let file = item.story.media._asMedia() as? TelegramMediaFile {
                        selectedMedia = file
                    }
                    
                    if let selectedMedia {
                        binding.updateLayerData(story: item.story, item: item, selectedMedia: selectedMedia, layer: layer, synchronous: .none)
                    }
                }
            }
        }
    }
}

private final class ItemTransitionView: UIView {
    private weak var itemLayer: CALayer?
    private var copyDurationLayer: SimpleLayer?
    private var copyViewCountLayer: SimpleLayer?
    private var copyPrivacyTypeLayer: SimpleLayer?
    private var copyAuthorLayer: SimpleLayer?
    private var copyLeftShadowLayer: SimpleLayer?
    private var copyRightShadowLayer: SimpleLayer?
    private var copyTopRightShadowLayer: SimpleLayer?
    private var copyTopLeftShadowLayer: SimpleLayer?
    
    private var viewCountLayerBottomLeftPosition: CGPoint?
    private var durationLayerBottomLeftPosition: CGPoint?
    private var privacyTypeLayerTopRightPosition: CGPoint?
    private var authorLayerTopLeftPosition: CGPoint?
    
    var selectionLayer: GridMessageSelectionLayer?
    
    init(itemLayer: CALayer?) {
        self.itemLayer = itemLayer
        
        super.init(frame: CGRect())
        
        if let itemLayer {
            self.layer.contentsRect = itemLayer.contentsRect
            
            var viewCountLayer: CALayer?
            var durationLayer: CALayer?
            var privacyTypeLayer: CALayer?
            var authorLayer: CALayer?
            var leftShadowLayer: CALayer?
            var rightShadowLayer: CALayer?
            var topRightShadowLayer: CALayer?
            var topLeftShadowLayer: CALayer?
            if let itemLayer = itemLayer as? ItemLayer {
                viewCountLayer = itemLayer.viewCountLayer
                durationLayer = itemLayer.durationLayer
                privacyTypeLayer = itemLayer.privacyTypeLayer
                authorLayer = itemLayer.authorLayer
                leftShadowLayer = itemLayer.leftShadowLayer
                rightShadowLayer = itemLayer.rightShadowLayer
                topRightShadowLayer = itemLayer.topRightShadowLayer
                topLeftShadowLayer = itemLayer.topLeftShadowLayer
                self.layer.contents = itemLayer.contents
            }
            
            if let leftShadowLayer {
                let copyLayer = SimpleLayer()
                copyLayer.contents = leftShadowLayer.contents
                copyLayer.contentsRect = leftShadowLayer.contentsRect
                copyLayer.contentsGravity = leftShadowLayer.contentsGravity
                copyLayer.contentsScale = leftShadowLayer.contentsScale
                copyLayer.frame = leftShadowLayer.frame
                self.layer.addSublayer(copyLayer)
                self.copyLeftShadowLayer = copyLayer
            }
            
            if let rightShadowLayer {
                let copyLayer = SimpleLayer()
                copyLayer.contents = rightShadowLayer.contents
                copyLayer.contentsRect = rightShadowLayer.contentsRect
                copyLayer.contentsGravity = rightShadowLayer.contentsGravity
                copyLayer.contentsScale = rightShadowLayer.contentsScale
                copyLayer.frame = rightShadowLayer.frame
                self.layer.addSublayer(copyLayer)
                self.copyRightShadowLayer = copyLayer
            }
            
            if let topRightShadowLayer {
                let copyLayer = SimpleLayer()
                copyLayer.contents = topRightShadowLayer.contents
                copyLayer.contentsRect = topRightShadowLayer.contentsRect
                copyLayer.contentsGravity = topRightShadowLayer.contentsGravity
                copyLayer.contentsScale = topRightShadowLayer.contentsScale
                copyLayer.frame = topRightShadowLayer.frame
                self.layer.addSublayer(copyLayer)
                self.copyTopRightShadowLayer = copyLayer
            }
            
            if let topLeftShadowLayer {
                let copyLayer = SimpleLayer()
                copyLayer.contents = topLeftShadowLayer.contents
                copyLayer.contentsRect = topLeftShadowLayer.contentsRect
                copyLayer.contentsGravity = topLeftShadowLayer.contentsGravity
                copyLayer.contentsScale = topLeftShadowLayer.contentsScale
                copyLayer.frame = topLeftShadowLayer.frame
                self.layer.addSublayer(copyLayer)
                self.copyTopLeftShadowLayer = copyLayer
            }
            
            if let viewCountLayer {
                let copyViewCountLayer = SimpleLayer()
                copyViewCountLayer.contents = viewCountLayer.contents
                copyViewCountLayer.contentsRect = viewCountLayer.contentsRect
                copyViewCountLayer.contentsGravity = viewCountLayer.contentsGravity
                copyViewCountLayer.contentsScale = viewCountLayer.contentsScale
                copyViewCountLayer.frame = viewCountLayer.frame
                self.layer.addSublayer(copyViewCountLayer)
                self.copyViewCountLayer = copyViewCountLayer
                
                self.viewCountLayerBottomLeftPosition = CGPoint(x: viewCountLayer.frame.minX, y: itemLayer.bounds.height - viewCountLayer.frame.maxY)
            }
            
            if let privacyTypeLayer {
                let copyPrivacyTypeLayer = SimpleLayer()
                copyPrivacyTypeLayer.contents = privacyTypeLayer.contents
                copyPrivacyTypeLayer.contentsRect = privacyTypeLayer.contentsRect
                copyPrivacyTypeLayer.contentsGravity = privacyTypeLayer.contentsGravity
                copyPrivacyTypeLayer.contentsScale = privacyTypeLayer.contentsScale
                copyPrivacyTypeLayer.frame = privacyTypeLayer.frame
                self.layer.addSublayer(copyPrivacyTypeLayer)
                self.copyPrivacyTypeLayer = copyPrivacyTypeLayer
                
                self.privacyTypeLayerTopRightPosition = CGPoint(x: itemLayer.bounds.width - privacyTypeLayer.frame.maxX, y: privacyTypeLayer.frame.minY)
            }
            
            if let authorLayer = authorLayer as? DurationLayer {
                let copyAuthorLayer = DurationLayer()
                copyAuthorLayer.contentsRect = authorLayer.contentsRect
                copyAuthorLayer.contentsGravity = authorLayer.contentsGravity
                copyAuthorLayer.contentsScale = authorLayer.contentsScale
                copyAuthorLayer.frame = authorLayer.frame
                copyAuthorLayer.copyAuthor(from: authorLayer)
                self.layer.addSublayer(copyAuthorLayer)
                self.copyAuthorLayer = copyAuthorLayer
                
                self.authorLayerTopLeftPosition = CGPoint(x: authorLayer.frame.minX, y: authorLayer.frame.minY)
            }
            
            if let durationLayer {
                let copyDurationLayer = SimpleLayer()
                copyDurationLayer.contents = durationLayer.contents
                copyDurationLayer.contentsRect = durationLayer.contentsRect
                copyDurationLayer.contentsGravity = durationLayer.contentsGravity
                copyDurationLayer.contentsScale = durationLayer.contentsScale
                copyDurationLayer.frame = durationLayer.frame
                self.layer.addSublayer(copyDurationLayer)
                self.copyDurationLayer = copyDurationLayer
                
                self.durationLayerBottomLeftPosition = CGPoint(x: itemLayer.bounds.width - durationLayer.frame.maxX, y: itemLayer.bounds.height - durationLayer.frame.maxY)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(state: StoryContainerScreen.TransitionState, transition: Transition) {
        let size = state.sourceSize.interpolate(to: state.destinationSize, amount: state.progress)
        
        if let copyDurationLayer = self.copyDurationLayer, let durationLayerBottomLeftPosition = self.durationLayerBottomLeftPosition {
            transition.setFrame(layer: copyDurationLayer, frame: CGRect(origin: CGPoint(x: size.width - durationLayerBottomLeftPosition.x - copyDurationLayer.bounds.width, y: size.height - durationLayerBottomLeftPosition.y - copyDurationLayer.bounds.height), size: copyDurationLayer.bounds.size))
        }
        
        if let copyViewCountLayer = self.copyViewCountLayer, let viewCountLayerBottomLeftPosition = self.viewCountLayerBottomLeftPosition {
            transition.setFrame(layer: copyViewCountLayer, frame: CGRect(origin: CGPoint(x: viewCountLayerBottomLeftPosition.x, y: size.height - viewCountLayerBottomLeftPosition.y - copyViewCountLayer.bounds.height), size: copyViewCountLayer.bounds.size))
        }
        
        if let privacyTypeLayer = self.copyPrivacyTypeLayer, let privacyTypeLayerTopRightPosition = self.privacyTypeLayerTopRightPosition {
            transition.setFrame(layer: privacyTypeLayer, frame: CGRect(origin: CGPoint(x: size.width - privacyTypeLayerTopRightPosition.x, y: privacyTypeLayerTopRightPosition.y), size: privacyTypeLayer.bounds.size))
        }
        
        if let authorLayer = self.copyAuthorLayer, let authorLayerTopLeftPosition = self.authorLayerTopLeftPosition {
            transition.setFrame(layer: authorLayer, frame: CGRect(origin: CGPoint(x: authorLayerTopLeftPosition.x, y: authorLayerTopLeftPosition.y), size: authorLayer.bounds.size))
        }
        
        if let copyLeftShadowLayer = self.copyLeftShadowLayer {
            transition.setFrame(layer: copyLeftShadowLayer, frame: CGRect(origin: CGPoint(x: 0.0, y: size.height - copyLeftShadowLayer.bounds.height), size: copyLeftShadowLayer.bounds.size))
        }
        
        if let copyRightShadowLayer = self.copyRightShadowLayer {
            transition.setFrame(layer: copyRightShadowLayer, frame: CGRect(origin: CGPoint(x: size.width - copyRightShadowLayer.bounds.width, y: size.height - copyRightShadowLayer.bounds.height), size: copyRightShadowLayer.bounds.size))
        }
        
        if let copyTopRightShadowLayer = self.copyTopRightShadowLayer {
            transition.setFrame(layer: copyTopRightShadowLayer, frame: CGRect(origin: CGPoint(x: size.width - copyTopRightShadowLayer.bounds.width, y: 0.0), size: copyTopRightShadowLayer.bounds.size))
        }
        
        if let copyTopLeftShadowLayer = self.copyTopLeftShadowLayer {
            transition.setFrame(layer: copyTopLeftShadowLayer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: copyTopLeftShadowLayer.bounds.size))
        }
    }
    
    func updateSelection(theme: CheckNodeTheme, isSelected: Bool?, animated: Bool) {
        if let isSelected = isSelected {
            if let selectionLayer = self.selectionLayer {
                selectionLayer.updateSelected(isSelected, animated: animated)
            } else {
                let selectionLayer = GridMessageSelectionLayer(theme: theme)
                selectionLayer.updateSelected(isSelected, animated: false)
                self.selectionLayer = selectionLayer
                self.layer.addSublayer(selectionLayer)
                if !self.bounds.isEmpty {
                    selectionLayer.frame = CGRect(origin: CGPoint(), size: self.bounds.size)
                    selectionLayer.updateLayout(size: self.bounds.size)
                    if animated {
                        selectionLayer.animateIn()
                    }
                }
            }
        } else if let selectionLayer = self.selectionLayer {
            self.selectionLayer = nil
            if animated {
                selectionLayer.animateOut { [weak selectionLayer] in
                    selectionLayer?.removeFromSuperlayer()
                }
            } else {
                selectionLayer.removeFromSuperlayer()
            }
        }
        
        if let copyPrivacyTypeLayer = self.copyPrivacyTypeLayer {
            let privacyAlpha: Float = isSelected == nil ? 1.0 : 0.0
            if privacyAlpha != copyPrivacyTypeLayer.opacity {
                let previousAlpha = copyPrivacyTypeLayer.opacity
                copyPrivacyTypeLayer.opacity = privacyAlpha
                copyPrivacyTypeLayer.animateAlpha(from: CGFloat(previousAlpha), to: CGFloat(privacyAlpha), duration: 0.2)
            }
        }
        
        if let copyAuthorLayer = self.copyAuthorLayer {
            let privacyAlpha: Float = isSelected == nil ? 1.0 : 0.0
            if privacyAlpha != copyAuthorLayer.opacity {
                let previousAlpha = copyAuthorLayer.opacity
                copyAuthorLayer.opacity = privacyAlpha
                copyAuthorLayer.animateAlpha(from: CGFloat(previousAlpha), to: CGFloat(privacyAlpha), duration: 0.2)
            }
        }
    }
}

private final class SparseItemGridBindingImpl: SparseItemGridBinding {
    let context: AccountContext
    let directMediaImageCache: DirectMediaImageCache
    let captureProtected: Bool
    let displayPrivacy: Bool
    var strings: PresentationStrings
    var chatPresentationData: ChatPresentationData
    var checkNodeTheme: CheckNodeTheme

    var itemInteraction: VisualMediaItemInteraction?
    var loadHoleImpl: ((SparseItemGrid.HoleAnchor, SparseItemGrid.HoleLocation) -> Signal<Never, NoError>)?
    var onTapImpl: ((VisualMediaItem, CALayer, CGPoint) -> Void)?
    var onTagTapImpl: (() -> Void)?
    var didScrollImpl: (() -> Void)?
    var coveringInsetOffsetUpdatedImpl: ((ContainedViewLayoutTransition) -> Void)?
    var onBeginFastScrollingImpl: (() -> Void)?
    var getShimmerColorsImpl: (() -> SparseItemGrid.ShimmerColors)?
    var updateShimmerLayersImpl: ((SparseItemGridDisplayItem) -> Void)?
    
    var revealedSpoilerMessageIds = Set<MessageId>()

    private var shimmerImages: [CGFloat: UIImage] = [:]

    init(context: AccountContext, directMediaImageCache: DirectMediaImageCache, captureProtected: Bool, displayPrivacy: Bool) {
        self.context = context
        self.directMediaImageCache = directMediaImageCache
        self.captureProtected = false
        self.displayPrivacy = displayPrivacy

        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        self.strings = presentationData.strings

        let themeData = ChatPresentationThemeData(theme: presentationData.theme, wallpaper: presentationData.chatWallpaper)
        self.chatPresentationData = ChatPresentationData(theme: themeData, fontSize: presentationData.chatFontSize, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat, nameDisplayOrder: presentationData.nameDisplayOrder, disableAnimations: true, largeEmoji: presentationData.largeEmoji, chatBubbleCorners: presentationData.chatBubbleCorners, animatedEmojiScale: 1.0)

        self.checkNodeTheme = CheckNodeTheme(theme: presentationData.theme, style: .overlay, hasInset: true)
    }

    func updatePresentationData(presentationData: PresentationData) {
        self.strings = presentationData.strings

        let themeData = ChatPresentationThemeData(theme: presentationData.theme, wallpaper: presentationData.chatWallpaper)
        self.chatPresentationData = ChatPresentationData(theme: themeData, fontSize: presentationData.chatFontSize, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat, nameDisplayOrder: presentationData.nameDisplayOrder, disableAnimations: true, largeEmoji: presentationData.largeEmoji, chatBubbleCorners: presentationData.chatBubbleCorners, animatedEmojiScale: 1.0)

        self.checkNodeTheme = CheckNodeTheme(theme: presentationData.theme, style: .overlay, hasInset: true)
    }

    func getSeparatorColor() -> UIColor {
        return self.chatPresentationData.theme.theme.list.itemPlainSeparatorColor
    }

    func createLayer(item: SparseItemGrid.Item) -> SparseItemGridLayer? {
        if let item = item as? VisualMediaItem, item.story.isForwardingDisabled {
            let layer = ItemLayer()
            setLayerDisableScreenshots(layer, true)
            return layer
        } else {
            return ItemLayer()
        }
    }

    func createView() -> SparseItemGridView? {
        return nil
    }

    func createShimmerLayer() -> SparseItemGridShimmerLayer? {
        return nil
    }

    private static let widthSpecs: ([Int], [Int]) = {
        let list: [(Int, Int)] = [
            (50, 64),
            (100, 150),
            (140, 200),
            (Int.max, 280)
        ]
        return (list.map(\.0), list.map(\.1))
    }()

    func bindLayers(items: [SparseItemGrid.Item], layers: [SparseItemGridDisplayItem], size: CGSize, insets: UIEdgeInsets, synchronous: SparseItemGrid.Synchronous) {
        for i in 0 ..< items.count {
            guard let item = items[i] as? VisualMediaItem else {
                continue
            }

            let displayItem = layers[i]

            guard let layer = displayItem.layer as? ItemLayer else {
                continue
            }
            if layer.bounds.isEmpty {
                continue
            }
            
            var imageWidthSpec: Int = SparseItemGridBindingImpl.widthSpecs.1[0]
            for i in 0 ..< SparseItemGridBindingImpl.widthSpecs.0.count {
                if Int(layer.bounds.width) <= SparseItemGridBindingImpl.widthSpecs.0[i] {
                    imageWidthSpec = SparseItemGridBindingImpl.widthSpecs.1[i]
                    break
                }
            }
            
            let story = item.story
            let hasSpoiler = false
            layer.updateHasSpoiler(hasSpoiler: hasSpoiler)
            
            var selectedMedia: Media?
            if let image = story.media._asMedia() as? TelegramMediaImage {
                selectedMedia = image
            } else if let file = story.media._asMedia() as? TelegramMediaFile {
                selectedMedia = file
            }
            
            if let selectedMedia = selectedMedia {
                if let result = directMediaImageCache.getImage(peer: item.peer, story: story, media: selectedMedia, width: imageWidthSpec, aspectRatio: 0.81, possibleWidths: SparseItemGridBindingImpl.widthSpecs.1, includeBlurred: hasSpoiler || displayItem.blurLayer != nil, synchronous: synchronous == .full) {
                    if let image = result.image {
                        layer.setContents(image)
                        switch synchronous {
                        case .none:
                            layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2, completion: { [weak self, weak layer, weak displayItem] _ in
                                layer?.hasContents = true
                                if let displayItem = displayItem {
                                    self?.updateShimmerLayersImpl?(displayItem)
                                }
                            })
                        default:
                            layer.hasContents = true
                        }
                    }
                    if let image = result.blurredImage {
                        layer.setSpoilerContents(image)
                        
                        if let blurLayer = displayItem.blurLayer {
                            blurLayer.contentsGravity = .resizeAspectFill
                            blurLayer.contents = result.blurredImage?.cgImage
                        }
                    }
                    if let loadSignal = result.loadSignal {
                        layer.disposable?.dispose()
                        let startTimestamp = CFAbsoluteTimeGetCurrent()
                        layer.disposable = (loadSignal
                        |> deliverOnMainQueue).start(next: { [weak self, weak layer, weak displayItem] image in
                            guard let layer = layer else {
                                return
                            }
                            let deltaTime = CFAbsoluteTimeGetCurrent() - startTimestamp
                            let synchronousValue: Bool
                            switch synchronous {
                            case .none, .full:
                                synchronousValue = false
                            case .semi:
                                synchronousValue = deltaTime < 0.1
                            }
                            
                            if let contents = layer.getContents(), !synchronousValue {
                                let copyLayer = ItemLayer()
                                copyLayer.contents = contents
                                copyLayer.contentsRect = layer.contentsRect
                                copyLayer.frame = layer.bounds
                                if let durationLayer = layer.durationLayer {
                                    layer.insertSublayer(copyLayer, below: durationLayer)
                                } else {
                                    layer.addSublayer(copyLayer)
                                }
                                copyLayer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak copyLayer] _ in
                                    copyLayer?.removeFromSuperlayer()
                                })
                                
                                layer.setContents(image)
                                layer.hasContents = true
                                if let displayItem = displayItem {
                                    self?.updateShimmerLayersImpl?(displayItem)
                                }
                            } else {
                                layer.setContents(image)
                                
                                if !synchronousValue {
                                    layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2, completion: { [weak layer] _ in
                                        layer?.hasContents = true
                                        if let displayItem = displayItem {
                                            self?.updateShimmerLayersImpl?(displayItem)
                                        }
                                    })
                                } else {
                                    layer.hasContents = true
                                    if let displayItem = displayItem {
                                        self?.updateShimmerLayersImpl?(displayItem)
                                    }
                                }
                            }
                            
                            if let displayItem, let blurLayer = displayItem.blurLayer {
                                blurLayer.contentsGravity = .resizeAspectFill
                                blurLayer.contents = result.blurredImage?.cgImage
                            }
                        })
                    }
                }
                
                self.updateLayerData(story: story, item: item, selectedMedia: selectedMedia, layer: layer, synchronous: synchronous)
            }
            
            var isSelected: Bool?
            if let selectedIds = self.itemInteraction?.selectedIds {
                isSelected = selectedIds.contains(story.id)
            }
            layer.updateSelection(theme: self.checkNodeTheme, isSelected: isSelected, animated: false)
            
            layer.bind(item: item)
        }
    }
    
    func updateLayerData(story: EngineStoryItem, item: VisualMediaItem, selectedMedia: Media, layer: ItemLayer, synchronous: SparseItemGrid.Synchronous) {
        var viewCount: Int32?
        if let value = story.views?.seenCount {
            viewCount = Int32(value)
        }
        
        var topRightIcon: ItemTopRightIcon?
        if item.isPinned {
            topRightIcon = .pinned
        } else if self.displayPrivacy, let value = story.privacy {
            switch value.base {
            case .everyone:
                break
            case .contacts:
                topRightIcon = .privacyContacts
            case .closeFriends:
                topRightIcon = .privacyCloseFriends
            case .nobody:
                topRightIcon = .privacySelected
            }
        }
        
        var duration: Int32?
        var isMin: Bool = false
        if let file = selectedMedia as? TelegramMediaFile, !file.isAnimated {
            if let durationValue = file.duration {
                duration = Int32(durationValue)
            }
            isMin = layer.bounds.width < 80.0
        }
        
        layer.updateDuration(viewCount: viewCount, duration: duration, topRightIcon: topRightIcon, author: item.authorPeer, isMin: isMin, minFactor: min(1.0, layer.bounds.height / 74.0), directMediaImageCache: self.directMediaImageCache, synchronous: synchronous)
    }

    func unbindLayer(layer: SparseItemGridLayer) {
        guard let layer = layer as? ItemLayer else {
            return
        }
        layer.unbind()
    }

    func scrollerTextForTag(tag: Int32) -> String? {
        let month = Month(packedValue: tag)
        return stringForMonth(strings: self.strings, month: month.month, ofYear: month.year)
    }

    func loadHole(anchor: SparseItemGrid.HoleAnchor, at location: SparseItemGrid.HoleLocation) -> Signal<Never, NoError> {
        if let loadHoleImpl = self.loadHoleImpl {
            return loadHoleImpl(anchor, location)
        } else {
            return .never()
        }
    }

    func onTap(item: SparseItemGrid.Item, itemLayer: CALayer, point: CGPoint) {
        guard let item = item as? VisualMediaItem else {
            return
        }
        self.onTapImpl?(item, itemLayer, point)
    }

    func onTagTap() {
        self.onTagTapImpl?()
    }

    func didScroll() {
        self.didScrollImpl?()
    }

    func coveringInsetOffsetUpdated(transition: ContainedViewLayoutTransition) {
        self.coveringInsetOffsetUpdatedImpl?(transition)
    }

    func onBeginFastScrolling() {
        self.onBeginFastScrollingImpl?()
    }

    func getShimmerColors() -> SparseItemGrid.ShimmerColors {
        if let getShimmerColorsImpl = self.getShimmerColorsImpl {
            return getShimmerColorsImpl()
        } else {
            return SparseItemGrid.ShimmerColors(background: 0xffffff, foreground: 0xffffff)
        }
    }
}

public final class PeerInfoStoryPaneNode: ASDisplayNode, PeerInfoPaneNode, ASScrollViewDelegate, ASGestureRecognizerDelegate {
    public enum ContentType {
        case photoOrVideo
        case photo
        case video
    }

    public struct ZoomLevel {
        fileprivate var value: SparseItemGrid.ZoomLevel

        init(_ value: SparseItemGrid.ZoomLevel) {
            self.value = value
        }

        var rawValue: Int32 {
            return Int32(self.value.rawValue)
        }

        public init(rawValue: Int32) {
            self.value = SparseItemGrid.ZoomLevel(rawValue: Int(rawValue))
        }
    }
    
    private let context: AccountContext
    private let peerId: PeerId?
    private let searchQuery: String?
    private let isSaved: Bool
    private let isArchive: Bool
    private let isProfileEmbedded: Bool
    private let canManageStories: Bool
    public private(set) var contentType: ContentType
    private var contentTypePromise: ValuePromise<ContentType>
    
    private let navigationController: () -> NavigationController?
    
    public weak var parentController: ViewController?

    private let contextGestureContainerNode: ContextControllerSourceNode
    private let itemGrid: SparseItemGrid
    private let itemGridBinding: SparseItemGridBindingImpl
    private let directMediaImageCache: DirectMediaImageCache
    private var items: SparseItemGrid.Items?
    private var pinnedIds: Set<Int32> = Set()
    private var didUpdateItemsOnce: Bool = false
    
    private var selectionPanel: ComponentView<Empty>?

    private var isDeceleratingAfterTracking = false
    
    private var _itemInteraction: VisualMediaItemInteraction?
    private var itemInteraction: VisualMediaItemInteraction {
        return self._itemInteraction!
    }
    
    public var selectedIds: Set<Int32> {
        return self.itemInteraction.selectedIds ?? Set()
    }
    private let selectedIdsPromise = ValuePromise<Set<Int32>>(Set())
    public var updatedSelectedIds: Signal<Set<Int32>, NoError> {
        return self.selectedIdsPromise.get()
    }
    
    public var selectedItems: [Int32: EngineStoryItem] {
        var result: [Int32: EngineStoryItem] = [:]
        for id in self.selectedIds {
            if let items = self.items {
                for item in items.items {
                    if let item = item as? VisualMediaItem {
                        if item.story.id == id {
                            result[id] = item.story
                        }
                    }
                }
            }
        }
        return result
    }
    
    public var isEmpty: Bool {
        if let items = self.items, items.items.count != 0 {
            return false
        } else {
            return true
        }
    }
    
    public var isEmptyUpdated: (Bool) -> Void = { _ in }
    
    public private(set) var isSelectionModeActive: Bool
    
    private var currentParams: (size: CGSize, topInset: CGFloat, sideInset: CGFloat, bottomInset: CGFloat, deviceMetrics: DeviceMetrics, visibleHeight: CGFloat, isScrollingLockedAtTop: Bool, expandProgress: CGFloat, navigationHeight: CGFloat, presentationData: PresentationData)?
    
    private let ready = Promise<Bool>()
    private var didSetReady: Bool = false
    public var isReady: Signal<Bool, NoError> {
        return self.ready.get()
    }

    private let statusPromise = Promise<PeerInfoStatusData?>(nil)
    public var status: Signal<PeerInfoStatusData?, NoError> {
        self.statusPromise.get()
    }

    public var tabBarOffsetUpdated: ((ContainedViewLayoutTransition) -> Void)?
    public var tabBarOffset: CGFloat {
        return self.itemGrid.coveringInsetOffset
    }
        
    private var listDisposable: Disposable?
    private var hiddenMediaDisposable: Disposable?
    private let updateDisposable = MetaDisposable()
    
    private var numberOfItemsToRequest: Int = 50
    private var isRequestingView: Bool = false
    private var isFirstHistoryView: Bool = true
    
    private var decelerationAnimator: ConstantDisplayLinkAnimator?
    
    private var animationTimer: SwiftSignalKit.Timer?

    public private(set) var calendarSource: SparseMessageCalendar?
    private var listSource: PeerStoryListContext

    public var openCurrentDate: (() -> Void)?
    public var paneDidScroll: (() -> Void)?
    public var emptyAction: (() -> Void)?
    public var additionalEmptyAction: (() -> Void)?
    
    public var ensureRectVisible: ((UIView, CGRect) -> Void)?

    private weak var currentGestureItem: SparseItemGridDisplayItem?

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private weak var pendingOpenListContext: PeerStoryListContentContextImpl?
    
    private var preloadArchiveListContext: PeerStoryListContext?
    
    private var emptyStateView: ComponentView<Empty>?
    
    private weak var contextControllerToDismissOnSelection: ContextControllerProtocol?
    private weak var tempContextContentItemNode: TempExtractedItemNode?
        
    public init(context: AccountContext, peerId: PeerId?, searchQuery: String? = nil, contentType: ContentType, captureProtected: Bool, isSaved: Bool, isArchive: Bool, isProfileEmbedded: Bool, canManageStories: Bool, navigationController: @escaping () -> NavigationController?, listContext: PeerStoryListContext?) {
        self.context = context
        self.peerId = peerId
        self.searchQuery = searchQuery
        self.contentType = contentType
        self.contentTypePromise = ValuePromise<ContentType>(contentType)
        self.navigationController = navigationController
        self.isSaved = isSaved
        self.isArchive = isArchive
        self.isProfileEmbedded = isProfileEmbedded
        self.canManageStories = canManageStories
        
        self.isSelectionModeActive = !isProfileEmbedded && isArchive

        self.presentationData = self.context.sharedContext.currentPresentationData.with { $0 }

        self.contextGestureContainerNode = ContextControllerSourceNode()
        self.itemGrid = SparseItemGrid(theme: self.presentationData.theme)
        self.directMediaImageCache = DirectMediaImageCache(account: context.account)

        self.itemGridBinding = SparseItemGridBindingImpl(
            context: context,
            directMediaImageCache: self.directMediaImageCache,
            captureProtected: captureProtected,
            displayPrivacy: isProfileEmbedded
        )

        self.listSource = listContext ?? PeerStoryListContext(account: context.account, peerId: peerId ?? context.account.peerId, isArchived: self.isArchive)
        self.calendarSource = nil
        
        super.init()

        if self.peerId != nil {
            let _ = (ApplicationSpecificNotice.getSharedMediaScrollingTooltip(accountManager: context.sharedContext.accountManager)
                     |> deliverOnMainQueue).start(next: { [weak self] count in
                guard let strongSelf = self else {
                    return
                }
                if count < 1 {
                    strongSelf.itemGrid.updateScrollingAreaTooltip(tooltip: SparseItemGridScrollingArea.DisplayTooltip(animation: "anim_infotip", text: strongSelf.itemGridBinding.chatPresentationData.strings.SharedMedia_FastScrollTooltip, completed: {
                        guard let strongSelf = self else {
                            return
                        }
                        let _ = ApplicationSpecificNotice.incrementSharedMediaScrollingTooltip(accountManager: strongSelf.context.sharedContext.accountManager, count: 1).start()
                    }))
                }
            })
        }

        self.itemGridBinding.loadHoleImpl = { [weak self] hole, location in
            guard let strongSelf = self else {
                return .never()
            }
            return strongSelf.loadHole(anchor: hole, at: location)
        }

        self.itemGridBinding.onTapImpl = { [weak self] item, itemLayer, point in
            guard let self else {
                return
            }
            
            if self.isProfileEmbedded {
                if let selectedIds = self.itemInteraction.selectedIds {
                    self.itemInteraction.toggleSelection(item.story.id, !selectedIds.contains(item.story.id))
                    return
                }
            } else {
                if let selectedIds = self.itemInteraction.selectedIds, let itemLayer = itemLayer as? ItemLayer, let selectionLayer = itemLayer.selectionLayer {
                    if selectionLayer.checkLayer.frame.insetBy(dx: -4.0, dy: -4.0).contains(point) {
                        self.itemInteraction.toggleSelection(item.story.id, !selectedIds.contains(item.story.id))
                        return
                    }
                }
            }
            
            if self.pendingOpenListContext != nil {
                return
            }
            
            //TODO:localize
            let listContext = PeerStoryListContentContextImpl(
                context: self.context,
                peerId: self.peerId ?? self.context.account.peerId,
                listContext: self.listSource,
                initialId: item.story.id
            )
            self.pendingOpenListContext = listContext
            self.itemGrid.isUserInteractionEnabled = false
            
            let _ = (listContext.state
            |> take(1)
            |> deliverOnMainQueue).start(next: { [weak self] _ in
                guard let self, let navigationController = self.navigationController() else {
                    return
                }
                
                guard let pendingOpenListContext = self.pendingOpenListContext, pendingOpenListContext === listContext else {
                    return
                }
                self.pendingOpenListContext = nil
                self.itemGrid.isUserInteractionEnabled = true
                
                var transitionIn: StoryContainerScreen.TransitionIn?
                
                let story = item.story
                var foundItem: SparseItemGridDisplayItem?
                var foundItemLayer: SparseItemGridLayer?
                self.itemGrid.forEachVisibleItem { item in
                    guard let itemLayer = item.layer as? ItemLayer else {
                        return
                    }
                    foundItem = item
                    if let listItem = itemLayer.item, listItem.story.id == story.id {
                        foundItemLayer = itemLayer
                    }
                }
                if let foundItemLayer {
                    let itemRect = self.itemGrid.frameForItem(layer: foundItemLayer)
                    transitionIn = StoryContainerScreen.TransitionIn(
                        sourceView: self.view,
                        sourceRect: self.itemGrid.view.convert(itemRect, to: self.view),
                        sourceCornerRadius: 0.0,
                        sourceIsAvatar: false
                    )
                    
                    if let blurLayer = foundItem?.blurLayer {
                        let transition = Transition(animation: .curve(duration: 0.25, curve: .easeInOut))
                        transition.setAlpha(layer: blurLayer, alpha: 0.0)
                    }
                }
                
                let storyContainerScreen = StoryContainerScreen(
                    context: self.context,
                    content: listContext,
                    transitionIn: transitionIn,
                    transitionOut: { [weak self] _, itemId in
                        guard let self else {
                            return nil
                        }
                        
                        var foundItem: SparseItemGridDisplayItem?
                        var foundItemLayer: SparseItemGridLayer?
                        self.itemGrid.forEachVisibleItem { item in
                            guard let itemLayer = item.layer as? ItemLayer else {
                                return
                            }
                            foundItem = item
                            if let listItem = itemLayer.item, AnyHashable(listItem.story.id) == itemId {
                                foundItemLayer = itemLayer
                            }
                        }
                        if let foundItemLayer {
                            if let blurLayer = foundItem?.blurLayer {
                                let transition = Transition(animation: .curve(duration: 0.25, curve: .easeInOut))
                                transition.setAlpha(layer: blurLayer, alpha: 1.0)
                            }
                            
                            let itemRect = self.itemGrid.frameForItem(layer: foundItemLayer)
                            return StoryContainerScreen.TransitionOut(
                                destinationView: self.view,
                                transitionView: StoryContainerScreen.TransitionView(
                                    makeView: { [weak foundItemLayer] in
                                        return ItemTransitionView(itemLayer: foundItemLayer)
                                    },
                                    updateView: { view, state, transition in
                                        (view as? ItemTransitionView)?.update(state: state, transition: transition)
                                    },
                                    insertCloneTransitionView: { [weak self] view in
                                        guard let self else {
                                            return
                                        }
                                        self.addToTransitionSurface(view: view)
                                    }
                                ),
                                destinationRect: self.itemGrid.view.convert(itemRect, to: self.view),
                                destinationCornerRadius: 0.0,
                                destinationIsAvatar: false,
                                completed: {}
                            )
                        }
                        
                        return nil
                    }
                )
                
                self.hiddenMediaDisposable?.dispose()
                self.hiddenMediaDisposable = (storyContainerScreen.focusedItem
                |> deliverOnMainQueue).start(next: { [weak self] itemId in
                    guard let self else {
                        return
                    }
                    if let itemId {
                        let anyAmount = self.itemInteraction.hiddenMedia.isEmpty
                        self.itemInteraction.hiddenMedia = Set([itemId.id])
                        if let items = self.items, let item = items.items.first(where: { $0.id == AnyHashable(itemId.id) }) {
                            self.itemGrid.ensureItemVisible(index: item.index, anyAmount: anyAmount)
                            
                            if !anyAmount {
                                var foundItemLayer: SparseItemGridLayer?
                                self.itemGrid.forEachVisibleItem { item in
                                    guard let itemLayer = item.layer as? ItemLayer else {
                                        return
                                    }
                                    if let listItem = itemLayer.item, listItem.story.id == itemId.id {
                                        foundItemLayer = itemLayer
                                    }
                                }
                                if let foundItemLayer {
                                    self.ensureRectVisible?(self.view, self.itemGrid.frameForItem(layer: foundItemLayer))
                                }
                            }
                        }
                    } else {
                        self.itemInteraction.hiddenMedia = Set()
                    }
                    
                    self.updateHiddenItems()
                })
                
                navigationController.pushViewController(storyContainerScreen)
            })
        }

        self.itemGridBinding.onTagTapImpl = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.openCurrentDate?()
        }

        self.itemGridBinding.didScrollImpl = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.paneDidScroll?()

            strongSelf.cancelPreviewGestures()
        }

        self.itemGridBinding.coveringInsetOffsetUpdatedImpl = { [weak self] transition in
            guard let strongSelf = self else {
                return
            }
            strongSelf.tabBarOffsetUpdated?(transition)
        }

        var processedOnBeginFastScrolling = false
        self.itemGridBinding.onBeginFastScrollingImpl = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if processedOnBeginFastScrolling {
                return
            }
            processedOnBeginFastScrolling = true

            let _ = (ApplicationSpecificNotice.getSharedMediaFastScrollingTooltip(accountManager: strongSelf.context.sharedContext.accountManager)
            |> deliverOnMainQueue).start(next: { count in
                guard let strongSelf = self else {
                    return
                }
                if count < 1 {
                    let _ = ApplicationSpecificNotice.incrementSharedMediaFastScrollingTooltip(accountManager: strongSelf.context.sharedContext.accountManager).start()

                    var currentNode: ASDisplayNode = strongSelf
                    var result: PeerInfoScreenNodeProtocol?
                    while true {
                        if let currentNode = currentNode as? PeerInfoScreenNodeProtocol {
                            result = currentNode
                            break
                        } else if let supernode = currentNode.supernode {
                            currentNode = supernode
                        } else {
                            break
                        }
                    }
                    if let result = result {
                        result.displaySharedMediaFastScrollingTooltip()
                    }
                }
            })
        }

        self.itemGridBinding.getShimmerColorsImpl = { [weak self] in
            guard let strongSelf = self, let presentationData = strongSelf.currentParams?.presentationData else {
                return SparseItemGrid.ShimmerColors(background: 0xffffff, foreground: 0xffffff)
            }

            let backgroundColor = presentationData.theme.list.mediaPlaceholderColor
            let foregroundColor = presentationData.theme.list.itemBlocksBackgroundColor.withAlphaComponent(0.6)

            return SparseItemGrid.ShimmerColors(background: backgroundColor.argb, foreground: foregroundColor.argb)
        }

        self.itemGridBinding.updateShimmerLayersImpl = { [weak self] layer in
            self?.itemGrid.updateShimmerLayers(item: layer)
        }

        self.itemGrid.cancelExternalContentGestures = { [weak self] in
            self?.contextGestureContainerNode.cancelGesture()
        }

        self.itemGrid.zoomLevelUpdated = { [weak self] zoomLevel in
            guard let strongSelf = self else {
                return
            }
            let _ = strongSelf
            //let _ = updateVisualMediaStoredState(engine: strongSelf.context.engine, peerId: strongSelf.peerId, messageTag: strongSelf.stateTag, state: VisualMediaStoredState(zoomLevel: Int32(zoomLevel.rawValue))).start()
        }
        
        self._itemInteraction = VisualMediaItemInteraction(
            openItem: { [weak self] _ in
                guard let self else {
                    return
                }
                let _ = self
            },
            openItemContextActions: { [weak self] item, sourceNode, sourceRect, gesture in
                guard let self else {
                    return
                }
                let _ = self
            },
            toggleSelection: { [weak self] id, value in
                guard let self, let itemInteraction = self._itemInteraction else {
                    return
                }
                
                if let parentController = self.parentController as? PeerInfoScreen {
                    parentController.toggleStorySelection(ids: [id], isSelected: value)
                } else {
                    if var selectedIds = itemInteraction.selectedIds {
                        if value {
                            selectedIds.insert(id)
                        } else {
                            selectedIds.remove(id)
                        }
                        itemInteraction.selectedIds = selectedIds
                        self.selectedIdsPromise.set(selectedIds)
                        self.updateSelectedItems(animated: true)
                    }
                }
            }
        )
        //TODO:selection
        if self.isSelectionModeActive {
            self._itemInteraction?.selectedIds = Set()
        }
        self.itemGridBinding.itemInteraction = self._itemInteraction

        self.contextGestureContainerNode.isGestureEnabled = self.isProfileEmbedded
        self.contextGestureContainerNode.addSubnode(self.itemGrid)
        self.addSubnode(self.contextGestureContainerNode)

        self.contextGestureContainerNode.shouldBegin = { [weak self] point in
            guard let strongSelf = self else {
                return false
            }
            guard let item = strongSelf.itemGrid.item(at: point) else {
                return false
            }
            guard let layer = item.layer as? ItemLayer else {
                return false
            }
            guard let storyItem = layer.item else {
                return false
            }

            if let result = strongSelf.view.hitTest(point, with: nil) {
                if result.asyncdisplaykit_node is SparseItemGridScrollingArea {
                    return false
                }
            }
            
            if !strongSelf.canManageStories {
                if !storyItem.story.isForwardingDisabled, case .everyone = storyItem.story.privacy?.base {
                } else {
                    return false
                }
            }

            strongSelf.currentGestureItem = item

            return true
        }

        self.contextGestureContainerNode.customActivationProgress = { [weak self] progress, update in
            guard let strongSelf = self, let currentGestureItem = strongSelf.currentGestureItem else {
                return
            }
            guard let itemLayer = currentGestureItem.layer else {
                return
            }

            let targetContentRect = CGRect(origin: CGPoint(), size: itemLayer.bounds.size)

            let scaleSide = itemLayer.bounds.width
            let minScale: CGFloat = max(0.7, (scaleSide - 15.0) / scaleSide)
            let currentScale = 1.0 * (1.0 - progress) + minScale * progress

            let originalCenterOffsetX: CGFloat = itemLayer.bounds.width / 2.0 - targetContentRect.midX
            let scaledCenterOffsetX: CGFloat = originalCenterOffsetX * currentScale

            let originalCenterOffsetY: CGFloat = itemLayer.bounds.height / 2.0 - targetContentRect.midY
            let scaledCenterOffsetY: CGFloat = originalCenterOffsetY * currentScale

            let scaleMidX: CGFloat = scaledCenterOffsetX - originalCenterOffsetX
            let scaleMidY: CGFloat = scaledCenterOffsetY - originalCenterOffsetY

            switch update {
            case .update:
                let sublayerTransform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, currentScale, currentScale, 1.0), scaleMidX, scaleMidY, 0.0)
                itemLayer.transform = sublayerTransform
            case .begin:
                let sublayerTransform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, currentScale, currentScale, 1.0), scaleMidX, scaleMidY, 0.0)
                itemLayer.transform = sublayerTransform
            case .ended:
                let sublayerTransform = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, currentScale, currentScale, 1.0), scaleMidX, scaleMidY, 0.0)
                let previousTransform = itemLayer.transform
                itemLayer.transform = sublayerTransform

                itemLayer.animate(from: NSValue(caTransform3D: previousTransform), to: NSValue(caTransform3D: sublayerTransform), keyPath: "transform", timingFunction: CAMediaTimingFunctionName.easeOut.rawValue, duration: 0.2)
            }
        }

        self.contextGestureContainerNode.activated = { [weak self] gesture, _ in
            guard let strongSelf = self, let currentGestureItem = strongSelf.currentGestureItem else {
                return
            }
            strongSelf.currentGestureItem = nil

            guard let itemLayer = currentGestureItem.layer as? ItemLayer else {
                return
            }
            guard let story = itemLayer.item?.story else {
                return
            }
            let rect = strongSelf.itemGrid.frameForItem(layer: itemLayer)
            
            strongSelf.openContextMenu(item: story, itemLayer: itemLayer, rect: rect, gesture: gesture)
        }
        
        self.statusPromise.set(.single(PeerInfoStatusData(text: "", isActivity: false, key: self.isArchive ? .storyArchive : .stories)))

        self.presentationDataDisposable = (self.context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.itemGridBinding.updatePresentationData(presentationData: presentationData)

            strongSelf.itemGrid.updatePresentationData(theme: presentationData.theme)
        })
        
        self.requestHistoryAroundVisiblePosition(synchronous: false, reloadAtTop: false)
        
        if peerId == context.account.peerId && !isArchive {
            self.preloadArchiveListContext = PeerStoryListContext(account: context.account, peerId: context.account.peerId, isArchived: true)
        }
    }
    
    deinit {
        self.listDisposable?.dispose()
        self.hiddenMediaDisposable?.dispose()
        self.animationTimer?.invalidate()
        self.presentationDataDisposable?.dispose()
        self.updateDisposable.dispose()
    }

    public func loadHole(anchor: SparseItemGrid.HoleAnchor, at location: SparseItemGrid.HoleLocation) -> Signal<Never, NoError> {
        let listSource = self.listSource
        return Signal { subscriber in
            listSource.loadMore(completion: {
                Queue.mainQueue().async {
                    subscriber.putCompletion()
                }
            })
            
            
            return EmptyDisposable
        }
        |> runOn(.mainQueue())
    }
    
    private func openContextMenu(item: EngineStoryItem, itemLayer: ItemLayer, rect: CGRect, gesture: ContextGesture?) {
        guard let parentController = self.parentController else {
            return
        }
        
        let canManage = self.canManageStories
        
        var items: [ContextMenuItem] = []
        
        if canManage, let peerId = self.peerId {
            items.append(.action(ContextMenuActionItem(text: !self.isArchive ? self.presentationData.strings.StoryList_ItemAction_Archive : self.presentationData.strings.StoryList_ItemAction_Unarchive, icon: { theme in generateTintedImage(image: UIImage(bundleImageName: self.isArchive ? "Chat/Context Menu/Archive" : "Chat/Context Menu/Unarchive"), color: theme.contextMenu.primaryColor) }, action: { [weak self] _, f in
                guard let self else {
                    f(.default)
                    return
                }
                
                if self.isArchive {
                    f(.default)
                } else {
                    f(.dismissWithoutContent)
                }
                
                let _ = self.context.engine.messages.updateStoriesArePinned(peerId: peerId, ids: [item.id: item], isPinned: self.isArchive ? true : false).startStandalone()
                self.parentController?.present(UndoOverlayController(presentationData: self.presentationData, content: .actionSucceeded(title: nil, text: self.isArchive ? self.presentationData.strings.StoryList_ToastUnarchived_Text(1) : self.presentationData.strings.StoryList_ToastArchived_Text(1), cancel: nil, destructive: false), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
            })))
            
            if !self.isArchive {
                let isPinned = self.pinnedIds.contains(item.id)
                items.append(.action(ContextMenuActionItem(text: isPinned ? self.presentationData.strings.StoryList_ItemAction_Unpin : self.presentationData.strings.StoryList_ItemAction_Pin, icon: { theme in generateTintedImage(image: UIImage(bundleImageName: isPinned ? "Chat/Context Menu/Unpin" : "Chat/Context Menu/Pin"), color: theme.contextMenu.primaryColor) }, action: { [weak self, weak itemLayer] _, f in
                    itemLayer?.isHidden = false
                    guard let self else {
                        f(.default)
                        return
                    }
                    
                    if !isPinned && self.pinnedIds.count >= 3 {
                        f(.default)
                        
                        let presentationData = self.presentationData
                        self.parentController?.present(UndoOverlayController(presentationData: presentationData, content: .info(title: nil, text: presentationData.strings.StoryList_ToastPinLimit_Text(Int32(3)), timeout: nil, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
                        
                        return
                    }
                    
                    f(.dismissWithoutContent)
                    
                    var updatedPinnedIds = self.pinnedIds
                    if isPinned {
                        updatedPinnedIds.remove(item.id)
                    } else {
                        updatedPinnedIds.insert(item.id)
                    }
                    let _ = self.context.engine.messages.updatePinnedToTopStories(peerId: peerId, ids: Array(updatedPinnedIds)).startStandalone()
                    
                    let presentationData = self.presentationData
                    
                    let toastTitle: String?
                    let toastText: String
                    if isPinned {
                        toastTitle = nil
                        toastText = presentationData.strings.StoryList_ToastUnpinned_Text(1)
                    } else {
                        toastTitle = presentationData.strings.StoryList_ToastPinned_Title(1)
                        toastText = presentationData.strings.StoryList_ToastPinned_Text(1)
                    }
                    self.parentController?.present(UndoOverlayController(presentationData: presentationData, content: .universal(animation: isPinned ? "anim_toastunpin" : "anim_toastpin", scale: 0.06, colors: [:], title: toastTitle, text: toastText, customUndoText: nil, timeout: 5), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
                })))
            }
            
            items.append(.action(ContextMenuActionItem(text: self.presentationData.strings.StoryList_ItemAction_Edit, icon: { theme in generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Edit"), color: theme.contextMenu.primaryColor) }, action: { [weak self] c, _ in
                c?.dismiss(completion: {
                    guard let self else {
                        return
                    }
                    let _ = (self.context.engine.data.get(
                        TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
                    )
                    |> deliverOnMainQueue).startStandalone(next: { [weak self] peer in
                        guard let self, let peer else {
                            return
                        }
                        
                        var foundItemLayer: SparseItemGridLayer?
                        var sourceImage: UIImage?
                        self.itemGrid.forEachVisibleItem { gridItem in
                            guard let itemLayer = gridItem.layer as? ItemLayer else {
                                return
                            }
                            if let listItem = itemLayer.item, listItem.story.id == item.id {
                                foundItemLayer = itemLayer
                                if let contents = itemLayer.contents, CFGetTypeID(contents as CFTypeRef) == CGImage.typeID {
                                    sourceImage = UIImage(cgImage: contents as! CGImage)
                                }
                            }
                        }
                        
                        guard let controller = MediaEditorScreen.makeEditStoryController(
                            context: self.context,
                            peer: peer,
                            storyItem: item,
                            videoPlaybackPosition: nil,
                            repost: false,
                            transitionIn: .gallery(MediaEditorScreen.TransitionIn.GalleryTransitionIn(sourceView: self.itemGrid.view, sourceRect: foundItemLayer?.frame ?? .zero, sourceImage: sourceImage)),
                            transitionOut: MediaEditorScreen.TransitionOut(destinationView: self.itemGrid.view, destinationRect: foundItemLayer?.frame ?? .zero, destinationCornerRadius: 0.0),
                            update: { [weak self] disposable in
                                guard let self else {
                                    return
                                }
                                self.updateDisposable.set(disposable)
                            }
                        ) else {
                            return
                        }
                        self.parentController?.push(controller)
                    })
                })
            })))
        }
        
        if !item.isForwardingDisabled, case .everyone = item.privacy?.base {
            items.append(.action(ContextMenuActionItem(text: self.presentationData.strings.StoryList_ItemAction_Forward, icon: { theme in generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Forward"), color: theme.contextMenu.primaryColor) }, action: { [weak self] c, _ in
                c?.dismiss(completion: {
                    guard let self, let peerId = self.peerId else {
                        return
                    }
                    
                    let _ = (self.context.engine.data.get(
                        TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)
                    )
                    |> deliverOnMainQueue).startStandalone(next: { [weak self] peer in
                        guard let self else {
                            return
                        }
                        guard let peer, let peerReference = PeerReference(peer._asPeer()) else {
                            return
                        }
                        
                        let shareController = ShareController(
                            context: self.context,
                            subject: .media(.story(peer: peerReference, id: item.id, media: TelegramMediaStory(storyId: StoryId(peerId: peer.id, id: item.id), isMention: false))),
                            presetText: nil,
                            preferredAction: .default,
                            showInChat: nil,
                            fromForeignApp: false,
                            segmentedValues: nil,
                            externalShare: false,
                            immediateExternalShare: false,
                            switchableAccounts: [],
                            immediatePeerId: nil,
                            updatedPresentationData: nil,
                            forceTheme: nil,
                            forcedActionTitle: nil,
                            shareAsLink: false,
                            collectibleItemInfo: nil
                        )
                        self.parentController?.present(shareController, in: .window(.root))
                    })
                })
            })))
        }
        
        if canManage {
            items.append(.action(ContextMenuActionItem(text: self.presentationData.strings.StoryList_ItemAction_Delete, textColor: .destructive, icon: { theme in generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Delete"), color: theme.contextMenu.destructiveColor) }, action: { [weak self] c, _ in
                c?.dismiss(completion: {
                    guard let self else {
                        return
                    }
                    
                    self.presentDeleteConfirmation(ids: Set([item.id]))
                })
            })))
        }
        
        if self.canManageStories {
            if !items.isEmpty {
                items.append(.separator)
            }
            items.append(.action(ContextMenuActionItem(text: self.presentationData.strings.Conversation_ContextMenuSelect, icon: { theme in
                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Select"), color: theme.actionSheet.primaryTextColor)
            }, action: { [weak self] c, f in
                guard let self, let parentController = self.parentController as? PeerInfoScreen else {
                    f(.default)
                    return
                }
                
                self.contextControllerToDismissOnSelection = c
                parentController.toggleStorySelection(ids: [item.id], isSelected: true)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: { [weak self] in
                    guard let self, let contextControllerToDismissOnSelection = self.contextControllerToDismissOnSelection else {
                        return
                    }
                    if let contextControllerToDismissOnSelection = contextControllerToDismissOnSelection as? ContextController {
                        contextControllerToDismissOnSelection.dismissWithCustomTransition(transition: .animated(duration: 0.4, curve: .spring), completion: nil)
                    }
                })
            })))
        }
        
        if items.isEmpty {
            return
        }
        
        let tempSourceNode = TempExtractedItemNode(
            item: item,
            itemLayer: itemLayer
        )
        tempSourceNode.frame = rect
        tempSourceNode.update(size: rect.size)
        
        let scaleSide = itemLayer.bounds.width
        let minScale: CGFloat = max(0.7, (scaleSide - 15.0) / scaleSide)
        let currentScale = minScale
        
        ContainedViewLayoutTransition.immediate.updateSublayerTransformScale(node: tempSourceNode.contextSourceNode.contentNode, scale: currentScale)
        ContainedViewLayoutTransition.immediate.updateTransformScale(layer: itemLayer, scale: 1.0)
        
        self.tempContextContentItemNode = tempSourceNode
        self.addSubnode(tempSourceNode)
        
        let contextController = ContextController(presentationData: self.presentationData, source: .extracted(ExtractedContentSourceImpl(controller: parentController, sourceNode: tempSourceNode.contextSourceNode, keepInPlace: false, blurBackground: true)), items: .single(ContextController.Items(content: .list(items))), gesture: gesture)
        parentController.presentInGlobalOverlay(contextController)
    }

    public func updateContentType(contentType: ContentType) {
    }

    public func updateZoomLevel(level: ZoomLevel) {
        self.itemGrid.setZoomLevel(level: level.value)

        //let _ = updateVisualMediaStoredState(engine: self.context.engine, peerId: self.peerId, messageTag: self.stateTag, state: VisualMediaStoredState(zoomLevel: level.rawValue)).start()
    }
    
    public func setIsSelectionModeActive(_ value: Bool) {
        if self.isSelectionModeActive != value {
            self.isSelectionModeActive = value
            
            if value {
                if self._itemInteraction?.selectedIds == nil {
                    self._itemInteraction?.selectedIds = Set()
                }
            } else {
                self._itemInteraction?.selectedIds = nil
            }
            
            self.selectedIdsPromise.set(self._itemInteraction?.selectedIds ?? Set())
            self.updateSelectedItems(animated: true)
        }
    }
    
    public func ensureMessageIsVisible(id: MessageId) {
    }
    
    private func requestHistoryAroundVisiblePosition(synchronous: Bool, reloadAtTop: Bool) {
        if self.isRequestingView {
            return
        }
        self.isRequestingView = true
        var firstTime = true
        let queue = Queue()
        
        let authorPeer: Signal<EnginePeer?, NoError>
        if self.searchQuery != nil {
            authorPeer = self.context.engine.data.get(
                TelegramEngine.EngineData.Item.Peer.Peer(id: self.context.account.peerId)
            )
        } else {
            authorPeer = .single(nil)
        }
        
        var state = self.listSource.state
        if self.peerId == nil && self.listDisposable == nil {
            state = .single(PeerStoryListContext.State(
                peerReference: nil,
                items: [],
                pinnedIds: Set(),
                totalCount: 0,
                loadMoreToken: 0,
                isCached: false,
                hasCache: false,
                allEntityFiles: [:]
            )) |> then(state |> delay(2.0, queue: .mainQueue()))
        }
        
        self.listDisposable?.dispose()
        self.listDisposable = nil

        self.listDisposable = (combineLatest(
            state,
            authorPeer
        )
        |> deliverOn(queue)).startStrict(next: { [weak self] state, authorPeer in
            guard let self else {
                return
            }
            
            let title: String
            if state.totalCount == 0 {
                title = ""
            } else {
                if self.isSaved {
                    title = self.presentationData.strings.StoryList_SubtitleSaved(Int32(state.totalCount))
                } else if self.isArchive {
                    title = self.presentationData.strings.StoryList_SubtitleArchived(Int32(state.totalCount))
                } else {
                    title = self.presentationData.strings.StoryList_SubtitleCount(Int32(state.totalCount))
                }
            }
            self.statusPromise.set(.single(PeerInfoStatusData(text: title, isActivity: false, key: self.isArchive ? .storyArchive : .stories)))
            
            let timezoneOffset = Int32(TimeZone.current.secondsFromGMT())

            var mappedItems: [SparseItemGrid.Item] = []
            var mappedHoles: [SparseItemGrid.HoleAnchor] = []
            var totalCount: Int = 0
            if let peerReference = state.peerReference {
                for item in state.items {
                    mappedItems.append(VisualMediaItem(
                        index: mappedItems.count,
                        peer: peerReference,
                        story: item,
                        authorPeer: authorPeer,
                        isPinned: state.pinnedIds.contains(item.id),
                        localMonthTimestamp: Month(localTimestamp: item.timestamp + timezoneOffset).packedValue
                    ))
                }
                if mappedItems.count < state.totalCount, let lastItem = state.items.last, let loadMoreToken = state.loadMoreToken {
                    mappedHoles.append(VisualMediaHoleAnchor(index: mappedItems.count, storyId: Int32(loadMoreToken), localMonthTimestamp: Month(localTimestamp: lastItem.timestamp + timezoneOffset).packedValue))
                }
            }
            totalCount = state.totalCount
            totalCount = max(mappedItems.count, totalCount)
            
            if totalCount == 0 && state.loadMoreToken != nil && !state.isCached {
                totalCount = 100
            }

            Queue.mainQueue().async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                var headerText: String?
                if strongSelf.isArchive && !mappedItems.isEmpty && strongSelf.peerId == strongSelf.context.account.peerId {
                    headerText = strongSelf.presentationData.strings.StoryList_ArchiveDescription
                }

                let items = SparseItemGrid.Items(
                    items: mappedItems,
                    holeAnchors: mappedHoles,
                    count: totalCount,
                    itemBinding: strongSelf.itemGridBinding,
                    headerText: headerText,
                    snapTopInset: false
                )

                let currentSynchronous = synchronous && firstTime
                let currentReloadAtTop = reloadAtTop && firstTime
                firstTime = false
                strongSelf.updateHistory(items: items, pinnedIds: state.pinnedIds, synchronous: currentSynchronous, reloadAtTop: currentReloadAtTop)
                strongSelf.isRequestingView = false
            }
        })
    }
    
    private func updateHistory(items: SparseItemGrid.Items, pinnedIds: Set<Int32>, synchronous: Bool, reloadAtTop: Bool) {
        self.items = items
        self.pinnedIds = pinnedIds
        self.isEmptyUpdated(self.isEmpty)

        if let (size, topInset, sideInset, bottomInset, deviceMetrics, visibleHeight, isScrollingLockedAtTop, expandProgress, navigationHeight, presentationData) = self.currentParams {
            var gridSnapshot: UIView?
            if reloadAtTop {
                gridSnapshot = self.itemGrid.view.snapshotView(afterScreenUpdates: false)
            }
            self.update(size: size, topInset: topInset, sideInset: sideInset, bottomInset: bottomInset, deviceMetrics: deviceMetrics, visibleHeight: visibleHeight, isScrollingLockedAtTop: isScrollingLockedAtTop, expandProgress: expandProgress, navigationHeight: navigationHeight, presentationData: presentationData, synchronous: false, transition: .immediate)
            self.updateSelectedItems(animated: false)
            if let gridSnapshot = gridSnapshot {
                self.view.addSubview(gridSnapshot)
                gridSnapshot.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak gridSnapshot] _ in
                    gridSnapshot?.removeFromSuperview()
                })
            }
        }

        if !self.didSetReady {
            self.didSetReady = true
            self.ready.set(.single(true))
        }
    }
    
    public func scrollToTop() -> Bool {
        return self.itemGrid.scrollToTop()
    }

    public func hitTestResultForScrolling() -> UIView? {
        return self.itemGrid.hitTestResultForScrolling()
    }

    public func brieflyDisableTouchActions() {
        self.itemGrid.brieflyDisableTouchActions()
    }
    
    public func findLoadedMessage(id: MessageId) -> Message? {
        return nil
    }
    
    public func updateHiddenMedia() {
        //TODO:updateHiddenMedia
        /*self.itemGrid.forEachVisibleItem { item in
            guard let itemLayer = item.layer as? ItemLayer else {
                return
            }
            if let item = itemLayer.item {
                if self.itemInteraction.hiddenMedia[item.message.id] != nil {
                    itemLayer.isHidden = true
                    itemLayer.updateHasSpoiler(hasSpoiler: false)
                    self.itemGridBinding.revealedSpoilerMessageIds.insert(item.message.id)
                } else {
                    itemLayer.isHidden = false
                }
            } else {
                itemLayer.isHidden = false
            }
        }*/
    }
    
    public func transferVelocity(_ velocity: CGFloat) {
        self.itemGrid.transferVelocity(velocity)
    }
    
    public func cancelPreviewGestures() {
    }
    
    public func transitionNodeForGallery(messageId: MessageId, media: Media) -> (ASDisplayNode, CGRect, () -> (UIView?, UIView?))? {
        return nil
        
        /*var foundItemLayer: SparseItemGridLayer?
        self.itemGrid.forEachVisibleItem { item in
            guard let itemLayer = item.layer as? ItemLayer else {
                return
            }
            if let item = itemLayer.item, item.message.id == messageId {
                foundItemLayer = itemLayer
            }
        }
        if let itemLayer = foundItemLayer {
            let itemFrame = self.view.convert(self.itemGrid.frameForItem(layer: itemLayer), from: self.itemGrid.view)
            let proxyNode = ASDisplayNode()
            proxyNode.frame = itemFrame
            if let contents = itemLayer.getContents() {
                if let image = contents as? UIImage {
                    proxyNode.contents = image.cgImage
                } else {
                    proxyNode.contents = contents
                }
            }
            proxyNode.isHidden = true
            self.addSubnode(proxyNode)

            let escapeNotification = EscapeNotification {
                proxyNode.removeFromSupernode()
            }

            return (proxyNode, proxyNode.bounds, {
                let view = UIView()
                view.frame = proxyNode.frame
                view.layer.contents = proxyNode.layer.contents
                escapeNotification.keep()
                return (view, nil)
            })
        }
        return nil*/
    }
    
    public func addToTransitionSurface(view: UIView) {
        self.itemGrid.addToTransitionSurface(view: view)
    }
    
    private var gridSelectionGesture: MediaPickerGridSelectionGesture<Int32>?
    
    override public func didLoad() {
        super.didLoad()
        
        /*let selectionRecognizer = MediaListSelectionRecognizer(target: self, action: #selector(self.selectionPanGesture(_:)))
        selectionRecognizer.shouldBegin = {
            return true
        }
        self.view.addGestureRecognizer(selectionRecognizer)*/
    }
    
    private var selectionPanState: (selecting: Bool, initialMessageId: EngineMessage.Id, toggledMessageIds: [[EngineMessage.Id]])?
    private var selectionScrollActivationTimer: SwiftSignalKit.Timer?
    private var selectionScrollDisplayLink: ConstantDisplayLinkAnimator?
    private var selectionScrollDelta: CGFloat?
    private var selectionLastLocation: CGPoint?
    
    private func storyAtPoint(_ location: CGPoint) -> StoryViewList.Item? {
        return nil
    }
    
    @objc private func selectionPanGesture(_ recognizer: UIGestureRecognizer) -> Void {
        //TODO:selection
        /*let location = recognizer.location(in: self.view)
        switch recognizer.state {
            case .began:
                if let message = self.messageAtPoint(location) {
                    let selecting = !(self.chatControllerInteraction.selectionState?.selectedIds.contains(message.id) ?? false)
                    self.selectionPanState = (selecting, message.id, [])
                    self.chatControllerInteraction.toggleMessagesSelection([message.id], selecting)
                }
            case .changed:
                self.handlePanSelection(location: location)
                self.selectionLastLocation = location
            case .ended, .failed, .cancelled:
                self.selectionPanState = nil
                self.selectionScrollDisplayLink = nil
                self.selectionScrollActivationTimer?.invalidate()
                self.selectionScrollActivationTimer = nil
                self.selectionScrollDelta = nil
                self.selectionLastLocation = nil
                self.selectionScrollSkipUpdate = false
            case .possible:
                break
            @unknown default:
                fatalError()
        }*/
    }
    
    private func handlePanSelection(location: CGPoint) {
    }
    
    private var selectionScrollSkipUpdate = false
    private func setupSelectionScrolling() {
        self.selectionScrollDisplayLink = ConstantDisplayLinkAnimator(update: { [weak self] in
            self?.selectionScrollActivationTimer = nil
            if let strongSelf = self, let delta = strongSelf.selectionScrollDelta {
                let distance: CGFloat = 15.0 * min(1.0, 0.15 + abs(delta * delta))
                let direction: ListViewScrollDirection = delta > 0.0 ? .up : .down
                let _ = strongSelf.itemGrid.scrollWithDelta(direction == .up ? -distance : distance)
                
                if let location = strongSelf.selectionLastLocation {
                    if !strongSelf.selectionScrollSkipUpdate {
                        strongSelf.handlePanSelection(location: location)
                    }
                    strongSelf.selectionScrollSkipUpdate = !strongSelf.selectionScrollSkipUpdate
                }
            }
        })
        self.selectionScrollDisplayLink?.isPaused = false
    }
    
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        /*let location = gestureRecognizer.location(in: gestureRecognizer.view)
        if location.x < 44.0 {
            return false
        }*/
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.state != .failed, let otherGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer {
            let _ = otherGestureRecognizer
            //otherGestureRecognizer.isEnabled = false
            //otherGestureRecognizer.isEnabled = true
            return true
        } else {
            return false
        }
    }
    
    public func clearSelection() {
        self.itemInteraction.selectedIds = Set()
        self.selectedIdsPromise.set(Set())
        self.updateSelectedItems(animated: true)
    }
    
    public func updateSelectedMessages(animated: Bool) {
    }
    
    public func updateSelectedStories(selectedStoryIds: Set<Int32>?, animated: Bool) {
        self.itemInteraction.selectedIds = selectedStoryIds
        self.selectedIdsPromise.set(selectedStoryIds ?? Set())
        
        self.updateSelectedItems(animated: animated)
        
        if let tempContextContentItemNode = self.tempContextContentItemNode, let itemLayer = tempContextContentItemNode.itemLayer {
            let rect = self.itemGrid.frameForItem(layer: itemLayer)
            tempContextContentItemNode.frame = rect
            
            var isSelected: Bool?
            if let selectedIds = self.itemInteraction.selectedIds {
                isSelected = selectedIds.contains(tempContextContentItemNode.item.id)
            }
            tempContextContentItemNode.itemView.updateSelection(theme: self.itemGridBinding.checkNodeTheme, isSelected: isSelected, animated: true)
        }
        
        if let contextControllerToDismissOnSelection = self.contextControllerToDismissOnSelection as? ContextController {
            self.contextControllerToDismissOnSelection = nil
            contextControllerToDismissOnSelection.dismissWithCustomTransition(transition: .animated(duration: 0.4, curve: .spring), completion: nil)
        }
        
        if let (size, topInset, sideInset, bottomInset, deviceMetrics, visibleHeight, isScrollingLockedAtTop, expandProgress, navigationHeight, presentationData) = self.currentParams {
            self.update(size: size, topInset: topInset, sideInset: sideInset, bottomInset: bottomInset, deviceMetrics: deviceMetrics, visibleHeight: visibleHeight, isScrollingLockedAtTop: isScrollingLockedAtTop, expandProgress: expandProgress, navigationHeight: navigationHeight, presentationData: presentationData, synchronous: false, transition: .animated(duration: 0.4, curve: .spring))
        }
    }
    
    private func updateSelectedItems(animated: Bool) {
        self.contextGestureContainerNode.isGestureEnabled = self.isProfileEmbedded && self.itemInteraction.selectedIds == nil
        
        self.itemGrid.forEachVisibleItem { item in
            guard let itemLayer = item.layer as? ItemLayer, let item = itemLayer.item else {
                return
            }
            itemLayer.updateSelection(theme: self.itemGridBinding.checkNodeTheme, isSelected: self.itemInteraction.selectedIds?.contains(item.story.id), animated: animated)
        }

        var isSelecting = false
        if let selectedIds = self._itemInteraction?.selectedIds, !selectedIds.isEmpty {
            isSelecting = true
        }
        self.itemGrid.pinchEnabled = !isSelecting
        
        var enableDismissGesture = true
        if self.isProfileEmbedded {
            enableDismissGesture = true
        } else if let items = self.items, items.items.isEmpty {
        }
        
        if isSelecting {
            enableDismissGesture = false
        }
        self.view.disablesInteractiveTransitionGestureRecognizer = !enableDismissGesture
        
        if isSelecting {
            if self.gridSelectionGesture == nil {
                let selectionGesture = MediaPickerGridSelectionGesture<Int32>()
                selectionGesture.delegate = self.wrappedGestureRecognizerDelegate
                selectionGesture.sideInset = 44.0
                selectionGesture.updateIsScrollEnabled = { [weak self] isEnabled in
                    self?.itemGrid.isScrollEnabled = isEnabled
                }
                selectionGesture.itemAt = { [weak self] point in
                    if let strongSelf = self, let itemLayer = strongSelf.itemGrid.item(at: point)?.layer as? ItemLayer, let storyId = itemLayer.item?.story.id {
                        return (storyId, strongSelf._itemInteraction?.selectedIds?.contains(storyId) ?? false)
                    } else {
                        return nil
                    }
                }
                selectionGesture.updateSelection = { [weak self] storyId, selected in
                    if let strongSelf = self {
                        strongSelf._itemInteraction?.toggleSelection(storyId, selected)
                    }
                }
                self.itemGrid.view.addGestureRecognizer(selectionGesture)
                self.gridSelectionGesture = selectionGesture
            }
        } else if let gridSelectionGesture = self.gridSelectionGesture {
            self.itemGrid.view.removeGestureRecognizer(gridSelectionGesture)
            self.gridSelectionGesture = nil
        }
    }
    
    private func updateHiddenItems() {
        self.itemGrid.forEachVisibleItem { itemValue in
            guard let itemLayer = itemValue.layer as? ItemLayer, let item = itemLayer.item else {
                return
            }
            let itemHidden = self.itemInteraction.hiddenMedia.contains(item.story.id)
            itemLayer.isHidden = itemHidden
            
            if let blurLayer = itemValue.blurLayer {
                let transition = Transition.immediate
                if itemHidden {
                    transition.setAlpha(layer: blurLayer, alpha: 0.0)
                } else {
                    transition.setAlpha(layer: blurLayer, alpha: 1.0)
                }
            }
        }
    }
    
    private func presentDeleteConfirmation(ids: Set<Int32>) {
        guard let peerId = self.peerId else {
            return
        }
        
        let presentationData = self.presentationData
        let controller = ActionSheetController(presentationData: presentationData)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        
        let title: String = presentationData.strings.StoryList_DeleteConfirmation_Title(Int32(ids.count))
        
        controller.setItemGroups([
            ActionSheetItemGroup(items: [
                ActionSheetTextItem(title: title),
                ActionSheetButtonItem(title: presentationData.strings.StoryList_DeleteConfirmation_Action, color: .destructive, action: { [weak self] in
                    dismissAction()
                    
                    guard let self else {
                        return
                    }
                    
                    if let parentController = self.parentController as? PeerInfoScreen {
                        parentController.cancelItemSelection()
                    }
                    
                    let _ = self.context.engine.messages.deleteStories(peerId: peerId, ids: Array(ids)).startStandalone()
                })
            ]),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
        ])
        self.parentController?.present(controller, in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }
    
    public func update(size: CGSize, topInset: CGFloat, sideInset: CGFloat, bottomInset: CGFloat, deviceMetrics: DeviceMetrics, visibleHeight: CGFloat, isScrollingLockedAtTop: Bool, expandProgress: CGFloat, navigationHeight: CGFloat, presentationData: PresentationData, synchronous: Bool, transition: ContainedViewLayoutTransition) {
        self.currentParams = (size, topInset, sideInset, bottomInset, deviceMetrics, visibleHeight, isScrollingLockedAtTop, expandProgress, navigationHeight, presentationData)
        
        var bottomInset = bottomInset
        if self.isProfileEmbedded, let selectedIds = self.itemInteraction.selectedIds, self.canManageStories, let peerId = self.peerId {
            let selectionPanel: ComponentView<Empty>
            var selectionPanelTransition = Transition(transition)
            if let current = self.selectionPanel {
                selectionPanel = current
            } else {
                selectionPanelTransition = selectionPanelTransition.withAnimation(.none)
                selectionPanel = ComponentView()
                self.selectionPanel = selectionPanel
            }
            
            var selectionItems: [BottomActionsPanelComponent.Item] = []
            
            let actionIsPin = !selectedIds.contains(where: { self.pinnedIds.contains($0) })
            selectionItems.append(BottomActionsPanelComponent.Item(
                id: "pin-unpin",
                color: .accent,
                title: actionIsPin ? presentationData.strings.StoryList_ActionPanel_Pin : presentationData.strings.StoryList_ActionPanel_Unpin,
                isEnabled: !selectedIds.isEmpty,
                action: { [weak self] in
                    guard let self, let selectedIds = self.itemInteraction.selectedIds else {
                        return
                    }
                    if !selectedIds.contains(where: { self.pinnedIds.contains($0) }) {
                        var updatedPinnedIds = self.pinnedIds
                        for id in selectedIds {
                            updatedPinnedIds.insert(id)
                        }
                        if updatedPinnedIds.count > 3 {
                            let presentationData = self.presentationData
                            let animationBackgroundColor = presentationData.theme.rootController.tabBar.backgroundColor
                            let toastText = presentationData.strings.StoryList_ToastPinLimit_Text(3)
                            self.parentController?.present(UndoOverlayController(presentationData: presentationData, content: .universal(animation: "anim_infotip", scale: 1.0, colors: ["info1.info1.stroke": animationBackgroundColor, "info2.info2.Fill": animationBackgroundColor], title: nil, text: toastText, customUndoText: nil, timeout: 5), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
                        } else {
                            let _ = self.context.engine.messages.updatePinnedToTopStories(peerId: peerId, ids: Array(updatedPinnedIds)).startStandalone()
                            
                            let presentationData = self.presentationData
                            
                            let toastTitle = presentationData.strings.StoryList_ToastPinned_Title(Int32(selectedIds.count))
                            let toastText = presentationData.strings.StoryList_ToastPinned_Text(Int32(selectedIds.count))
                            
                            self.parentController?.present(UndoOverlayController(presentationData: presentationData, content: .universal(animation: "anim_toastpin", scale: 0.06, colors: [:], title: toastTitle, text: toastText, customUndoText: nil, timeout: 5), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
                            
                            if let parentController = self.parentController as? PeerInfoScreen {
                                parentController.cancelItemSelection()
                            }
                        }
                    } else {
                        var updatedPinnedIds = self.pinnedIds
                        for id in selectedIds {
                            updatedPinnedIds.remove(id)
                        }
                        let _ = self.context.engine.messages.updatePinnedToTopStories(peerId: peerId, ids: Array(updatedPinnedIds)).startStandalone()
                        
                        let presentationData = self.presentationData
                        
                        let toastTitle: String? = nil
                        let toastText: String = presentationData.strings.StoryList_ToastUnpinned_Text(Int32(selectedIds.count))
                        
                        self.parentController?.present(UndoOverlayController(presentationData: presentationData, content: .universal(animation: "anim_toastunpin", scale: 0.06, colors: [:], title: toastTitle, text: toastText, customUndoText: nil, timeout: 5), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
                        
                        if let parentController = self.parentController as? PeerInfoScreen {
                            parentController.cancelItemSelection()
                        }
                    }
                }
            ))
            selectionItems.append(BottomActionsPanelComponent.Item(
                id: "archive",
                color: .accent,
                title: self.isArchive ? presentationData.strings.StoryList_ActionPanel_Unarchive : presentationData.strings.StoryList_ActionPanel_Archive,
                isEnabled: !selectedIds.isEmpty,
                action: { [weak self] in
                    guard let self, let _ = self.itemInteraction.selectedIds else {
                        return
                    }
                    
                    let items: [Int32: EngineStoryItem] = self.selectedItems
                    
                    if let parentController = self.parentController as? PeerInfoScreen {
                        parentController.cancelItemSelection()
                    }
                    
                    let _ = self.context.engine.messages.updateStoriesArePinned(peerId: peerId, ids: items, isPinned: self.isArchive ? true : false).startStandalone()
                    
                    let text: String
                    if self.isArchive {
                        text = presentationData.strings.StoryList_ToastUnarchived_Text(Int32(items.count))
                    } else {
                        text = presentationData.strings.StoryList_ToastArchived_Text(Int32(items.count))
                    }
                    self.parentController?.present(UndoOverlayController(presentationData: presentationData, content: .actionSucceeded(title: nil, text: text, cancel: nil, destructive: false), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
                }
            ))
            selectionItems.append(BottomActionsPanelComponent.Item(
                id: "delete",
                color: .destructive,
                title: presentationData.strings.StoryList_ActionPanel_Delete,
                isEnabled: !selectedIds.isEmpty,
                action: { [weak self] in
                    guard let self, let selectedIds = self.itemInteraction.selectedIds else {
                        return
                    }
                    
                    self.presentDeleteConfirmation(ids: selectedIds)
                }
            ))
            
            let selectionPanelSize = selectionPanel.update(
                transition: selectionPanelTransition,
                component: AnyComponent(BottomActionsPanelComponent(
                    theme: presentationData.theme,
                    insets: UIEdgeInsets(top: 0.0, left: sideInset, bottom: bottomInset, right: sideInset),
                    items: selectionItems
                )),
                environment: {},
                containerSize: size
            )
            let selectionPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: size.height - selectionPanelSize.height), size: selectionPanelSize)
            if let selectionPanelView = selectionPanel.view {
                if selectionPanelView.superview == nil {
                    self.view.addSubview(selectionPanelView)
                    transition.animatePositionAdditive(layer: selectionPanelView.layer, offset: CGPoint(x: 0.0, y: selectionPanelFrame.height))
                }
                selectionPanelTransition.setFrame(view: selectionPanelView, frame: selectionPanelFrame)
            }
            bottomInset = selectionPanelSize.height
        } else if let selectionPanel = self.selectionPanel {
            self.selectionPanel = nil
            if let selectionPanelView = selectionPanel.view {
                transition.updateFrame(view: selectionPanelView, frame: CGRect(origin: CGPoint(x: 0.0, y: size.height), size: selectionPanelView.bounds.size))
            }
        }

        transition.updateFrame(node: self.contextGestureContainerNode, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: size.width, height: size.height)))
        
        if let items = self.items, items.items.isEmpty, items.count == 0 {
            let emptyStateView: ComponentView<Empty>
            var emptyStateTransition = Transition(transition)
            if let current = self.emptyStateView {
                emptyStateView = current
            } else {
                emptyStateTransition = .immediate
                emptyStateView = ComponentView()
                self.emptyStateView = emptyStateView
            }
            let emptyStateSize = emptyStateView.update(
                transition: emptyStateTransition,
                component: AnyComponent(EmptyStateIndicatorComponent(
                    context: self.context,
                    theme: presentationData.theme,
                    fitToHeight: self.isProfileEmbedded,
                    animationName: "StoryListEmpty",
                    title: self.isArchive ? presentationData.strings.StoryList_ArchivedEmptyState_Title : presentationData.strings.StoryList_SavedEmptyPosts_Title,
                    text: self.isArchive ? presentationData.strings.StoryList_ArchivedEmptyState_Text : presentationData.strings.StoryList_SavedEmptyPosts_Text,
                    actionTitle: self.isArchive ? nil : presentationData.strings.StoryList_SavedAddAction,
                    action: { [weak self] in
                        guard let self else {
                            return
                        }
                        self.emptyAction?()
                    },
                    additionalActionTitle: (self.isArchive || self.isProfileEmbedded) ? nil : presentationData.strings.StoryList_SavedEmptyAction,
                    additionalAction: { [weak self] in
                        guard let self else {
                            return
                        }
                        self.additionalEmptyAction?()
                    }
                )),
                environment: {},
                containerSize: CGSize(width: size.width, height: size.height - topInset - bottomInset)
            )
            
            let emptyStateFrame: CGRect
            if self.isProfileEmbedded {
                emptyStateFrame = CGRect(origin: CGPoint(x: floor((size.width - emptyStateSize.width) * 0.5), y: max(topInset, floor((visibleHeight - topInset - bottomInset - emptyStateSize.height) * 0.5))), size: emptyStateSize)
            } else {
                emptyStateFrame = CGRect(origin: CGPoint(x: floor((size.width - emptyStateSize.width) * 0.5), y: topInset), size: emptyStateSize)
            }
            
            if let emptyStateComponentView = emptyStateView.view {
                if emptyStateComponentView.superview == nil {
                    self.view.addSubview(emptyStateComponentView)
                    if self.didUpdateItemsOnce {
                        emptyStateComponentView.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                    }
                }
                emptyStateTransition.setFrame(view: emptyStateComponentView, frame: emptyStateFrame)
            }
            
            let backgroundColor: UIColor
            if self.isProfileEmbedded {
                backgroundColor = presentationData.theme.list.plainBackgroundColor
            } else {
                backgroundColor = presentationData.theme.list.blocksBackgroundColor
            }
            
            if self.didUpdateItemsOnce {
                Transition(animation: .curve(duration: 0.2, curve: .easeInOut)).setBackgroundColor(view: self.view, color: backgroundColor)
            } else {
                self.view.backgroundColor = backgroundColor
            }
        } else {
            if let emptyStateView = self.emptyStateView {
                let subTransition = Transition(animation: .curve(duration: 0.2, curve: .easeInOut))
                self.emptyStateView = nil
                
                if let emptyStateComponentView = emptyStateView.view {
                    subTransition.setAlpha(view: emptyStateComponentView, alpha: 0.0, completion: { [weak emptyStateComponentView] _ in
                        emptyStateComponentView?.removeFromSuperview()
                    })
                }
                
                if self.isProfileEmbedded {
                    subTransition.setBackgroundColor(view: self.view, color: presentationData.theme.list.plainBackgroundColor)
                } else {
                    subTransition.setBackgroundColor(view: self.view, color: presentationData.theme.list.blocksBackgroundColor)
                }
            } else {
                self.view.backgroundColor = .clear
            }
        }

        transition.updateFrame(node: self.itemGrid, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: size.width, height: size.height)))
        if let items = self.items {
            let wasFirstTime = !self.didUpdateItemsOnce
            self.didUpdateItemsOnce = true
            let fixedItemHeight: CGFloat?
            let isList = false
            switch self.contentType {
            default:
                fixedItemHeight = nil
            }
            
            let fixedItemAspect: CGFloat? = 0.81
            
            let gridTopInset = topInset
         
            self.itemGrid.pinchEnabled = items.count > 2
            self.itemGrid.update(size: size, insets: UIEdgeInsets(top: gridTopInset, left: sideInset, bottom:  bottomInset, right: sideInset), useSideInsets: !isList, scrollIndicatorInsets: UIEdgeInsets(top: 0.0, left: sideInset, bottom: bottomInset, right: sideInset), lockScrollingAtTop: isScrollingLockedAtTop, fixedItemHeight: fixedItemHeight, fixedItemAspect: fixedItemAspect, items: items, theme: self.itemGridBinding.chatPresentationData.theme.theme, synchronous: wasFirstTime ? .full : .none)
        }
    }

    public func currentTopTimestamp() -> Int32? {
        var timestamp: Int32?
        self.itemGrid.forEachVisibleItem { item in
            guard let itemLayer = item.layer as? ItemLayer else {
                return
            }
            if let item = itemLayer.item {
                if let timestampValue = timestamp {
                    timestamp = max(timestampValue, item.story.timestamp)
                } else {
                    timestamp = item.story.timestamp
                }
            }
        }
        return timestamp
    }

    public func scrollToTimestamp(timestamp: Int32) {
        if let items = self.items, !items.items.isEmpty {
            var previousIndex: Int?
            for item in items.items {
                guard let item = item as? VisualMediaItem else {
                    continue
                }
                if item.story.timestamp <= timestamp {
                    break
                }
                previousIndex = item.index
            }
            if previousIndex == nil {
                previousIndex = (items.items[0] as? VisualMediaItem)?.index
            }
            if let index = previousIndex {
                self.itemGrid.scrollToItem(at: index)

                if let item = self.itemGrid.item(at: index) {
                    if let layer = item.layer as? ItemLayer {
                        Queue.mainQueue().after(0.1, { [weak layer] in
                            guard let layer = layer else {
                                return
                            }

                            let overlayLayer = SimpleLayer()
                            overlayLayer.backgroundColor = UIColor(white: 1.0, alpha: 0.6).cgColor
                            overlayLayer.frame = layer.bounds
                            layer.addSublayer(overlayLayer)
                            overlayLayer.animateAlpha(from: 1.0, to: 0.0, duration: 0.8, delay: 0.3, removeOnCompletion: false, completion: { [weak overlayLayer] _ in
                                overlayLayer?.removeFromSuperlayer()
                            })
                        })
                    }
                }
            }
        }
    }

    public func scrollToItem(index: Int) {
        guard let _ = self.items else {
            return
        }
        self.itemGrid.scrollToItem(at: index)
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let result = super.hitTest(point, with: event) else {
            return nil
        }
        /*if self.decelerationAnimator != nil {
            self.decelerationAnimator?.isPaused = true
            self.decelerationAnimator = nil
            
            return self.scrollNode.view
        }*/
        return result
    }

    public func availableZoomLevels() -> (decrement: ZoomLevel?, increment: ZoomLevel?) {
        let levels = self.itemGrid.availableZoomLevels()
        return (levels.decrement.flatMap(ZoomLevel.init), levels.increment.flatMap(ZoomLevel.init))
    }
}

private class MediaListSelectionRecognizer: UIPanGestureRecognizer {
    private let selectionGestureActivationThreshold: CGFloat = 5.0
    
    var recognized: Bool? = nil
    var initialLocation: CGPoint = CGPoint()
    
    public var shouldBegin: (() -> Bool)?
    
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        self.minimumNumberOfTouches = 2
        self.maximumNumberOfTouches = 2
    }
    
    public override func reset() {
        super.reset()
        
        self.recognized = nil
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        if let shouldBegin = self.shouldBegin, !shouldBegin() {
            self.state = .failed
        } else {
            let touch = touches.first!
            self.initialLocation = touch.location(in: self.view)
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        let location = touches.first!.location(in: self.view)
        let translation = location.offsetBy(dx: -self.initialLocation.x, dy: -self.initialLocation.y)
        
        let touchesArray = Array(touches)
        if self.recognized == nil, touchesArray.count == 2 {
            if let firstTouch = touchesArray.first, let secondTouch = touchesArray.last {
                let firstLocation = firstTouch.location(in: self.view)
                let secondLocation = secondTouch.location(in: self.view)
                
                func distance(_ v1: CGPoint, _ v2: CGPoint) -> CGFloat {
                    let dx = v1.x - v2.x
                    let dy = v1.y - v2.y
                    return sqrt(dx * dx + dy * dy)
                }
                if distance(firstLocation, secondLocation) > 200.0 {
                    self.state = .failed
                }
            }
            if self.state != .failed && (abs(translation.y) >= selectionGestureActivationThreshold) {
                self.recognized = true
            }
        }
        
        if let recognized = self.recognized, recognized {
            super.touchesMoved(touches, with: event)
        }
    }
}

private final class TempExtractedItemNode: ASDisplayNode {
    let contextSourceNode: ContextExtractedContentContainingNode
    let item: EngineStoryItem
    weak var itemLayer: ItemLayer?
    let itemView: ItemTransitionView
    
    init(item: EngineStoryItem, itemLayer: ItemLayer) {
        self.item = item
        self.contextSourceNode = ContextExtractedContentContainingNode()
        self.itemView = ItemTransitionView(itemLayer: itemLayer)
        self.itemLayer = itemLayer
        
        super.init()
        
        self.addSubnode(self.contextSourceNode)
        
        self.contextSourceNode.contentNode.view.addSubview(self.itemView)
        self.itemView.clipsToBounds = true
        
        self.contextSourceNode.willUpdateIsExtractedToContextPreview = { [weak self] isExtracted, transition in
            guard let self else {
                return
            }
            
            transition.updateCornerRadius(layer: self.itemView.layer, cornerRadius: isExtracted ? 10.0 : 0.0)
            
            if isExtracted {
                transition.updateSublayerTransformScale(node: self.contextSourceNode.contentNode, scale: 1.0)
            }
        }
        
        self.contextSourceNode.isExtractedToContextPreviewUpdated = { [weak self] isExtracted in
            guard let self else {
                return
            }
            
            self.itemLayer?.isHidden = isExtracted
            
            if !isExtracted {
                self.removeFromSupernode()
            }
        }
    }
    
    func update(size: CGSize) {
        self.contextSourceNode.frame = CGRect(origin: CGPoint(), size: size)
        self.contextSourceNode.contentNode.frame = CGRect(origin: CGPoint(), size: size)
        self.contextSourceNode.contentRect = CGRect(origin: CGPoint(x: 2.0, y: 0.0), size: CGSize(width: size.width - 4.0, height: size.height))
        
        self.itemView.frame = CGRect(origin: CGPoint(), size: size)
        self.itemView.update(state: StoryContainerScreen.TransitionState(sourceSize: size, destinationSize: size, progress: 0.0), transition: .immediate)
    }
}

private final class ExtractedContentSourceImpl: ContextExtractedContentSource {
    var keepInPlace: Bool
    let ignoreContentTouches: Bool = true
    let blurBackground: Bool
    let adjustContentForSideInset: Bool = true
    
    private let controller: ViewController
    private let sourceNode: ContextExtractedContentContainingNode
    
    var actionsHorizontalAlignment: ContextActionsHorizontalAlignment {
        return .center
    }
    
    init(controller: ViewController, sourceNode: ContextExtractedContentContainingNode, keepInPlace: Bool, blurBackground: Bool) {
        self.controller = controller
        self.sourceNode = sourceNode
        self.keepInPlace = keepInPlace
        self.blurBackground = blurBackground
    }
    
    func takeView() -> ContextControllerTakeViewInfo? {
        return ContextControllerTakeViewInfo(containingItem: .node(self.sourceNode), contentAreaInScreenSpace: UIScreen.main.bounds)
    }
    
    func putBack() -> ContextControllerPutBackViewInfo? {
        return ContextControllerPutBackViewInfo(contentAreaInScreenSpace: UIScreen.main.bounds)
    }
}

private final class BottomActionsPanelComponent: Component {
    public final class Item: Equatable {
        public enum Color {
            case accent
            case destructive
        }
        
        public var id: AnyHashable
        public var color: Color
        public var title: String
        public var isEnabled: Bool
        public var action: () -> Void
        
        public init(id: AnyHashable, color: Color, title: String, isEnabled: Bool, action: @escaping () -> Void) {
            self.id = id
            self.color = color
            self.title = title
            self.isEnabled = isEnabled
            self.action = action
        }
        
        public static func ==(lhs: Item, rhs: Item) -> Bool {
            if lhs === rhs {
                return true
            }
            if lhs.id != rhs.id {
                return false
            }
            if lhs.color != rhs.color {
                return false
            }
            if lhs.title != rhs.title {
                return false
            }
            if lhs.isEnabled != rhs.isEnabled {
                return false
            }
            return true
        }
    }
    
    public let theme: PresentationTheme
    public let insets: UIEdgeInsets
    public let items: [Item]
    
    public init(
        theme: PresentationTheme,
        insets: UIEdgeInsets,
        items: [Item]
    ) {
        self.theme = theme
        self.insets = insets
        self.items = items
    }
    
    public static func ==(lhs: BottomActionsPanelComponent, rhs: BottomActionsPanelComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.insets != rhs.insets {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        return true
    }
    
    public final class View: UIView {
        private let backgroundView: BlurredBackgroundView
        private let separatorLayer: SimpleLayer
        
        private var itemViews: [AnyHashable: ComponentView<Empty>] = [:]
        
        private var component: BottomActionsPanelComponent?
        
        public override init(frame: CGRect) {
            self.backgroundView = BlurredBackgroundView(color: nil, enableBlur: true)
            self.backgroundView.isUserInteractionEnabled = false
            
            self.separatorLayer = SimpleLayer()
            
            super.init(frame: frame)
            
            self.addSubview(self.backgroundView)
            self.layer.addSublayer(self.separatorLayer)
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
        func update(component: BottomActionsPanelComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let themeUpdated = self.component?.theme !== component.theme
            
            self.component = component
            
            if themeUpdated {
                self.backgroundView.updateColor(color: component.theme.rootController.navigationBar.blurredBackgroundColor, transition: .immediate)
                self.separatorLayer.backgroundColor = component.theme.rootController.navigationBar.separatorColor.cgColor
            }
            
            let itemHeight: CGFloat = 54.0
            let size = CGSize(width: availableSize.width, height: itemHeight + component.insets.bottom)
            
            transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(), size: size))
            self.backgroundView.update(size: size, transition: transition.containedViewLayoutTransition)
            transition.setFrame(layer: self.separatorLayer, frame: CGRect(origin: CGPoint(x: 0.0, y: -UIScreenPixel), size: CGSize(width: size.width, height: UIScreenPixel)))
            
            let sideInset = component.insets.left + 12.0
            
            var validIds: [AnyHashable] = []
            var itemsAndSizes: [(CGSize, ComponentView<Empty>)] = []
            for item in component.items {
                validIds.append(item.id)
                
                let itemColor: UIColor
                if item.isEnabled {
                    switch item.color {
                    case .accent:
                        itemColor = component.theme.list.itemAccentColor
                    case .destructive:
                        itemColor = component.theme.list.itemDestructiveColor
                    }
                } else {
                    itemColor = component.theme.list.itemDisabledTextColor
                }
                
                let itemView: ComponentView<Empty>
                if let current = self.itemViews[item.id] {
                    itemView = current
                } else {
                    itemView = ComponentView()
                    self.itemViews[item.id] = itemView
                }
                let itemSize = itemView.update(
                    transition: .immediate,
                    component: AnyComponent(PlainButtonComponent(
                        content: AnyComponent(Text(text: item.title, font: Font.regular(17.0), color: itemColor)),
                        effectAlignment: .center,
                        minSize: CGSize(width: 16.0, height: itemHeight),
                        contentInsets: UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0),
                        action: {
                            item.action()
                        },
                        isEnabled: item.isEnabled,
                        animateAlpha: true,
                        animateScale: false,
                        animateContents: false
                    )),
                    environment: {},
                    containerSize: CGSize(width: availableSize.width, height: itemHeight)
                )
                itemsAndSizes.append((itemSize, itemView))
            }
            var removedIds: [AnyHashable] = []
            for (id, itemView) in self.itemViews {
                if !validIds.contains(id) {
                    removedIds.append(id)
                    itemView.view?.removeFromSuperview()
                }
            }
            for id in removedIds {
                self.itemViews.removeValue(forKey: id)
            }
            
            for i in 0 ..< itemsAndSizes.count {
                let (itemSize, itemView) = itemsAndSizes[i]
                
                let itemCenterX: CGFloat = CGFloat(i) * (floor((availableSize.width - sideInset * 2.0) / CGFloat(itemsAndSizes.count - 1)))
                let itemX: CGFloat
                if i == 0 {
                    itemX = sideInset
                } else if i == itemsAndSizes.count - 1 {
                    itemX = availableSize.width - sideInset - itemSize.width
                } else {
                    itemX = sideInset + floor(itemCenterX - itemSize.width * 0.5)
                }
                
                let itemFrame = CGRect(origin: CGPoint(x: itemX, y: 0.0), size: itemSize)
                
                if let itemComponenView = itemView.view {
                    if itemComponenView.superview == nil {
                        self.addSubview(itemComponenView)
                    }
                    itemComponenView.frame = itemFrame
                }
            }
            
            return size
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

