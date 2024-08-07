import Foundation
import UIKit
import Display
import ComponentFlow
import PlainButtonComponent

public final class TabSelectorComponent: Component {
    public struct Colors: Equatable {
        public var foreground: UIColor
        public var selection: UIColor

        public init(
            foreground: UIColor,
            selection: UIColor
        ) {
            self.foreground = foreground
            self.selection = selection
        }
    }
    
    public struct CustomLayout: Equatable {
        public var font: UIFont
        public var spacing: CGFloat
        public var lineSelection: Bool
        
        public init(font: UIFont, spacing: CGFloat, lineSelection: Bool = false) {
            self.font = font
            self.spacing = spacing
            self.lineSelection = lineSelection
        }
    }
    
    public struct Item: Equatable {
        public var id: AnyHashable
        public var title: String

        public init(
            id: AnyHashable,
            title: String
        ) {
            self.id = id
            self.title = title
        }
    }

    public let colors: Colors
    public let customLayout: CustomLayout?
    public let items: [Item]
    public let selectedId: AnyHashable?
    public let setSelectedId: (AnyHashable) -> Void
    public let transitionFraction: CGFloat?
    
    public init(
        colors: Colors,
        customLayout: CustomLayout? = nil,
        items: [Item],
        selectedId: AnyHashable?,
        setSelectedId: @escaping (AnyHashable) -> Void,
        transitionFraction: CGFloat? = nil
    ) {
        self.colors = colors
        self.customLayout = customLayout
        self.items = items
        self.selectedId = selectedId
        self.setSelectedId = setSelectedId
        self.transitionFraction = transitionFraction
    }
    
