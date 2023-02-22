//
//  CGFloat+NSNumber.swift
//  mybroadcast
//
//  Created by Andrei Yakugov on 4/21/22.
//


import Foundation
import CoreGraphics

extension CGFloat {

    var nsNumber: NSNumber {
        return .init(value: native)
    }
}

