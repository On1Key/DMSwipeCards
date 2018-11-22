//
//  DMSwipeCardsView.swift
//  Pods
//
//  Created by Dylan Marriott on 18/12/16.
//
//

import Foundation
import UIKit

public enum SwipeMode {
    case left
    case right
}

public protocol DMSwipeCardsViewDelegate: class {
    func swipedLeft(_ object: Any)
    func swipedRight(_ object: Any)
    func cardTapped(_ object: Any)
    func reachedEndOfStack()
    ///左右滑动暂停代理,和continue闭包(闭包执行完毕，函数最终还会调用swipedLeft或者right代理),返回值为是否暂停操作
    func swipedLeftOrRightResume(_ object: Any,_ left:Bool,_ continueHandler:@escaping ((_ cancelSwipe:Bool) -> Void)) -> Bool
    //    func cardAutoSwipeAction(_ obj)
}

public class DMSwipeCardsView<Element>: UIView {
    
    public weak var delegate: DMSwipeCardsViewDelegate?
    public var bufferSize: Int = 2
    
    fileprivate let viewGenerator: ViewGenerator
    fileprivate let overlayGenerator: OverlayGenerator?
    fileprivate var allCards = [Element]()
    fileprivate var loadedCards = [DMSwipeCard]()
    
    //cardsview层级的左右滑动veiw
    fileprivate var leftV : UIView?
    fileprivate var rightV : UIView?
    fileprivate var leftOriX : CGFloat = 0
    fileprivate var rightOriX : CGFloat = UIScreen.main.bounds.size.width
    fileprivate var showSwipeView : Bool = false
    
    ///重置左右悬浮显示框的隐藏与否状态
    public func resetShowSwipeViewState(show:Bool){
        self.showSwipeView = show
        leftV?.isHidden = !show
        rightV?.isHidden = !show
        _ = self.loadedCards.map { (card) -> Void in
            card.resetShowSwipeState(show: !show)
        }
    }
    
    ///是否非手势自动滑动到下一张卡片
    public func autoSwipeToNextCard(left:Bool){
        loadedCards.first?.autoSwipeMoveToLRAction(left)
    }
    
    public typealias ViewGenerator = (_ element: Element, _ frame: CGRect) -> (UIView)
    public typealias OverlayGenerator = (_ mode: SwipeMode, _ frame: CGRect) -> (UIView)
    public init(frame: CGRect,
                viewGenerator: @escaping ViewGenerator,
                overlayGenerator: OverlayGenerator? = nil,showLRView:Bool = false) {
        self.overlayGenerator = overlayGenerator
        self.viewGenerator = viewGenerator
        self.showSwipeView = showLRView
        super.init(frame: frame)
        if (showSwipeView){
            
            var rect = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height-80);
            if let lv = self.overlayGenerator?(.left, rect) {
                addSubview(lv)
                bringSubview(toFront: lv)
                lv.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
                leftV = lv
                leftOriX = lv.frame.origin.x
            }
            if let rv = self.overlayGenerator?(.right, rect) {
                addSubview(rv)
                bringSubview(toFront: rv)
                rv.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
                rightV = rv
                rightOriX = rv.frame.origin.x
            }
        }
        self.isUserInteractionEnabled = false
    }
    
    override private init(frame: CGRect) {
        fatalError("Please use init(frame:,viewGenerator)")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Please use init(frame:,viewGenerator)")
    }
    
    public func addCards(_ elements: [Element], onTop: Bool = false) {
        if elements.isEmpty {
            return
        }
        
        self.isUserInteractionEnabled = true
        
        if onTop {
            for element in elements.reversed() {
                allCards.insert(element, at: 0)
            }
        } else {
            for element in elements {
                allCards.append(element)
            }
        }
        
        if onTop && loadedCards.count > 0 {
            for cv in loadedCards {
                cv.removeFromSuperview()
            }
            loadedCards.removeAll()
        }
        
        for element in elements {
            if loadedCards.count < bufferSize {
                let cardView = self.createCardView(element: element)
                if loadedCards.isEmpty {
                    self.addSubview(cardView)
                } else {
                    self.insertSubview(cardView, belowSubview: loadedCards.last!)
                }
                self.loadedCards.append(cardView)
            }
        }
        if let lv = leftV{
            bringSubview(toFront: lv)
        }
        if let rv = rightV{
            bringSubview(toFront: rv)
        }
    }
    
    func swipeTopCardRight() {
        // TODO: not yet supported
        fatalError("Not yet supported")
    }
    
    func swipeTopCardLeft() {
        // TODO: not yet supported
        fatalError("Not yet supported")
    }
}

