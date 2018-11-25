//
//  DMSwipeCard.swift
//  Pods
//
//  Created by Dylan Marriott on 18/12/16.
//
//

import Foundation
import UIKit

protocol DMSwipeCardDelegate: class {
    func cardSwipedLeft(_ card: DMSwipeCard)
    func cardSwipedRight(_ card: DMSwipeCard)
    ///滑动过程的回调，用来处理外部足有模拟悬浮框的操作
    func cardSwipedMoving(_ activeX: CGFloat,_ scale : CGFloat,_ left: Bool,_ finish:Bool)
    ///滑动过程的暂停，返回值true进行resume操作，并由闭包进行后续的continue事件(闭包的的参数为取消滑动后续操作，默认不取消)
    func cardSwipeResume(_ card: DMSwipeCard,_ left : Bool,_ continueHandler:@escaping ((_ cancelSwipe:Bool) -> Void)) -> Bool
    func cardTapped(_ card: DMSwipeCard)
}

class DMSwipeCard: UIView {
    
    weak var delegate: DMSwipeCardDelegate?
    var obj: Any!
    var leftOverlay: UIView?
    var rightOverlay: UIView?
    var showSwipeView : Bool = true//显示滑动view，默认显示
    
    private let actionMargin: CGFloat = 120.0
    private let rotationStrength: CGFloat = UIScreen.main.bounds.width
    private let rotationAngle: CGFloat = CGFloat(Double.pi) / CGFloat(8.0)
    private let rotationMax: CGFloat = 1
    private let scaleStrength: CGFloat = -2
    private let scaleMax: CGFloat = 1.02
    
