//
//  GLTFExtensions.swift
//  DataIO
//
//  Created by Evgenij Lutz on 03.06.26.
//

import Foundation


public extension GLTF {
    func accessor(at index: Int?) -> GLTFAccessor? {
        guard let index else {
            return nil
        }
        
        guard let accessors else {
            return nil
        }
        
        guard accessors.count > index else {
            return nil
        }
        
        return accessors[index]
    }
    
    
    func material(at index: Int?) -> GLTFMaterial? {
        guard let index else {
            return nil
        }
        
        guard let materials else {
            return nil
        }
        
        guard materials.count > index else {
            return nil
        }
        
        return materials[index]
    }
    
    
    func bufferView(at index: Int?) -> GLTFBufferView? {
        guard let index else {
            return nil
        }
        
        guard let bufferViews else {
            return nil
        }
        
        guard bufferViews.count > index else {
            return nil
        }
        
        return bufferViews[index]
    }
    
    
    func buffer(at index: Int?) -> GLTFBuffer? {
        guard let index else {
            return nil
        }
        
        guard let buffers else {
            return nil
        }
        
        guard buffers.count > index else {
            return nil
        }
        
        return buffers[index]
    }
    
    
    func texture(at index: Int?) -> GLTFTexture? {
        guard let index else {
            return nil
        }
        
        guard let textures else {
            return nil
        }
        
        guard textures.count > index else {
            return nil
        }
        
        return textures[index]
    }
    
    
    func image(at index: Int?) -> GLTFImage? {
        guard let index else {
            return nil
        }
        
        guard let images else {
            return nil
        }
        
        guard images.count > index else {
            return nil
        }
        
        return images[index]
    }
    
    
    func scene(at index: Int?) -> GLTFScene? {
        guard let index else {
            return nil
        }
        
        guard let scenes else {
            return nil
        }
        
        guard scenes.count > index else {
            return nil
        }
        
        return scenes[index]
    }
    
    
    func node(at index: Int?) -> GLTFNode? {
        guard let index else {
            return nil
        }
        
        guard let nodes else {
            return nil
        }
        
        guard nodes.count > index else {
            return nil
        }
        
        return nodes[index]
    }
    
}


public extension GLTFAccessor {
    var stride: Int {
        let componentSize: Int
        switch componentType {
        case .byte: componentSize = 1
        case .unsignedByte: componentSize = 1
        case .short: componentSize = 2
        case .unsignedShort: componentSize = 2
        case .unsignedInt: componentSize = 4
        case .float: componentSize = 4
        }
        
        let numComponents: Int
        switch type {
        case .scalar: numComponents = 1
        case .vec2: numComponents = 2
        case .vec3: numComponents = 3
        case .vec4: numComponents = 4
        case .mat2: numComponents = 4
        case .mat3: numComponents = 9
        case .mat4: numComponents = 16
        }
        
        return numComponents * componentSize
    }
}