extension DMSwipeCardsView: DMSwipeCardDelegate {
    func cardSwipedLeft(_ card: DMSwipeCard) {
        self.handleSwipedCard(card)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            self.delegate?.swipedLeft(card.obj)
            self.loadNextCard()
        }
    }
    
    func cardSwipedRight(_ card: DMSwipeCard) {
        self.handleSwipedCard(card)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            self.delegate?.swipedRight(card.obj)
            self.loadNextCard()
        }
    }
    
    func cardSwipedMoving(_ activeX : CGFloat,_ scale : CGFloat,_ left : Bool,_ finish:Bool){
        guard let lv = leftV else {return}
        guard let rv = rightV else {return}
        bringSubview(toFront: lv)
        bringSubview(toFront: rv)
        if finish{
            lv.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            rv.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            lv.frame = CGRect(x: leftOriX, y: lv.frame.origin.y, width: lv.frame.size.width, height: lv.frame.size.height)
            rv.frame = CGRect(x: rightOriX, y: rv.frame.origin.y, width: rv.frame.size.width, height: rv.frame.size.height)
            return
        }
        if left{
            UIView.animate(withDuration: 0.01) {
                lv.frame = CGRect(x: activeX, y: lv.frame.origin.y, width: lv.frame.size.width, height: lv.frame.size.height)
                lv.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }else{
            UIView.animate(withDuration: 0.01) {
                rv.frame = CGRect(x: activeX, y: rv.frame.origin.y, width: rv.frame.size.width, height: rv.frame.size.height)
                rv.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }
    
    func cardSwipeResume(_ card: DMSwipeCard, _ left: Bool, _ continueHandler: @escaping ((_ cancelSwipe:Bool) -> Void)) -> Bool {
        if let resume = self.delegate?.swipedLeftOrRightResume(card.obj, left, continueHandler){
            return resume
        }
        return false
    }
    
    func cardTapped(_ card: DMSwipeCard) {
        self.delegate?.cardTapped(card.obj)
    }
}

extension DMSwipeCardsView {
    fileprivate func handleSwipedCard(_ card: DMSwipeCard) {
        self.loadedCards.removeFirst()
        self.allCards.removeFirst()
        if self.allCards.isEmpty {
            self.isUserInteractionEnabled = false
            self.delegate?.reachedEndOfStack()
        }
    }
    
    fileprivate func loadNextCard() {
        if self.allCards.count - self.loadedCards.count > 0  && self.loadedCards.last != nil {
            let next = self.allCards[loadedCards.count]
            let nextView = self.createCardView(element: next)
            let below = self.loadedCards.last!
            self.loadedCards.append(nextView)
            self.insertSubview(nextView, belowSubview: below)
        }
    }
    
    fileprivate func createCardView(element: Element) -> DMSwipeCard {
        let cardView = DMSwipeCard(frame: self.bounds)
        cardView.showSwipeView = !showSwipeView//这里是否显示滑动view是取反，因为cardsview和card是不会同时显示的，二者显示逻辑相反
        cardView.delegate = self
        cardView.obj = element
        let sv = self.viewGenerator(element, cardView.bounds)
        cardView.addSubview(sv)
        cardView.leftOverlay = self.overlayGenerator?(.left, cardView.bounds)
        cardView.rightOverlay = self.overlayGenerator?(.right, cardView.bounds)
        cardView.configureOverlays()
        return cardView
    }
}
