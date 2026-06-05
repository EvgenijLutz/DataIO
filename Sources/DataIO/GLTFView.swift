//
//  GLTFView.swift
//  DataIO
//
//  Created by Evgenij Lutz on 03.06.26.
//

#if canImport(RealityKit)

import SwiftUI
import ARKit
import RealityKit


typealias Vector3f = SIMD3<Float>
typealias Quaternionf = simd_quatf


@MainActor
func gltfTest() async throws -> [Entity] {
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
            
            func loadTextureResource(_ imageIndex: Int, _ semantic: TextureResource.Semantic = .color) async throws -> TextureResource? {
                guard let texture = library.gltf.texture(at: imageIndex) else {
                    return nil
                }
                
                guard let image = library.gltf.image(at: texture.source) else {
                    return nil
                }
                
                guard let bufferView = library.gltf.bufferView(at: image.bufferView) else {
                    return nil
                }
                
                guard let buffer = buffer(at: bufferView.buffer) else {
                    return nil
                }
                
                let byteOffset = bufferView.byteOffset ?? 0
                let imageData = Data(buffer.data[byteOffset ..< (byteOffset + bufferView.byteLength)])
                guard let ciImage = CIImage(data: imageData) else {
                    return nil
                }
                
                guard let image = ciImage.cgImage else {
                    return nil
                }
                
                return try await TextureResource(image: image, options: .init(semantic: semantic, mipmapsMode: .allocateAndGenerateAll))
            }
            
            // Material
            var materials = [any RealityKit.Material]()
            if let gltfMaterial = library.gltf.material(at: primitive.material) {
                var material = PhysicallyBasedMaterial()
                
                // PBR material
                if let pbrMetallicRoughness = gltfMaterial.pbrMetallicRoughness {
                    // Base colour
                    if let baseColorTexture = pbrMetallicRoughness.baseColorTexture,
                       let texture = try await loadTextureResource(baseColorTexture.index) {
                        material.baseColor = .init(texture: .init(texture))
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
                    
                    
                    // Metallic-Roughness
                    //if let mr = pbrMetallicRoughness.metallicRoughnessTexture,
                    //   let texture = try await loadTextureResource(mr.index, .raw) {
                    //    //
                    //}
                    
                    
                    // Roughness
                    if let roughnessFactor = pbrMetallicRoughness.roughnessFactor {
                        material.roughness = .init(scale: roughnessFactor)
                    }
                    
                    
                    // Metallic
                    if let metallicFactor = pbrMetallicRoughness.metallicFactor {
                        material.metallic = .init(scale: metallicFactor)
                    }
                }
                
                
                // Normal map
                if let normalTexture = gltfMaterial.normalTexture,
                   let texture = try await loadTextureResource(normalTexture.index, .normal) {
                    //print("Cunt")
                    material.normal = .init(texture: .init(texture))
                }
                else {
                    material.normal = .init(texture: nil)
                }
                
                
                // Alpha blend mode
                if gltfMaterial.alphaMode == .blend {
                    // TODO: Use greyscale texture if set?
                    material.blending = .transparent(opacity: .init(scale: 1))
                    material.opacityThreshold = 0.01
                }
                
                
                // Face culling
                if gltfMaterial.doubleSided == true {
                    material.faceCulling = .none
                }
                
                materials.append(material)
            }
            materials.append(OcclusionMaterial())
            
            // Vertex attributes
            var numVertices = 0
            var vertexStride = 0
            
            var minPosition = Vector3f(-2, -2, -2)
            var maxPosition = Vector3f(2, 2, 2)
            
            var positionAttribute: LowLevelMesh.Attribute?
            var positionCopyFunction: DataCopyFunction = { _, _ in }
            if let attribute = library.gltf.accessor(at: primitive.attributes["POSITION"]),
               let bufferView = library.gltf.bufferView(at: attribute.bufferView),
               let buffer = buffer(at: bufferView.buffer) {
                if let min = attribute.min, min.count == 3 {
                    minPosition = .init(min[0], min[1], min[2])
                }
                if let max = attribute.max {
                    maxPosition = .init(max[0], max[1], max[2])
                }
                print("Bounds: \(minPosition) - \(maxPosition)")
                
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
            
            
            if let _ = library.gltf.accessor(at: primitive.attributes["TANGENT"]) {
                print("Tangent")
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
                .init(indexCount: numIndices, topology: .triangle, bounds: .init(min: minPosition, max: maxPosition))
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


class ARDelegate: NSObject, ARSessionDelegate {
    weak var arView: ARView?
    var anchorsAdded: (_ anchors: [ARAnchor]) -> Void = { _ in }
    
    /**
     This is called when a new frame has been updated.
    
     @param session The session being run.
     @param frame The frame that has been updated.
     */
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //print("Did update frame: \(frame)")
    }

    /**
     This is called when new anchors are added to the session.
    
     @param session The session being run.
     @param anchors An array of added anchors.
     */
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("Did add anchors: \(anchors)")
        anchorsAdded(anchors)
    }

    /**
     This is called when anchors are updated.
    
     @param session The session being run.
     @param anchors An array of updated anchors.
     */
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //print("Did update anchors: \(anchors)")
    }

    /**
     This is called when anchors are removed from the session.
    
     @param session The session being run.
     @param anchors An array of removed anchors.
     */
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("Did remove anchors: \(anchors)")
    }
}


