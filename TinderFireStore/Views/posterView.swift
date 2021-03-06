//
//  CardView.swift
//  TinderFireStore
//
//  Created by wenlong qiu on 8/11/19.
//  Copyright © 2019 wenlong qiu. All rights reserved.
//

import UIKit
import SDWebImage

protocol CardViewDelegate {
    func didTapMoreInfo(cardViewModel: PosterViewModel)
    func didRemoveCard(cardView: posterView)
    func didSwipe(translationDirection: CGFloat)
}

class posterView: UIView {

    var nextCardView: posterView?
    
    var delegate: CardViewDelegate?
    
    //didset invoked upon loading homecontroller in setupcardfromuser
    var posterViewModel: PosterViewModel! {
        didSet {
//            let imageName = cardViewModel.imageUrls.first ?? "" //imageNames[0] not defined optional, if count == 0 will crash
//            let url = URL(string: imageName)
//            imageView.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "photo_placeholder"), options: .continueInBackground) //image placeholder in case url doesnt work, placehold image will show until finish load pic
            
            swipingPhotosController.cardViewModel = self.posterViewModel
            
            informationLabel.attributedText = posterViewModel.attributedString
            informationLabel.textAlignment = posterViewModel.textAlignment
            
            (0..<posterViewModel.imageUrls.count).forEach { (_) in
                let barView = UIView()
                barView.backgroundColor = barDeselectedColor
                barsStackView.addArrangedSubview(barView)
            }
            barsStackView.arrangedSubviews.first?.backgroundColor = .white
            setupImageIndexObserver()
        }
    }
    
    
    fileprivate let swipingPhotosController = SwipingPhotosController(isCardViewMode: true)
    fileprivate let informationLabel = UILabel()
    
    //Configurations
    fileprivate let threshold: CGFloat = 80 //setting fileprivate is for easy locate bugs, bugs of this property must be within this file

    fileprivate let gradientLayer = CAGradientLayer()

    fileprivate let barsStackView = UIStackView()
    
    fileprivate var imageIndex = 0
    
    fileprivate let barDeselectedColor = UIColor(white: 0, alpha: 0.1)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        backgroundColor = UIColor.white
        layer.opacity = 1
        //handlePan automatically capture panGesture as gesture parameter, recognizer captures gesture, observer captures notification
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    
    //goal is to react when a property in another class changes, defines the reaction here
    fileprivate func setupImageIndexObserver() {
        posterViewModel.imageIndexObserver = { [weak self](idx, imageUrl) in //avoid memorhy cycle
//            let url = URL(string: imageUrl!)
//            self?.barsStackView.arrangedSubviews.forEach({ (v) in
//                v.backgroundColor = self?.barDeselectedColor
//            })
//            self?.barsStackView.arrangedSubviews[idx].backgroundColor = .white
        }
    }
    
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: nil) //closest responder is self
        let shouldAdvanceNextPhoto = tapLocation.x > frame.width / 2 ? true : false
        
        if shouldAdvanceNextPhoto {
            posterViewModel.goToNextPic()
        } else {
            posterViewModel.backToPreviousPic()
        }
        
    }
    
    fileprivate let moreInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "info_icon").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleMoreInfo), for: .touchUpInside)

        return button
    }()
    
    @objc fileprivate func handleMoreInfo() {
        //cardview object has no present method
        //not optimal soluton becasue of maintainabilty
//        let rootViewController = UIApplication.shared.keyWindow?.rootViewController //present anycontroller u want but be caraful with view hierachy
//        let userDetailsController = UIViewController()
//        userDetailsController.view.backgroundColor = .white
//        rootViewController?.present(userDetailsController, animated: true)
        
        delegate?.didTapMoreInfo(cardViewModel: self.posterViewModel)
    }
    
    fileprivate func setupLayout() {
        layer.cornerRadius = 10
        clipsToBounds = true //if false exceeding frames from bounds are not clipped
        
        let swipingPhotosView = swipingPhotosController.view!
        addSubview(swipingPhotosView)
        swipingPhotosView.fillSuperview()
        
        
        setupGradientLayer() //self.frame is zero at this point, wont be zero when init is done
        
        
        addSubview(informationLabel) //add subview upon the previous subview, z position + 1
        informationLabel.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 16, right: 16))
        informationLabel.textColor = .white
        informationLabel.numberOfLines = 0
        
        addSubview(moreInfoButton)
        moreInfoButton.anchor(top: nil, leading: nil, bottom: self.bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 16, right: 16), size: .init(width: 44, height: 44)) //apple guideline button size has to be bigger than 40
    }
    
    fileprivate func setupBarsStackView() {
        addSubview(barsStackView)
        barsStackView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 8, left: 8, bottom: 0, right: 8), size: .init(width: 0, height: 4))
        barsStackView.spacing = 4
        barsStackView.distribution = .fillEqually
        
        
    }
    
    fileprivate func setupGradientLayer() {
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [0.5,1.1] //gradient from top to bottom 0 being top 1 being bottom
        
        layer.addSublayer(gradientLayer)
    
    }
    //executed when view draws itself, this stage, cardview or self.frame is not zero anymore
    override func layoutSubviews() {
        gradientLayer.frame = self.frame //self.frame is not zero only after self.init(), more precisely, not zero after Homecontroller anchored poster view. posterview is not Homecontroller's view so cant use view.bounds
    }
    
    
    @objc fileprivate func handlePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            superview?.subviews.forEach({ (subview) in
                subview.layer.removeAllAnimations() //remove all unfinished animations when new animation begin
            })
        case .changed:
            handleChanged(gesture)
        case .ended:
            handleEnded(gesture)
        default:
            ()
        }
    }
    //view  rotates and translate according to user panning
    fileprivate func handleChanged(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: nil)
        let degrees: CGFloat = translation.x / 20 //minimize rotatation per translation
        let angle = degrees * .pi / 180
        let rotationalTransformation = CGAffineTransform(rotationAngle: angle)
        transform = rotationalTransformation.translatedBy(x: translation.x, y: translation.y)
        
    }
    
    //when user stops pannign return to original position
    fileprivate func handleEnded(_ gesture: UIPanGestureRecognizer) {
        //nil will get you this view
        let translationDirection: CGFloat = gesture.translation(in: nil).x > 0 ? 1 : -1
        let shouldDismissCard = abs(gesture.translation(in: nil).x) > threshold
        if shouldDismissCard {
            self.delegate?.didSwipe(translationDirection: translationDirection)
        } else {
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
                self.transform = .identity
            })
        }
        
//        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
//
//            if shouldDismissCard {
//                //self.frame = CGRect(x: 600 * translationDirection, y: 0, width: self.frame.width, height: self.frame.height)
//            // below lines will make card go up and go left at the same time, above will go up and then go left
//                let offScreenTransform = self.transform.translatedBy(x: 600 * translationDirection, y: 0)
//                self.transform = offScreenTransform
//            } else {
//                self.transform = .identity
//            }
//        }) { (_) in
//            //self.transform = .identity //this line suppose to return cards back when swiped but since removeFromSuperView anyuway so this line is useless
//            if shouldDismissCard {
//                self.removeFromSuperview()
//                self.delegate?.didRemoveCard(cardView: self)
////                self.frame = CGRect(x: 0, y: 0, width: self.superview!.frame.width, height: self.superview!.frame.height)
//            }
//
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
