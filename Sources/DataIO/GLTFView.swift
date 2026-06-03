//
//  GLTFView.swift
//  DataIO
//
//  Created by Evgenij Lutz on 03.06.26.
//

#if canImport(RealityKit)

import SwiftUI
import RealityKit


@MainActor
func loadGLTFModel() async throws -> [Entity] {
    guard let url = Bundle.main.url(forResource: "SP-50", withExtension: "glb") else {
        print("fuck you")
        return []
    }
    
    let library = try await GLTFLibrary.from(url)
    //print(String(describing: library))
    
    guard let gltfMeshes = library.gltf.meshes else {
        return []
    }
    
    
    // Buffers
    struct Buffer {
        let buffer: GLTFBuffer
        let data: Data
    }
    var buffers = [Buffer]()
    if let gltfBuffers = library.gltf.buffers {
        for (index, gltfBuffer) in gltfBuffers.enumerated() {
            if let uri = gltfBuffer.uri {
                _ = uri
                throw GLTFError.other("Importing buffer data using URI is not yet implemented")
            }
            else {
                guard index < library.binaryChunks.count else {
                    throw GLTFError.other("Invalid binary chunk index: \(index). Number of binary chunks: \(library.binaryChunks.count)")
                }
                let buf = Buffer(buffer: gltfBuffer, data: library.binaryChunks[index])
                buffers.append(buf)
            }
        }
    }
    func buffer(at index: Int?) -> Buffer? {
        guard let index else {
            return nil
        }
        
        guard buffers.count > index else {
            return nil
        }
        
        return buffers[index]
    }
    
    
    // Meshes
    struct Mesh {
        var name: String?
        var submeshes = [MeshResource]()
        var materials = [any RealityKit.Material]()
    }
    var meshes = [Mesh]()
    func mesh(at index: Int?) -> Mesh? {
        guard let index else {
            return nil
        }
        
        guard meshes.count > index else {
            return nil
        }
        
        return meshes[index]
    }
    
    var entities = [Entity]()
    for gltfMesh in gltfMeshes {
        var mesh = Mesh(name: gltfMesh.name)
        
        for primitive in gltfMesh.primitives {
            typealias DataCopyFunction = (_ pointer: UnsafeMutableRawPointer, _ index: Int) -> Void
            
            // Index buffer accessor
            var numIndices = 0
            var indexType = MTLIndexType.uint32
            var indexStride = 4
            let indices = library.gltf.accessor(at: primitive.indices)
            var indexCopyFunction: DataCopyFunction = { _, _ in }
            if let indices,
               let bufferView = library.gltf.bufferView(at: indices.bufferView),
               let buffer = buffer(at: bufferView.buffer) {
                //print("Index: \(indices)")
                numIndices = indices.count
                
                switch indices.componentType {
                case .unsignedShort:
                    indexType = .uint16
                    indexStride = 2
                    
                case .unsignedInt:
                    indexType = .uint32
                    indexStride = 4
                    
                default:
                    break
                }
                
                
                // Data copy function
                let data = buffer.data
                data.withUnsafeBytes { rawPointer in
                    if let baseAddress = rawPointer.baseAddress?.advanced(by: bufferView.byteOffset ?? 0) {
                        indexCopyFunction = { pointer, index in
                            let address = baseAddress.advanced(by: index * indexStride)
                            pointer.copyMemory(from: address, byteCount: indexStride)
                        }
                    }
                }
            }
            
            // Material
            var materials = [any RealityKit.Material]()
            if let gltfMaterial = library.gltf.material(at: primitive.material) {
                var material = PhysicallyBasedMaterial()
                
                if let pbrMetallicRoughness = gltfMaterial.pbrMetallicRoughness {
                    //material.baseColor = .init(texture: nil)
                    
                    if let baseColorTexture = pbrMetallicRoughness.baseColorTexture,
                       let texture = library.gltf.texture(at: baseColorTexture.index),
                       let image = library.gltf.image(at: texture.source) {
                        //if let mimeType = image.mimeType {
                        //    print(mimeType)
                        //}
                        //if let uri = image.uri {
                        //    print(uri)
                        //}
                        if let bufferView = library.gltf.bufferView(at: image.bufferView),
                           let buffer = buffer(at: bufferView.buffer) {
                            let byteOffset = bufferView.byteOffset ?? 0
                            let imageData = Data(buffer.data[byteOffset ..< (byteOffset + bufferView.byteLength)])
                            if let ciImage = CIImage(data: imageData), let image = ciImage.cgImage {
                                let texture = try await TextureResource(image: image, options: .init(semantic: .color, mipmapsMode: .allocateAndGenerateAll))
                                material.baseColor = .init(texture: .init(texture))
                                
                                if gltfMaterial.alphaMode == .blend {
                                    // TODO: Use greyscale texture?
                                    material.blending = .transparent(opacity: .init(scale: 1))
                                }
                            }
                            else {
                                material.baseColor = .init(tint: .purple)
                            }
                        }
                        else {
                            // Other variants are not yet supported
                            // TODO: Implement other texture loading possibilities
                            material.baseColor = .init(tint: .blue)
                        }
                    }
                    else if let baseColor = pbrMetallicRoughness.baseColorFactor, baseColor.count == 4 {
                        let red = CGFloat(baseColor[0])
                        let green = CGFloat(baseColor[1])
                        let blue = CGFloat(baseColor[2])
                        let alpha = CGFloat(baseColor[3])
                        if alpha < 0.99 {
                            material.blending = .transparent(opacity: .init(scale: 1))
                        }
                        
                        material.baseColor = .init(tint: .init(red: red, green: green, blue: blue, alpha: alpha))
                    }
                    else {
                        material.baseColor = .init(tint: .yellow)
                    }
                    
                    if let roughnessFactor = pbrMetallicRoughness.roughnessFactor {
                        material.roughness = .init(scale: roughnessFactor)
                    }
                    
                    if let metallicFactor = pbrMetallicRoughness.metallicFactor {
                        material.metallic = .init(scale: metallicFactor)
                    }
                    
                    if gltfMaterial.doubleSided == true {
                        material.faceCulling = .none
                    }
                }
                else {
                    material.baseColor = .init(tint: .red)
                }
                
                material.normal = .init(texture: nil)
                
                materials.append(material)
                
                //materials = [SimpleMaterial(color: .red, isMetallic: true)]
            }
            
            // Vertex attributes
            var numVertices = 0
            var vertexStride = 0
            
            var positionAttribute: LowLevelMesh.Attribute?
            var positionCopyFunction: DataCopyFunction = { _, _ in }
            if let attribute = library.gltf.accessor(at: primitive.attributes["POSITION"]),
               let bufferView = library.gltf.bufferView(at: attribute.bufferView),
               let buffer = buffer(at: bufferView.buffer) {
                numVertices = attribute.count
                let stride = bufferView.byteStride ?? attribute.stride
                let offset = vertexStride
                positionAttribute = .init(semantic: .position, format: .float3, layoutIndex: 0, offset: offset)
                vertexStride += stride
                
                // Data copy function
                let data = buffer.data
                data.withUnsafeBytes { rawPointer in
                    if let baseAddress = rawPointer.baseAddress?.advanced(by: bufferView.byteOffset ?? 0) {
                        positionCopyFunction = { pointer, index in
                            let address = baseAddress.advanced(by: index * stride)
                            pointer.advanced(by: offset).copyMemory(from: address, byteCount: stride)
                        }
                    }
                }
            }
            
            var normalAttribute: LowLevelMesh.Attribute?
            var normalCopyFunction: DataCopyFunction = { _, _ in }
            if let attribute = library.gltf.accessor(at: primitive.attributes["NORMAL"]),
               let bufferView = library.gltf.bufferView(at: attribute.bufferView),
               let buffer = buffer(at: bufferView.buffer) {
                if numVertices != attribute.count {
                    print("⚠️ Inconsistent vertex count")
                }
                
                let stride = bufferView.byteStride ?? attribute.stride
                let offset = vertexStride
                normalAttribute = .init(semantic: .normal, format: .float3, layoutIndex: 0, offset: offset)
                vertexStride += stride
                
                // Data copy function
                let data = buffer.data
                data.withUnsafeBytes { rawPointer in
                    if let baseAddress = rawPointer.baseAddress?.advanced(by: bufferView.byteOffset ?? 0) {
                        normalCopyFunction = { pointer, index in
                            let address = baseAddress.advanced(by: index * stride)
                            pointer.advanced(by: offset).copyMemory(from: address, byteCount: stride)
                        }
                    }
                }
            }
            
            var uvAttribute: LowLevelMesh.Attribute?
            var uvCopyFunction: DataCopyFunction = { _, _ in }
            if let attribute = library.gltf.accessor(at: primitive.attributes["TEXCOORD_0"]),
               let bufferView = library.gltf.bufferView(at: attribute.bufferView),
               let buffer = buffer(at: bufferView.buffer) {
                if numVertices != attribute.count {
                    print("⚠️ Inconsistent vertex count")
                }
                
                let stride = bufferView.byteStride ?? attribute.stride
                let offset = vertexStride
                uvAttribute = .init(semantic: .uv0, format: .float2, layoutIndex: 0, offset: offset)
                vertexStride += stride
                
                // Data copy function
                let data = buffer.data
                data.withUnsafeBytes { rawPointer in
                    if let baseAddress = rawPointer.baseAddress?.advanced(by: bufferView.byteOffset ?? 0) {
                        uvCopyFunction = { pointer, index in
                            let address = baseAddress.advanced(by: index * stride)
                            
                            // Flip the y coordinate
                            var uv = address.loadUnaligned(as: SIMD2<Float>.self)
                            uv.y = 1 - uv.y
                            
                            pointer.advanced(by: offset).copyMemory(from: &uv, byteCount: stride)
                        }
                    }
                }
            }
            
            let vertexAttributes = [positionAttribute, normalAttribute, uvAttribute].compactMap(\.self)
            let vertexLayouts = [LowLevelMesh.Layout(bufferIndex: 0, bufferOffset: 0, bufferStride: vertexStride)]
            
            let llm = try LowLevelMesh(descriptor: .init(vertexCapacity: numVertices,
                                                         vertexAttributes: vertexAttributes,
                                                         vertexLayouts: vertexLayouts,
                                                         indexCapacity: numIndices,
                                                         indexType: indexType))
            
            // Fill vertex data
            llm.withUnsafeMutableBytes(bufferIndex: 0) { pointer in
                if let baseAddress = pointer.baseAddress {
                    for vertexIndex in 0 ..< numVertices {
                        let address = baseAddress.advanced(by: vertexIndex * vertexStride)
                        positionCopyFunction(address, vertexIndex)
                        normalCopyFunction(address, vertexIndex)
                        uvCopyFunction(address, vertexIndex)
                    }
                }
            }
            
            // Fill index data
            if numIndices > 0 {
                llm.withUnsafeMutableIndices { pointer in
                    if let baseAddress = pointer.baseAddress {
                        for index in 0 ..< numIndices {
                            let address = baseAddress.advanced(by: index * indexStride)
                            indexCopyFunction(address, index)
                        }
                    }
                }
            }
            
            // TODO: Calculate bounding box on the fly
            llm.parts.replaceAll([
                .init(indexCount: numIndices, topology: .triangle, bounds: .init(min: .init(-2, -2, -2), max: .init(2, 2, 2)))
            ])
            
            let meshResource = try await MeshResource(from: llm)
            mesh.submeshes.append(meshResource)
            mesh.materials = materials
            
            //let entity = Entity()
            //if let name = gltfMesh.name {
            //    entity.name = name
            //}
            //let mc = ModelComponent(mesh: meshResource, materials: materials)
            //entity.components.set(mc)
            //
            //entities.append(entity)
        }
        
        meshes.append(mesh)
    }
    
    if let scene = library.gltf.scene(at: library.gltf.scene), let nodes = scene.nodes {
        let rootEntity = Entity()
        rootEntity.transform.translation = .init(0, -0.7, 0)
        entities.append(rootEntity)
        
        func appendNode(_ nodeIndex: Int?, parent: Entity) {
            guard let node = library.gltf.node(at: nodeIndex) else {
                return
            }
            
            let entity = Entity()
            if let name = node.name {
                entity.name = name
            }
            
            if let mesh = mesh(at: node.mesh) {
                for submesh in mesh.submeshes {
                    let mc = ModelComponent(mesh: submesh, materials: mesh.materials)
                    entity.components.set(mc)
                }
            }
            
            if let translation = node.translation, translation.count == 3 {
                entity.transform.translation = .init(translation[0], translation[1], translation[2])
            }
            
            if let rotation = node.rotation, rotation.count == 4 {
                entity.transform.rotation = .init(ix: rotation[0], iy: rotation[1], iz: rotation[2], r: rotation[3])
            }
            
            if let scale = node.scale, scale.count == 3 {
                entity.transform.scale = .init(scale[0], scale[1], scale[2])
            }
            
            parent.children.append(entity)
            
            if let children = node.children {
                for child in children {
                    appendNode(child, parent: entity)
                }
            }
        }
        
        for nodeIndex in nodes {
            appendNode(nodeIndex, parent: rootEntity)
        }
    }
    
    return entities
}


struct GLTFView: View {
    var body: some View {
        RealityView { content in
            do {
                let env = try await EnvironmentResource(named: "Studio")
                content.environment = .skybox(env)
                
                let startTime = CACurrentMediaTime()
                let entities = try await loadGLTFModel()
                let elapsed = CACurrentMediaTime() - startTime
                print("Import time taken: \(elapsed)")
                
                content.entities.append(contentsOf: entities)
                //print("Num entities: \(entities.count)")
            }
            catch {
                print(error)
            }
        }
        .realityViewCameraControls(.orbit)
        
//        Text("Cunt")
//            .task { @concurrent in
//                do {
//                    let startTime = CACurrentMediaTime()
//                    _ = try await loadGLTFModel()
//                    let elapsed = CACurrentMediaTime() - startTime
//                    print("Import time taken: \(elapsed)")
//                }
//                catch {
//                    print(error)
//                }
//            }
        
    }
}

#endif

