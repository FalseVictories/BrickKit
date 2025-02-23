//
//  File.swift
//  BrickKit
//
//  Created by iain on 18/02/2025.
//

import Foundation
import SceneKit

extension SCNVector3 {
    init?(xStr: String,
          yStr: String,
          zStr: String) {
        guard let x = Double(xStr),
              let y = Double(yStr),
              let z = Double(zStr) else {
            return nil
        }
        self.init(x: x, y: y, z: z)
    }
}