    private var xFromCenter: CGFloat = 0.0
    private var yFromCenter: CGFloat = 0.0
    private var originalPoint = CGPoint.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragEvent(gesture:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapEvent(gesture:)))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetShowSwipeState(show:Bool){
        self.showSwipeView = show
        self.leftOverlay?.isHidden = !self.showSwipeView
        self.rightOverlay?.isHidden = !self.showSwipeView
    }
    
    func configureOverlays() {
        resetShowSwipeState(show: self.showSwipeView)
        self.configureOverlay(overlay: self.leftOverlay)
        self.configureOverlay(overlay: self.rightOverlay)
    }
    
    private func configureOverlay(overlay: UIView?) {
        if let o = overlay {
            self.addSubview(o)
            o.alpha = 0.0
        }
    }
    ///自动撤回卡片到中心
    func autoSwipeMoveToCenterAction(_ left:Bool){
        var leftFlag : CGFloat = -1
        if left == false{
            leftFlag = 1
        }
        
        let ori = self.superview?.center ?? CGPoint.zero
        self.originalPoint = ori
        self.yFromCenter = 30
        let finishPoint = CGPoint(x: 500 * leftFlag, y: 2 * self.yFromCenter + self.originalPoint.y)
        self.xFromCenter = self.originalPoint.x * leftFlag
        self.center = finishPoint
        
        let rStrength = min(self.xFromCenter / self.rotationStrength, self.rotationMax)
        let rAngle = self.rotationAngle * rStrength
        let scale = min(1 - fabs(rStrength) / self.scaleStrength, self.scaleMax)
        let transform = CGAffineTransform(rotationAngle: rAngle)
        let scaleTransform = transform.scaledBy(x: scale, y: scale)
        self.transform = scaleTransform
        
        UIView.animate(withDuration: 1, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            self.center = ori
            self.transform = CGAffineTransform.identity
        }) { (success) in
            self.leftOverlay?.alpha = 0.0
            self.rightOverlay?.alpha = 0.0
        }
    }
    ///自动滑动卡片到一侧
    func autoSwipeMoveToLRAction(_ left:Bool){
        
        var leftFlag : CGFloat = -1
        if left == false{
            leftFlag = 1
        }
        
        self.xFromCenter = 120 * leftFlag
        self.yFromCenter = 0
        self.originalPoint = self.center
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            let rStrength = min(self.xFromCenter / self.rotationStrength, self.rotationMax)
            let rAngle = self.rotationAngle * rStrength
            let scale = min(1 - fabs(rStrength) / self.scaleStrength, self.scaleMax)
            self.center = CGPoint(x: self.originalPoint.x + self.xFromCenter, y: self.originalPoint.y + self.yFromCenter)
            let transform = CGAffineTransform(rotationAngle: rAngle)
            let scaleTransform = transform.scaledBy(x: scale, y: scale)
            self.transform = scaleTransform
            self.updateOverlay(self.xFromCenter)
        }) { (success) in
            self.xFromCenter = 200 * leftFlag
            self.yFromCenter = 0
            self.afterSwipeAction()
        }
        
    }
    
    @objc func dragEvent(gesture: UIPanGestureRecognizer) {
        xFromCenter = gesture.translation(in: self).x
        //yFromCenter = gesture.translation(in: self).y
        yFromCenter = 0//修改原有围绕手势中心点动画，改为围绕x轴的动画
        
        switch gesture.state {
        case .began:
            self.originalPoint = self.center
            break
        case .changed:
            let rStrength = min(xFromCenter / self.rotationStrength, rotationMax)
            let rAngle = self.rotationAngle * rStrength
            let scale = min(1 - fabs(rStrength) / self.scaleStrength, self.scaleMax)
            self.center = CGPoint(x: self.originalPoint.x + xFromCenter, y: self.originalPoint.y + yFromCenter)
            let transform = CGAffineTransform(rotationAngle: rAngle)
            let scaleTransform = transform.scaledBy(x: scale, y: scale)
            self.transform = scaleTransform
            self.updateOverlay(xFromCenter)
            break
        case .ended:
            self.afterSwipeAction()
            break
        default:
            break
        }
    }
    
    @objc func tapEvent(gesture: UITapGestureRecognizer) {
        self.delegate?.cardTapped(self)
    }
    
    private func afterSwipeAction() {
        self.delegate?.cardSwipedMoving(0,1,false,true)
        
        ///回到初始状态
        func insideToOriginalAction(){
            UIView.animate(withDuration: 0.3) {
                self.center = self.originalPoint
                self.transform = CGAffineTransform.identity
                self.leftOverlay?.alpha = 0.0
                self.rightOverlay?.alpha = 0.0
            }
        }
        
        ///触发左右滑动之后，通过代理返回值，确定是否进行由外部决定的结束滑动事件
        func insideLeftOrRightAction(_ left:Bool){
            let resumeValue = self.delegate?.cardSwipeResume(self,left, {
                (cancelSwipe) in
                //回调处理后续事件
                if cancelSwipe == true{
                    insideToOriginalAction()
                }else{
                    if left{
                        self.leftAction()
                    }else{
                        self.rightAction()
                    }
                }
            })
            if resumeValue == true{
                //暂停有真值，后续事件交由回调处理
            }else{
                //如果没有暂停，或者暂停值为false，自动运行后续过程
                if left{
                    self.leftAction()
                }else{
                    self.rightAction()
                }
            }
            
        }
        
        //只有触发阈值才会响应代理
        if xFromCenter > actionMargin {
            insideLeftOrRightAction(false)
        } else if xFromCenter < -actionMargin {
            insideLeftOrRightAction(true)
        } else {
            insideToOriginalAction()
        }
    }
    
    private func updateOverlay(_ distance: CGFloat) {
        var activeOverlay: UIView?
        if (distance > 0) {
            self.leftOverlay?.alpha = 0.0
            activeOverlay = self.rightOverlay
        } else {
            self.rightOverlay?.alpha = 0.0
            activeOverlay = self.leftOverlay
        }
        
        activeOverlay?.alpha = min(fabs(distance)/100, 1.0)
        
        //------添加左右动效-------------
        if let activeView = activeOverlay{
            
            //改用frame的x值修改动画
            let activeW = activeView.frame.size.width
            let centerX = (self.frame.size.width - activeW) * 0.5
            let screenW = UIScreen.main.bounds.size.width
            var anchorX:CGFloat = 120*(screenW/375)//需要适配不同手机
            if (activeView.convert(activeView.bounds, to: UIApplication.shared.keyWindow!).origin.x + activeView.frame.size.width * 0.5) == (activeView.superview!.convert(activeView.superview!.bounds, to: UIApplication.shared.keyWindow!).origin.x + activeView.superview!.frame.size.width * 0.5){
                anchorX = activeView.convert(activeView.bounds, to: UIApplication.shared.keyWindow!).origin.x + activeView.frame.size.width * 0.5
            }
            let proportion = fabs(distance)/anchorX//滑动比例
            let anchorLeftW = screenW - anchorX
            var activeX:CGFloat =  0
            if distance > 0 {
                activeX = screenW - anchorLeftW * proportion
                if distance >= anchorX {
                    activeX = centerX - activeW * 0.5
                }
            }else{
                activeX = anchorLeftW * proportion-activeW
                if distance <= -anchorX{
                    activeX = centerX - activeW * 0.5
                }
            }
            self.delegate?.cardSwipedMoving(activeX,proportion*0.5+0.5,distance<=0,false)
            //            print(#function,#line,distance,activeX)
            UIView .animate(withDuration: 0.01, animations: {
                activeView.frame = CGRect(x: activeX, y: (activeView.frame.origin.y), width: (activeView.frame.size.width), height: (activeView.frame.size.height))
                activeView.transform = CGAffineTransform(scaleX: proportion*0.5+0.5, y: proportion*0.5+0.5)
            }) { (complete) in
                
            }
        }
        //------添加左右动效-------------
    }
    
    private func rightAction() {
        let finishPoint = CGPoint(x: 500, y: 2 * yFromCenter + self.originalPoint.y)
        UIView.animate(withDuration: 0.1, animations: {
            self.center = finishPoint
        }) { _ in
            self.removeFromSuperview()
        }
        self.delegate?.cardSwipedRight(self)
    }
    
    private func leftAction() {
        let finishPoint = CGPoint(x: -500, y: 2 * yFromCenter + self.originalPoint.y)
        UIView.animate(withDuration: 0.1, animations: {
            self.center = finishPoint
        }) { _ in
            self.removeFromSuperview()
        }
        self.delegate?.cardSwipedLeft(self)
    }
}

extension DMSwipeCard: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
