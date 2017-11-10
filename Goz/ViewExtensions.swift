//
//  ViewExtensions.swift
//  Goz
//
//  Created by John N Blanchard on 11/9/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension UIView {
  func rotateViewForOrientations(orientation: UIDeviceOrientation) {
    switch orientation {
    case .landscapeLeft:
      transform = CGAffineTransform.identity.rotated(by: CGFloat(Double.pi/2))
    case .landscapeRight:
      transform = CGAffineTransform.identity.rotated(by: CGFloat(-Double.pi/2))
    default:
      transform = CGAffineTransform.identity
    }
  }
}

extension UIDeviceOrientation { var videoOrientation: AVCaptureVideoOrientation? { switch self { case .portrait: return .portrait case .portraitUpsideDown: return .portraitUpsideDown case .landscapeLeft: return .landscapeRight case .landscapeRight: return .landscapeLeft default: return nil } } }
