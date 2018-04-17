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
  func cardTapped(_ card: DMSwipeCard)
}

class DMSwipeCard: UIView {

	weak var delegate: DMSwipeCardDelegate?
	var obj: Any!
	var leftOverlay: UIView?
	var rightOverlay: UIView?

	private let actionMargin: CGFloat = 120.0
	private let rotationStrength: CGFloat = 320.0
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

	func configureOverlays() {
		self.configureOverlay(overlay: self.leftOverlay)
		self.configureOverlay(overlay: self.rightOverlay)
	}

	private func configureOverlay(overlay: UIView?) {
		if let o = overlay {
			self.addSubview(o)
			o.alpha = 0.0
		}
	}

	@objc func dragEvent(gesture: UIPanGestureRecognizer) {
		xFromCenter = gesture.translation(in: self).x
		yFromCenter = gesture.translation(in: self).y

		switch gesture.state {
		case .began:
			self.originalPoint = self.center
			break
		case .changed:
            //----添加垂直滑动屏蔽-------
            //switch (xFromCenter, yFromCenter) {
            //case let (x, y) where abs(x) >= abs(y) && x > 0:
              //  //Right
             //   break
            //case let (x, y) where abs(x) >= abs(y) && x < 0:
              //  //Left
             //   break
            //default:
            //    return
            //}
            //----添加垂直滑动屏蔽-------
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
		if xFromCenter > actionMargin {
			self.rightAction()
		} else if xFromCenter < -actionMargin {
			self.leftAction()
		} else {
			UIView.animate(withDuration: 0.3) {
				self.center = self.originalPoint
				self.transform = CGAffineTransform.identity
				self.leftOverlay?.alpha = 0.0
				self.rightOverlay?.alpha = 0.0
			}
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
            
            //尝试使用convert，失败
////            let activeW = activeView.frame.size.width
//            let screenW = UIScreen.main.bounds.size.width
//
////            if distance == 0.001 {
////                activeView.center = CGPoint(x: self.frame.size.width * 0.5, y: activeView.center.y)
////            }else if distance == -0.001 {
////                activeView.center = CGPoint(x: 0, y: activeView.center.y)
////            }
//
//            let activeCenterToWindow = activeView.convert(activeView.center, to: UIApplication.shared.keyWindow!)
//
//            let proportion = fabs(distance)/(screenW * 0.5)
//            var activeCenterX:CGFloat =  activeView.center.x
//            print("\n")
//            print("activeCenterToWindow=",activeCenterToWindow)
//            if distance > 0 {
//                activeCenterX = screenW - fabs(distance)/
////                if distance >= (self.convert(self.center, to: UIApplication.shared.keyWindow!).x - screenW * 0.5) {
////                    activeCenterX = self.center.x
////                }
//            }else{
//                activeCenterX = fabs(distance) + 100
////                if fabs(distance) >= screenW - self.convert(self.center, to: UIApplication.shared.keyWindow!).x {
////                    activeCenterX = self.center.x
////                }
//            }
////            print(#function,#line,distance,activeCenterX)
//            let centerFromWindow = activeView.convert(CGPoint(x: activeCenterX, y: activeCenterToWindow.y), from: UIApplication.shared.keyWindow!)
//            print("distance=",distance)
//            print("centerFromWindow=",centerFromWindow)
//            print("rect ori=",activeView.frame)
//            print("rect con=",activeView.convert(activeView.frame, to: UIApplication.shared.keyWindow!))
//            UIView .animate(withDuration: 0.01, animations: {
//                activeView.center = CGPoint(x: activeCenterX, y: activeView.center.y)
////                activeView.transform = CGAffineTransform.init(scaleX: proportion, y: proportion)
//            }) { (complete) in
//
//            }
            
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
            print(#function,#line,distance,activeX)
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
		UIView.animate(withDuration: 0.3, animations: { 
			self.center = finishPoint
		}) { _ in
			self.removeFromSuperview()
		}
		self.delegate?.cardSwipedRight(self)
	}

	private func leftAction() {
		let finishPoint = CGPoint(x: -500, y: 2 * yFromCenter + self.originalPoint.y)
		UIView.animate(withDuration: 0.3, animations: {
			self.center = finishPoint
		}) { _ in
			self.removeFromSuperview()
		}
		self.delegate?.cardSwipedLeft(self)
	}
}

extension DMSwipeCard: UIGestureRecognizerDelegate {
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}
