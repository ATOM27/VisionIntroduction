//
//  SceneType.swift
//  VisionIntroduction
//
//  Created by Eugene  Mekhedov on 24.05.2018.
//  Copyright © 2018 Eugene  Mekhedov. All rights reserved.
//

import Foundation

enum SceneType {
    case forest
    case beach
    case other
    
    init(classification: String) {
        switch classification {
        case "ocean", "playground":
            self = .beach
        case "rainforest", "forest_path", "bamboo_forest", "forest_road", "tree_farm", "rope_bridge", "mountain_snowy":
            self = .forest
        default:
            self = .other
        }
    }
}

extension SceneType: Equatable { }
