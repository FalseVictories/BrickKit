//
//  File.swift
//  BrickKit
//
//  Created by iain on 18/02/2025.
//

import Foundation
import SceneKit

#if os(macOS)
typealias FloatPrecisionType = Double
#elseif os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
typealias FloatPrecisionType = Float
#endif

extension SCNVector3 {
    init?(xStr: String,
          yStr: String,
          zStr: String) {
        guard let x = FloatPrecisionType(xStr),
              let y = FloatPrecisionType(yStr),
              let z = FloatPrecisionType(zStr) else {
            return nil
        }
        self.init(x: x, y: y, z: z)
    }
}
