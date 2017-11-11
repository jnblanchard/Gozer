//
//  TorchLabel.swift
//  Goz
//
//  Created by John N Blanchard on 11/11/17.
//  Copyright © 2017 JohnNBlanchard. All rights reserved.
//

import UIKit

@IBDesignable
class TorchLabel: UILabel {

  @IBInspectable
  public var on: Bool {
    set {
      let style = NSMutableParagraphStyle()
      style.alignment = .center
      let firstAtr =  [
        NSAttributedStringKey.font: UIFont(name: "Futura-Bold", size: 16),
        NSAttributedStringKey.foregroundColor: UIColor.white,
        NSAttributedStringKey.paragraphStyle: style
      ]

      let firstPart = NSMutableAttributedString(string: "Torch\n", attributes: firstAtr ?? [:] )

      let secondAtr = [
        NSAttributedStringKey.font: UIFont(name: "Futura-Medium", size: 14),
        NSAttributedStringKey.foregroundColor: UIColor.white,
        NSAttributedStringKey.paragraphStyle: style
      ]

      let con = on ? "Off" : "On"
      let secondPart = NSAttributedString(string: con, attributes: secondAtr ?? [:])

      firstPart.append(secondPart)
      attributedText = firstPart
    } get {
      guard let temp = text, temp.contains("On") else { return false }
      return true
    }
  }

}
