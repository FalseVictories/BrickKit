//
//  File.swift
//  BrickKit
//
//  Created by iain on 01/03/2025.
//

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
#endif

import Foundation

@MainActor
public class BKColorManager {
    private var colors: [UInt16: BKColor]
    
    private static var _shared: BKColorManager?
    public static var shared: BKColorManager {
        guard let shared = _shared else {
            fatalError("BKColorManager not initialized")
        }
        
        return shared
    }
    
    public static func createSharedColorManager(from file: String) async throws {
        guard _shared == nil else {
            return
        }
        
        _shared = try await BKColorManager(from: file)
    }
    
    private init(from filePath: String) async throws {
        colors = [:]
        
        let url = URL(fileURLWithPath: filePath)
        for try await line in url.lines {
            if let color = BKColor(from: line) {
                colors[color.code] = color
            }
        }
    }
}

extension BKColorManager {
    public func colorForID(_ id: UInt16) -> BKNativeColor? {
        return colors[id]?.color ?? nil
    }
}
