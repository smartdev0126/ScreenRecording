//
//  AVAssetWriter.Status+stringDescription.swift
//  mybroadcast
//
//  Created by Andrei Yakugov on 4/21/22.
//


import AVFoundation

extension AVAssetWriter.Status: CustomStringConvertible {

    public var description: String {
        switch self {
        case .cancelled:
            return "cancelled"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        case .unknown:
            return "unknown"
        case .writing:
            return "writing"
        @unknown default:
            return "@unknown default"
        }
    }
}
