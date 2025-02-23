//
//  File.swift
//  BrickKit
//
//  Created by iain on 21/02/2025.
//

import Accelerate
import Foundation
import SceneKit

extension SCNMatrix4 {
    var determinant: Float {
        let m = simd_float4x4(self)
        return m.determinant
    }
}
