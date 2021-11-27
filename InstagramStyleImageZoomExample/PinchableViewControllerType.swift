//
//  PinchableViewControllerType.swift
//  InstagramStyleImageZoomExample
//
//  Created by Aaron Lee on 2021/11/15.
//

import UIKit
import RxSwift

protocol PinchableViewControllerType: UIViewController {
    
    var bag: DisposeBag { get }
    
    var tableView: UITableView { get }
    
    var pinchedImageBackgroundView: UIView { get }
    
    var pinchedImageView: PinchImageView { get }
    
    var isImagePinched: Bool { get set }
    
    var imageViewDidPinch: PublishSubject<UIPinchGestureRecognizer> { get }
    
    var imageViewDidPan: PublishSubject<UIPanGestureRecognizer> { get }
    
    func bindImageViewPinchGesture()
    
    func bindImageViewPanGesture()
    
}

extension PinchableViewControllerType {
    
    func bindImageViewPinchGesture() {
        imageViewDidPinch
            .when(.began)
            .subscribe(onNext: { [weak self] gesture in
                self?.imageViewPinchGestureDidBegin(gesture: gesture)
            })
            .disposed(by: bag)
        
        imageViewDidPinch
            .when(.changed)
            .subscribe(onNext: { [weak self] gesture in
                self?.imageViewPinchGestureDidChange(with: gesture)
            })
            .disposed(by: bag)
        
        let pinchEndObservable = Observable.of(imageViewDidPinch.when(.ended),
                                               imageViewDidPinch.when(.cancelled),
                                               imageViewDidPinch.when(.failed)).merge()
        
        pinchEndObservable
            .subscribe(onNext: { [weak self] gesture in
                self?.imageViewPinchGestureDidEnd(gesture: gesture)
            })
            .disposed(by: bag)
    }
    
    private func imageViewPinchGestureDidBegin(gesture: UIPinchGestureRecognizer) {
        guard let gestureView = gesture.view as? UIImageView else { return }
        
        if gesture.scale < 1 { return }
        if isImagePinched { return }
        
        pinchedImageView.pinchGesture = gesture
        
        // Flags
        isImagePinched = true
        tableView.panGestureRecognizer.isEnabled = false
        
        // Image
        let image = gestureView.image
        pinchedImageView.image = image
        
        // Position + Frame
        let convertedFrame = gestureView.convert(gestureView.bounds, to: view)
        pinchedImageView.frame = convertedFrame
        
        // Visiblity
        pinchedImageView.alpha = 1
        gestureView.alpha = 0
        
        imageViewPinchGestureDidChange(with: gesture)
        
        UIView.animate(withDuration: 0.15) {
            self.pinchedImageBackgroundView.alpha = 0.6
        }
    }
    
    private func imageViewPinchGestureDidChange(with gesture: UIPinchGestureRecognizer) {
        guard let gestureView = gesture.view else { return }
        
        let pinchCentre = CGPoint(x: gesture.location(in: gestureView).x - gestureView.bounds.midX,
                                  y: gesture.location(in: gestureView).y - gestureView.bounds.midY)
        
        let currentScale = pinchedImageView.frame.width / pinchedImageView.bounds.size.width
        
        var newScale = gesture.scale
        
        let calculatedScale = currentScale * gesture.scale
        
        if calculatedScale < kImagePinchMinScale {
            newScale = kImagePinchMinScale / currentScale
            
        } else if calculatedScale > kImagePinchMaxScale {
            newScale = kImagePinchMaxScale / currentScale
    
        }
        
        pinchedImageView.transform = pinchedImageView
            .transform
            .translatedBy(x: pinchCentre.x, y: pinchCentre.y)
            .scaledBy(x: newScale, y: newScale)
            .translatedBy(x: -pinchCentre.x, y: -pinchCentre.y)
        
        gesture.scale = 1
    }
    
    private func imageViewPinchGestureDidEnd(gesture: UIPinchGestureRecognizer) {
        guard let cellImageView = gesture.view as? UIImageView else { return }
        gesture.scale = 1
        tableView.panGestureRecognizer.isEnabled = true
        
        UIView.animate(withDuration: 0.3) {
            
            self.pinchedImageBackgroundView.alpha = 0
            self.pinchedImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.pinchedImageView.frame = cellImageView.convert(cellImageView.bounds, to: self.view)
            
        } completion: { _ in
            self.isImagePinched = false
            
            self.pinchedImageView.alpha = 0
            cellImageView.alpha = 1
        }
        
    }
    
    func bindImageViewPanGesture() {
        let changeObservable = Observable.of(imageViewDidPan.when(.began),
                                             imageViewDidPan.when(.changed),
                                             imageViewDidPan.when(.ended)).merge()
        changeObservable
            .subscribe { [weak self] gesture in
                self?.imageViewPanGestureDidRecognize(gesture)
            }
            .disposed(by: bag)
        
        let endObservable = Observable.of(imageViewDidPan.when(.failed),
                                          imageViewDidPan.when(.cancelled)).merge()
        
        endObservable
            .subscribe(onNext: { [weak self] _ in
                guard let pinchGesture = self?.pinchedImageView.pinchGesture else { return }
                self?.imageViewPinchGestureDidEnd(gesture: pinchGesture)
            })
            .disposed(by: bag)
    }
    
    private func imageViewPanGestureDidRecognize(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        pinchedImageView.center = CGPoint(x: pinchedImageView.center.x + translation.x, y: pinchedImageView.center.y + translation.y)
        gesture.setTranslation(.zero, in: view)
    }
    
}