    public static func ==(lhs: TabSelectorComponent, rhs: TabSelectorComponent) -> Bool {
        if lhs.colors != rhs.colors {
            return false
        }
        if lhs.customLayout != rhs.customLayout {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        if lhs.selectedId != rhs.selectedId {
            return false
        }
        if lhs.transitionFraction != rhs.transitionFraction {
            return false
        }
        return true
    }
    
    private final class VisibleItem {
        let title = ComponentView<Empty>()
        
        init() {
        }
    }
    
    public final class View: UIView {
        private var component: TabSelectorComponent?
        private weak var state: EmptyComponentState?
        
        private let selectionView: UIImageView
        private var visibleItems: [AnyHashable: VisibleItem] = [:]
        
        override init(frame: CGRect) {
            self.selectionView = UIImageView()
            
            super.init(frame: frame)
            
            self.addSubview(self.selectionView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
        }
        
        func update(component: TabSelectorComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let selectionColorUpdated = component.colors.selection != self.component?.colors.selection
           
            self.component = component
            self.state = state
            
            let baseHeight: CGFloat = 28.0
            let innerInset: CGFloat = 12.0
            let spacing: CGFloat = component.customLayout?.spacing ?? 2.0
            
            let itemFont: UIFont
            var isLineSelection = false
            if let customLayout = component.customLayout {
                itemFont = customLayout.font
                isLineSelection = customLayout.lineSelection
            } else {
                itemFont = Font.semibold(14.0)
            }
            
            if selectionColorUpdated {
                if isLineSelection {
                    self.selectionView.image = generateImage(CGSize(width: 5.0, height: 3.0), rotatedContext: { size, context in
                        context.clear(CGRect(origin: CGPoint(), size: size))
                        context.setFillColor(component.colors.selection.cgColor)
                        context.fillEllipse(in: CGRect(origin: CGPoint(), size: CGSize(width: 4.0, height: 4.0)))
                        context.fillEllipse(in: CGRect(origin: CGPoint(x: size.width - 4.0, y: 0.0), size: CGSize(width: 4.0, height: 4.0)))
                        context.fill(CGRect(x: 2.0, y: 0.0, width: size.width - 4.0, height: 4.0))
                        context.fill(CGRect(x: 0.0, y: 2.0, width: size.width, height: 2.0))
                    })?.resizableImage(withCapInsets: UIEdgeInsets(top: 3.0, left: 3.0, bottom: 0.0, right: 3.0), resizingMode: .stretch)
                } else {
                    self.selectionView.image = generateStretchableFilledCircleImage(diameter: baseHeight, color: component.colors.selection)
                }
            }
            
            var contentWidth: CGFloat = 0.0
            var previousBackgroundRect: CGRect?
            var selectedBackgroundRect: CGRect?
            var nextBackgroundRect: CGRect?
            
            let selectedIndex = component.items.firstIndex(where: { $0.id == component.selectedId })
            
            var validIds: [AnyHashable] = []
            var index = 0
            for item in component.items {
                var itemTransition = transition
                let itemView: VisibleItem
                if let current = self.visibleItems[item.id] {
                    itemView = current
                } else {
                    itemView = VisibleItem()
                    self.visibleItems[item.id] = itemView
                    itemTransition = itemTransition.withAnimation(.none)
                }
                
                let itemId = item.id
                validIds.append(itemId)
                
                var selectionFraction: CGFloat = 0.0
                if let transitionFraction = component.transitionFraction, let selectedIndex {
                    if item.id == component.selectedId {
                        selectionFraction = 1.0 - abs(transitionFraction)
                    } else {
                        if index == selectedIndex - 1 && transitionFraction < 0.0 {
                            selectionFraction = abs(transitionFraction)
                        } else if index == selectedIndex + 1 && transitionFraction > 0.0 {
                            selectionFraction = abs(transitionFraction)
                        }
                    }
                } else {
                    selectionFraction = item.id == component.selectedId ? 1.0 : 0.0
                }
                
                let itemSize = itemView.title.update(
                    transition: .immediate,
                    component: AnyComponent(PlainButtonComponent(
                        content: AnyComponent(ItemComponent(
                            text: item.title,
                            font: itemFont,
                            color: component.colors.foreground,
                            selectedColor: component.colors.selection,
                            selectionFraction: isLineSelection ? selectionFraction : 0.0
                        )),
                        effectAlignment: .center,
                        minSize: nil,
                        action: { [weak self] in
                            guard let self, let component = self.component else {
                                return
                            }
                            component.setSelectedId(itemId)
                        },
                        animateScale: !isLineSelection
                    )),
                    environment: {},
                    containerSize: CGSize(width: 200.0, height: 100.0)
                )
                
                if !contentWidth.isZero {
                    contentWidth += spacing
                }
                let itemTitleFrame = CGRect(origin: CGPoint(x: contentWidth + innerInset, y: floor((baseHeight - itemSize.height) * 0.5)), size: itemSize)
                let itemBackgroundRect = CGRect(origin: CGPoint(x: contentWidth, y: 0.0), size: CGSize(width: innerInset + itemSize.width + innerInset, height: baseHeight))
                contentWidth = itemBackgroundRect.maxX
                
                if item.id == component.selectedId {
                    selectedBackgroundRect = itemBackgroundRect
                }
                if selectedBackgroundRect == nil {
                    previousBackgroundRect = itemBackgroundRect
                } else if nextBackgroundRect == nil, itemBackgroundRect != selectedBackgroundRect {
                    nextBackgroundRect = itemBackgroundRect
                }
                
                if let itemTitleView = itemView.title.view {
                    if itemTitleView.superview == nil {
                        itemTitleView.layer.anchorPoint = CGPoint()
                        self.addSubview(itemTitleView)
                    }
                    itemTransition.setPosition(view: itemTitleView, position: itemTitleFrame.origin)
                    itemTransition.setBounds(view: itemTitleView, bounds: CGRect(origin: CGPoint(), size: itemTitleFrame.size))
                    itemTransition.setAlpha(view: itemTitleView, alpha: item.id == component.selectedId || isLineSelection ? 1.0 : 0.4)
                }
                index += 1
            }
            
            var removeIds: [AnyHashable] = []
            for (id, itemView) in self.visibleItems {
                if !validIds.contains(id) {
                    removeIds.append(id)
                    itemView.title.view?.removeFromSuperview()
                }
            }
            for id in removeIds {
                self.visibleItems.removeValue(forKey: id)
            }
            
            if let selectedBackgroundRect {
                self.selectionView.alpha = 1.0
                                
                if isLineSelection {
                    var effectiveBackgroundRect = selectedBackgroundRect
                    if let transitionFraction = component.transitionFraction {
                        if transitionFraction < 0.0 {
                            if let previousBackgroundRect {
                                effectiveBackgroundRect = effectiveBackgroundRect.interpolate(with: previousBackgroundRect, fraction: abs(transitionFraction))
                            }
                        } else if transitionFraction > 0.0 {
                            if let nextBackgroundRect {
                                effectiveBackgroundRect = effectiveBackgroundRect.interpolate(with: nextBackgroundRect, fraction: abs(transitionFraction))
                            }
                        }
                    }
                    
                    var mappedSelectionFrame = effectiveBackgroundRect.insetBy(dx: 12.0, dy: 0.0)
                    mappedSelectionFrame.origin.y = mappedSelectionFrame.maxY + 6.0
                    mappedSelectionFrame.size.height = 3.0
                    transition.setFrame(view: self.selectionView, frame: mappedSelectionFrame)
                } else {
                    transition.setFrame(view: self.selectionView, frame: selectedBackgroundRect)
                }
            } else {
                self.selectionView.alpha = 0.0
            }
            
            return CGSize(width: contentWidth, height: baseHeight)
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

extension CGRect {
    func interpolate(with other: CGRect, fraction: CGFloat) -> CGRect {
         return CGRect(
            x: self.origin.x * (1.0 - fraction) + (other.origin.x) * fraction,
            y: self.origin.y * (1.0 - fraction) + (other.origin.y) * fraction,
            width: self.size.width * (1.0 - fraction) + (other.size.width) * fraction,
            height: self.size.height * (1.0 - fraction) + (other.size.height) * fraction
         )
     }
}

private final class ItemComponent: CombinedComponent {
    let text: String
    let font: UIFont
    let color: UIColor
    let selectedColor: UIColor
    let selectionFraction: CGFloat
    
    init(
        text: String,
        font: UIFont,
        color: UIColor,
        selectedColor: UIColor,
        selectionFraction: CGFloat
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.selectedColor = selectedColor
        self.selectionFraction = selectionFraction
    }

    static func ==(lhs: ItemComponent, rhs: ItemComponent) -> Bool {
        if lhs.text != rhs.text {
            return false
        }
        if lhs.font != rhs.font {
            return false
        }
        if lhs.color != rhs.color {
            return false
        }
        if lhs.selectedColor != rhs.selectedColor {
            return false
        }
        if lhs.selectionFraction != rhs.selectionFraction {
            return false
        }
        return true
    }
    
    static var body: Body {
        let title = Child(Text.self)
        let selectedTitle = Child(Text.self)
        
        return { context in
            let component = context.component
           
            let title = title.update(
                component: Text(
                    text: component.text,
                    font: component.font,
                    color: component.color
                ),
                availableSize: context.availableSize,
                transition: .immediate
            )
            context.add(title
                .position(CGPoint(x: title.size.width / 2.0, y: title.size.height / 2.0))
                .opacity(1.0 - component.selectionFraction)
            )
            
            let selectedTitle = selectedTitle.update(
                component: Text(
                    text: component.text,
                    font: component.font,
                    color: component.selectedColor
                ),
                availableSize: context.availableSize,
                transition: .immediate
            )
            context.add(selectedTitle
                .position(CGPoint(x: selectedTitle.size.width / 2.0, y: selectedTitle.size.height / 2.0))
                .opacity(component.selectionFraction)
            )
                        
            return title.size
        }
    }
}