struct GLTFView_Old: View {
    let arSession = ARSession()
    let arDelegate = ARDelegate()
    let worldTracking = ARWorldTrackingConfiguration()
    
    var body: some View {
        RealityView { content in
            do {
#if false
                let env = try await EnvironmentResource(named: "Studio")
                content.environment = .skybox(env)
#else
                content.camera = .spatialTracking
#endif
                
                content.renderingEffects.depthOfField = .enabled
                content.renderingEffects.motionBlur = .enabled
                
                let startTime = CACurrentMediaTime()
                let entities = try await gltfTest()
                let elapsed = CACurrentMediaTime() - startTime
                print("Import time taken: \(elapsed)")
                
                if let rootEntity = entities.first {
                    //rootEntity.transform.translation = .init(0, -0.7, 0)
                    rootEntity.transform.scale = .init(0.1, 0.1, 0.1)
                    rootEntity.generateCollisionShapes(recursive: true)
                }
                
                content.entities.append(contentsOf: entities)
                //print("Num entities: \(entities.count)")
                
//                if ARWorldTrackingConfiguration.isSupported {
//                    worldTracking.planeDetection = [.horizontal, .vertical]
//
//                    arSession.run(worldTracking)
//
//                    arSession.delegate = arDelegate
//                }
            }
            catch {
                print(error)
            }
        }
        .realityViewCameraControls(.orbit)
//            .task { @concurrent in
//                do {
//                    let startTime = CACurrentMediaTime()
//                    _ = try await gltfTest()
//                    let elapsed = CACurrentMediaTime() - startTime
//                    print("Import time taken: \(elapsed)")
//                }
//                catch {
//                    print(error)
//                }
//            }
        
    }
}


struct SysmexView: UIViewRepresentable {
    typealias UIViewType = ARView
    var create: (_ view: ARView) -> Void
    var update: (_ view: ARView) -> Void
    
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .init(x: 0, y: 0, width: 10, height: 10), cameraMode: .ar, automaticallyConfigureSession: false)
        create(view)
        return view
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        update(uiView)
    }
    
    
}


struct GLTFView: View {
    let arSession = ARSession()
    let arDelegate = ARDelegate()
    let worldTracking = ARWorldTrackingConfiguration()
    
    let anchorEntity = AnchorEntity()
    var deviceEntity: Entity?
    
    
    func setup(_ anchors: [ARAnchor]) async throws {
        guard let first = anchors.first as? ARPlaneAnchor else {
            return
        }
        //anchorEntity.transform = Transform(matrix: first.transform)
        
        arDelegate.anchorsAdded = { anchors in }
        
        let startTime = CACurrentMediaTime()
        let entities = try await gltfTest()
        let elapsed = CACurrentMediaTime() - startTime
        print("Import time taken: \(elapsed)")
        
        //let c = AnchorEntity(first)
        
        for entity in entities {
            entity.transform = Transform(matrix: first.transform)
            
            //entity.transform.translation = first.center
            entity.transform.scale = .init(0.3, 0.3, 0.3)
            entity.generateCollisionShapes(recursive: true)
            
            anchorEntity.addChild(entity)
        }
    }
    
    
    var body: some View {
        SysmexView { view in
            arDelegate.arView = view
            
            guard ARWorldTrackingConfiguration.isSupported else {
                print("World tracking is not supported on this device")
                return
            }
            
            arDelegate.anchorsAdded = { anchors in
                Task {
                    do {
                        try await setup(anchors)
                    }
                    catch {
                        print(error)
                    }
                }
            }
            
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                worldTracking.sceneReconstruction = .mesh
            }
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                worldTracking.frameSemantics.insert(.sceneDepth)
            }
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                worldTracking.frameSemantics.insert(.personSegmentationWithDepth)
            }
            
            worldTracking.planeDetection = [.horizontal, .vertical]
            
            arSession.run(worldTracking)
            arSession.delegate = arDelegate
            //view.debugOptions = [.showAnchorOrigins]
            view.session = arSession
            
            view.environment.sceneUnderstanding.options = [.collision, .occlusion]
            view.scene.addAnchor(anchorEntity)
            
        } update: { view in
            //
        }
        .gesture(DragGesture().onChanged { value in
            guard let view = arDelegate.arView else {
                return
            }
            
            let results = view.raycast(from: value.location, allowing: .existingPlaneGeometry, alignment: .horizontal)
            print(results)
            
            if let first = results.first, let rootEntity = anchorEntity.children.first {
                rootEntity.transform.translation = Transform(matrix: first.worldTransform).translation
            }
        })
    }
}

#endif

