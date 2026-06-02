//
//  GLTF.swift
//  DataIO
//
//  Created by Evgenij Lutz on 09.03.25.
//

import Foundation


// MARK: Utilities

public enum GLTFError: Error {
    case notSupported
    case notImplemented
    
    case other(_ message: String)
}


// MARK: JSON value

public enum JSONValue: Codable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    // Decode from any JSON structure
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let val = try? container.decode(Bool.self) {
            self = .bool(val)
        } else if let val = try? container.decode(Double.self) {
            self = .number(val)
        } else if let val = try? container.decode(String.self) {
            self = .string(val)
        } else if let val = try? container.decode([String: JSONValue].self) {
            self = .object(val)
        } else if let val = try? container.decode([JSONValue].self) {
            self = .array(val)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown JSON value")
        }
    }

    // Encode into any JSON structure
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let val):
            try container.encode(val)
        case .number(let val):
            try container.encode(val)
        case .bool(let val):
            try container.encode(val)
        case .object(let val):
            try container.encode(val)
        case .array(let val):
            try container.encode(val)
        case .null:
            try container.encodeNil()
        }
    }
}


// MARK: Extension

/// JSON object with extension-specific objects.
///
/// Additional properties are allowed.
public struct GLTFExtension: Sendable, Codable {
    public var foo: String?
    
    public init(from decoder: any Decoder) throws {
        //
    }
    
    public enum CodingKeys: CodingKey {
        case foo
    }
    
    public func encode(to encoder: any Encoder) throws {
        //var container = encoder.container(keyedBy: CodingKeys.self)
        //try container.encodeIfPresent(self.foo, forKey: .foo)
    }
}


// MARK: Extra

/// Application-specific data.
///
/// Although `extras` **MAY** have any type, it is common for applications to store and access custom data as key/value pairs. Therefore, `extras` **SHOULD** be a JSON object rather than a primitive value for best portability.
public struct GLTFExtra: Sendable, Codable {
    public var foo: String?
}


// MARK: Accessors

public enum GLTFComponentType: Int, Codable, Sendable {
    case byte = 5120
    case unsignedByte = 5121
    case short = 5122
    case unsignedShort = 5123
    case unsignedInt = 5125
    case float = 5126
}


public enum GLTFAccessorType: String, Codable, Sendable {
    case scalar = "SCALAR"
    case vec2 = "VEC2"
    case vec3 = "VEC3"
    case vec4 = "VEC4"
    case mat2 = "MAT2"
    case mat3 = "MAT3"
    case mat4 = "MAT4"
}


public enum GLTFAccessorSparseIndexComponentType: Int, Codable, Sendable {
    case unsignedByte = 5121
    case unsignedShort = 5123
    case unsignedInt = 5125
}


/// An object pointing to a buffer view containing the indices of deviating accessor values. The number of indices is equal to `accessor.sparse.count`. Indices **MUST** strictly increase.
public struct GLTFAccessorSparseIndices: Sendable, Codable {
    /// The index of the buffer view with sparse indices.
    ///
    /// The referenced buffer view **MUST NOT** have its `target` or `byteStride` properties defined. The buffer view and the optional `byteOffset` **MUST** be aligned to the `componentType` byte length.
    public var bufferView: Int
    
    
    /// The offset relative to the start of the buffer view in bytes.
    public var byteOffset: Int?
    
    
    /// The indices data type.
    public var componentType: GLTFAccessorSparseIndexComponentType
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(bufferView: Int, byteOffset: Int? = nil, componentType: GLTFAccessorSparseIndexComponentType, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.bufferView = bufferView
        self.byteOffset = byteOffset
        self.componentType = componentType
        self.extensions = extensions
        self.extras = extras
    }
}


/// An object pointing to a buffer view containing the deviating accessor values.
///
/// The number of elements is equal to `accessor.sparse.count` times number of components. The elements have the same component type as the base accessor. The elements are tightly packed. Data **MUST** be aligned following the same rules as the base accessor.
public struct GLTFAccessorSparseValues: Sendable, Codable {
    /// The index of the bufferView with sparse values.
    ///
    /// The referenced buffer view **MUST NOT** have its `target` or `byteStride` properties defined.
    public var bufferView: Int
    
    
    /// The offset relative to the start of the buffer view in bytes.
    public var byteOffset: Int?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(bufferView: Int, byteOffset: Int? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.bufferView = bufferView
        self.byteOffset = byteOffset
        self.extensions = extensions
        self.extras = extras
    }
}


/// Sparse storage of accessor values that deviate from their initialization value.
public struct GLTFAccessorSparse: Sendable, Codable {
    /// Number of deviating accessor values stored in the sparse array.
    public var count: Int
    
    
    /// An object pointing to a buffer view containing the indices of deviating accessor values. The number of indices is equal to `count`. Indices **MUST** strictly increase.
    public var indices: GLTFAccessorSparseIndices
    
    
    /// An object pointing to a buffer view containing the deviating accessor values.
    public var values: GLTFAccessorSparseValues
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(count: Int, indices: GLTFAccessorSparseIndices, values: GLTFAccessorSparseValues, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.count = count
        self.indices = indices
        self.values = values
        self.extensions = extensions
        self.extras = extras
    }
}


/// A typed view into a buffer view that contains raw binary data.
public struct GLTFAccessor: Sendable, Codable {
    /// The index of the buffer view.
    ///
    /// When undefined, the accessor **MUST** be initialized with zeros; sparse property or extensions **MAY** override zeros with actual values.
    public var bufferView: Int
    
    
    /// The offset relative to the start of the buffer view in bytes.
    ///
    /// This **MUST** be a multiple of the size of the component datatype. This property **MUST NOT** be defined when bufferView is undefined.
    public var byteOffset: Int? // = 0
    
    
    /// The datatype of the accessor’s components.
    ///
    /// `unsignedInt` type **MUST NOT** be used for any accessor that is not referenced by `mesh.primitive.indices`.
    public var componentType: GLTFComponentType
    
    
    /// Specifies whether integer data values are normalized (true) to `[0, 1] (for unsigned types)` or to `[-1, 1] (for signed types)` when they are accessed.
    ///
    /// This property **MUST NOT** be set to true for accessors with `float` or `unsignedInt` component type.
    public var normalized: Bool? // = false
    
    
    /// The number of elements referenced by this accessor, not to be confused with the number of bytes or number of components.
    public var count: Int
    
    
    /// Specifies if the accessor’s elements are scalars, vectors, or matrices.
    public var type: GLTFAccessorType
    
    
    /// Maximum value of each component in this accessor.
    ///
    /// Array elements **MUST** be treated as having the same data type as accessor’s `componentType`. Both `min` and `max` arrays have the same length. The length is determined by the value of the type property; it can be 1, 2, 3, 4, 9, or 16.
    ///
    /// `normalized` property has no effect on array values: they always correspond to the actual values stored in the buffer. When the accessor is sparse, this property **MUST** contain maximum values of accessor data with sparse substitution applied.
    public var max: [Float]?
    
    
    /// Minimum value of each component in this accessor.
    ///
    /// Array elements **MUST** be treated as having the same data type as accessor’s `componentType`. Both `min` and `max` arrays have the same length. The length is determined by the value of the type property; it can be 1, 2, 3, 4, 9, or 16.
    ///
    /// `normalized` property has no effect on array values: they always correspond to the actual values stored in the buffer. When the accessor is sparse, this property **MUST** contain minimum values of accessor data with sparse substitution applied.
    public var min: [Float]?
    
    
    /// Sparse storage of elements that deviate from their initialization value.
    public var sparse: GLTFAccessorSparse?
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(bufferView: Int, byteOffset: Int? = nil, componentType: GLTFComponentType, normalized: Bool? = nil, count: Int, type: GLTFAccessorType, max: [Float]? = nil, min: [Float]? = nil, sparse: GLTFAccessorSparse? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.bufferView = bufferView
        self.byteOffset = byteOffset
        self.componentType = componentType
        self.normalized = normalized
        self.count = count
        self.type = type
        self.max = max
        self.min = min
        self.sparse = sparse
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Animaitons

public enum GLTFTargetPath: String, Codable, Sendable {
    case translation = "translation"
    case rotation = "rotation"
    case scale = "scale"
    case weights = "weights"
}


/// Animation Channel Target
///
/// The descriptor of the animated property.
///
/// - Seealso: [Animation Channel Target](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-animation-channel-target)
public struct GLTFChannelTarget: Sendable, Codable {
    /// The index of the node to animate.
    ///
    /// When undefined, the animated object **MAY** be defined by an extension.
    public var node: Int?
    
    
    /// The name of the node’s TRS property to animate, or the `"weights"` of the Morph Targets it instantiates.
    ///
    /// For the `"translation"` property, the values that are provided by the sampler are the translation along the X, Y, and Z axes.
    ///
    /// For the `"rotation"` property, the values are a quaternion in the order (x, y, z, w), where w is the scalar.
    ///
    /// For the `"scale"` property, the values are the scaling factors along the X, Y, and Z axes.
    public var path: GLTFTargetPath
    
    
    public init(node: Int? = nil, path: GLTFTargetPath) {
        self.node = node
        self.path = path
    }
}


/// Animation Channel
///
/// An animation channel combines an animation sampler with a target property being animated.
///
/// - Seealso: [Animation Channel](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-animation-channel)
public struct GLTFChannel: Sendable, Codable {
    /// The index of a sampler in this animation used to compute the value for the target, e.g., a node’s translation, rotation, or scale (TRS).
    public var sampler: Int
    
    
    /// The descriptor of the animated property.
    public var target: GLTFChannelTarget
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(sampler: Int, target: GLTFChannelTarget, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.sampler = sampler
        self.target = target
        self.extensions = extensions
        self.extras = extras
    }
}


/// Interpolation algorithm.
public enum GLTFInterpolation: String, Codable, Sendable {
    /// The animated values remain constant to the output of the first keyframe, until the next keyframe. The number of output elements **MUST** equal the number of input elements.
    case step = "STEP"
    
    /// The animated values are linearly interpolated between keyframes. When targeting a rotation, spherical linear interpolation (slerp) **SHOULD** be used to interpolate quaternions. The number of output elements **MUST** equal the number of input elements.
    case linear = "LINEAR"
    
    /// The animation’s interpolation is computed using a cubic spline with specified tangents. The number of output elements **MUST** equal three times the number of input elements. For each input element, the output stores three elements, an in-tangent, a spline vertex, and an out-tangent. There **MUST** be at least two keyframes when using this interpolation.
    case cubicSpline = "CUBICSPLINE"
}


/// Animation Sampler
///
/// An animation sampler combines timestamps with a sequence of output values and defines an interpolation algorithm.
/// - Seealso: [Animation Sampler](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-animation-sampler)
public struct GLTFAnimationSampler: Sendable, Codable {
    /// The index of an accessor containing keyframe timestamps.
    ///
    /// The accessor **MUST** be of scalar type with floating-point components. The values represent time in seconds `with time[0] >= 0.0`, and strictly increasing values, i.e., `time[n + 1] > time[n]`.
    public var input: Int
    
    
    /// Interpolation algorithm.
    public var interpolation: GLTFInterpolation? // = .linear
    
    
    /// The index of an accessor, containing keyframe output values.
    public var output: Int
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(input: Int, interpolation: GLTFInterpolation? = nil, output: Int, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.input = input
        self.interpolation = interpolation
        self.output = output
        self.extensions = extensions
        self.extras = extras
    }
}


/// A keyframe animation.
///
/// - Seealso: [Animation](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-animation)
public struct GLTFAnimation: Sendable, Codable {
    /// An array of animation channels.
    ///
    /// An animation channel combines an animation sampler with a target property being animated. Different channels of the same animation **MUST NOT** have the same targets.
    public var channels: [GLTFChannel]
    
    
    /// An array of animation samplers.
    ///
    /// An animation sampler combines timestamps with a sequence of output values and defines an interpolation algorithm.
    public var samplers: [GLTFAnimationSampler]
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(channels: [GLTFChannel], samplers: [GLTFAnimationSampler], name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.channels = channels
        self.samplers = samplers
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Asset

/// Metadata about the glTF asset.
public struct GLTFAsset: Sendable, Codable {
    /// A copyright message suitable for display to credit the content creator.
    public var copyright: String?
    
    
    /// Tool that generated this glTF model. Useful for debugging.
    public var generator: String?
    
    
    /// The glTF version in the form of `<major>.<minor>` that this asset targets.
    public var version: String
    
    
    /// The minimum glTF version in the form of `<major>.<minor>` that this asset targets. This property **MUST NOT** be greater than the asset version.
    public var minVersion: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(copyright: String? = nil, generator: String? = nil, version: String, minVersion: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.copyright = copyright
        self.generator = generator
        self.version = version
        self.minVersion = minVersion
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Buffers

/// Buffer
///
/// A buffer points to binary geometry, animation, or skins.
///
/// - Seealso: [Buffer](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-buffer)
public struct GLTFBuffer: Sendable, Codable {
    /// The URI (or IRI) of the buffer. Relative paths are relative to the current glTF asset. Instead of referencing an external file, this field **MAY** contain a `data:-URI`.
    public var uri: String?
    
    
    /// The length of the buffer in bytes.
    public var byteLength: Int
    
    
    /// The user-defined name of this object. This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(uri: String? = nil, byteLength: Int, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.uri = uri
        self.byteLength = byteLength
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Buffer views

/// The hint representing the intended GPU buffer type to use with this buffer view.
public enum GLTFBufferViewTarget: Int, Codable, Sendable {
    case arrayBuffer = 34962
    case elementArrayBuffer = 34963
}


/// Buffer View
///
/// A view into a buffer generally representing a subset of the buffer.
///
/// - Seealso: [Buffer View](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-bufferview)
public struct GLTFBufferView: Sendable, Codable {
    /// The index of the buffer.
    public var buffer: Int
    
    
    /// The offset into the buffer in bytes.
    public var byteOffset: Int? // = 0
    
    
    /// The offset into the buffer in bytes.
    public var byteLength: Int
    
    
    /// The stride, in bytes, between vertex attributes.
    ///
    /// When this is not defined, data is tightly packed. When two or more accessors use the same buffer view, this field **MUST** be defined.
    public var byteStride: Int?
    
    
    /// The hint representing the intended GPU buffer type to use with this buffer view.
    public var target: GLTFBufferViewTarget?
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(buffer: Int, byteOffset: Int? = nil, byteLength: Int, byteStride: Int? = nil, target: GLTFBufferViewTarget? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.buffer = buffer
        self.byteOffset = byteOffset
        self.byteLength = byteLength
        self.byteStride = byteStride
        self.target = target
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Cameras

public enum GLTFCameraType: String, Codable, Sendable {
    case perspective
    case orthographic
}


/// Camera Orthographic
///
/// An orthographic camera containing properties to create an orthographic projection matrix.
///
/// - Seealso: [Camera Orthographic](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-camera-orthographic)
public struct GLTFOrthographicCamera: Sendable, Codable {
    /// The floating-point horizontal magnification of the view.
    ///
    /// This value **MUST NOT** be equal to zero. This value **SHOULD NOT** be negative.
    public var xmag: Float
    
    
    /// The floating-point vertical magnification of the view.
    ///
    /// This value **MUST NOT** be equal to zero. This value **SHOULD NOT** be negative.
    public var ymag: Float
    
    
    /// The floating-point distance to the far clipping plane.
    ///
    /// This value **MUST NOT** be equal to zero. zfar **MUST** be greater than znear.
    public var zfar: Float
    
    
    /// The floating-point distance to the near clipping plane.
    public var znear: Float
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(xmag: Float, ymag: Float, zfar: Float, znear: Float, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.xmag = xmag
        self.ymag = ymag
        self.zfar = zfar
        self.znear = znear
        self.extensions = extensions
        self.extras = extras
    }
}


/// Camera Perspective
///
/// A perspective camera containing properties to create a perspective projection matrix.
///
/// - Seealso: [Camera Perspective](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-camera-perspective)
public struct GLTFPerspectiveCamera: Sendable, Codable {
    /// The floating-point aspect ratio of the field of view.
    ///
    /// When undefined, the aspect ratio of the rendering viewport **MUST** be used.
    public var aspectRatio: Float?
    
    
    /// The floating-point vertical field of view in radians.
    ///
    /// This value **SHOULD** be less than π.
    public var yfov: Float
    
    
    /// The floating-point distance to the far clipping plane.
    ///
    /// When defined, zfar **MUST** be greater than znear. If zfar is undefined, client implementations **SHOULD** use infinite projection matrix.
    public var zfar: Float
    
    
    /// The floating-point distance to the near clipping plane.
    public var znear: Float
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(aspectRatio: Float? = nil, yfov: Float, zfar: Float, znear: Float, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.aspectRatio = aspectRatio
        self.yfov = yfov
        self.zfar = zfar
        self.znear = znear
        self.extensions = extensions
        self.extras = extras
    }
}


/// Camera
///
/// A camera’s projection. A node **MAY** reference a camera to apply a transform to place the camera in the scene.
///
/// - Seealso: [Camera](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-camera)
public struct GLTFCamera: Sendable, Codable {
    /// An orthographic camera containing properties to create an orthographic projection matrix.
    ///
    /// This property **MUST NOT** be defined when perspective is defined.
    public var orthographic: GLTFOrthographicCamera?
    
    
    /// A perspective camera containing properties to create a perspective projection matrix.
    ///
    /// This property **MUST NOT** be defined when orthographic is defined.
    public var perspective: GLTFPerspectiveCamera?
    
    
    /// Specifies if the camera uses a perspective or orthographic projection.
    ///
    /// Based on this, either the camera’s perspective or orthographic property **MUST** be defined.
    public var type: GLTFCameraType
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(orthographic: GLTFOrthographicCamera? = nil, perspective: GLTFPerspectiveCamera? = nil, type: GLTFCameraType, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.orthographic = orthographic
        self.perspective = perspective
        self.type = type
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Images

/// Image data used to create a texture.
///
/// Image **MAY** be referenced by an URI (or IRI) or a buffer view index.
public struct GLTFImage: Sendable, Codable {
    /// The URI (or IRI) of the image.
    ///
    /// Relative paths are relative to the current glTF asset. Instead of referencing an external file, this field **MAY** contain a `data:-URI`. This field **MUST NOT** be defined when `bufferView` is defined.
    public var uri: String?
    
    
    /// The image’s media type.
    ///
    /// This field **MUST** be defined when bufferView is defined.
    ///
    /// Allowed values:
    /// - `"image/jpeg"`
    /// - `"image/png"`
    public var mimeType: String?
    
    
    /// The index of the bufferView that contains the image.
    ///
    /// This field **MUST NOT** be defined when uri is defined.
    public var bufferView: Int?
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(uri: String? = nil, mimeType: String? = nil, bufferView: Int? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.uri = uri
        self.mimeType = mimeType
        self.bufferView = bufferView
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Materials

/// Texture Info
///
/// Reference to a texture.
///
/// - Seealso: [Texture Info](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-textureinfo)
public struct GLTFTextureInfo: Sendable, Codable {
    /// The index of the texture.
    public var index: Int
    
    
    /// This integer value is used to construct a string in the format `TEXCOORD_<set index>` which is a reference to a key in `mesh.primitives.attributes` (e.g. a value of 0 corresponds to `TEXCOORD_0`). A mesh primitive **MUST** have the corresponding texture coordinate attributes for the material to be applicable to it.
    public var texCoord: Int? // = 0
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(index: Int, texCoord: Int? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.index = index
        self.texCoord = texCoord
        self.extensions = extensions
        self.extras = extras
    }
}


/// Material PBR Metallic Roughness
///
/// A set of parameter values that are used to define the metallic-roughness material model from Physically-Based Rendering (PBR) methodology.
///
/// - Seealso: [Material PBR Metallic Roughness](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-material-pbrmetallicroughness)
public struct GLTFMaterialPBRMetallicRoughness: Sendable, Codable {
    /// The factors for the base color of the material.
    ///
    /// This value defines linear multipliers for the sampled texels of the base color texture.
    ///
    /// Each element in the array **MUST** be greater than or equal to 0 and less than or equal to 1.
    public var baseColorFactor: [Float]? // = [1,1,1,1]
    
    
    /// The base color texture.
    ///
    /// The first three components (RGB) **MUST** be encoded with the sRGB transfer function. They specify the base color of the material. If the fourth component (A) is present, it represents the linear alpha coverage of the material. Otherwise, the alpha coverage is equal to 1.0. The `material.alphaMode` property specifies how alpha is interpreted. The stored texels **MUST NOT** be premultiplied. When undefined, the texture **MUST** be sampled as having 1.0 in all components.
    public var baseColorTexture: GLTFTextureInfo?
    
    
    /// The factor for the metalness of the material.
    ///
    /// This value defines a linear multiplier for the sampled metalness values of the metallic-roughness texture.
    public var metallicFactor: Float? // = 1
    
    
    /// The factor for the roughness of the material.
    ///
    /// This value defines a linear multiplier for the sampled roughness values of the metallic-roughness texture.
    public var roughnessFactor: Float? // = 1
    
    
    /// The metallic-roughness texture.
    ///
    /// The metalness values are sampled from the B channel. The roughness values are sampled from the G channel. These values **MUST** be encoded with a linear transfer function. If other channels are present (R or A), they **MUST** be ignored for metallic-roughness calculations. When undefined, the texture **MUST** be sampled as having `1.0` in G and B components.
    public var metallicRoughnessTexture: GLTFTextureInfo?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(baseColorFactor: [Float]? = nil, baseColorTexture: GLTFTextureInfo? = nil, metallicFactor: Float? = nil, roughnessFactor: Float? = nil, metallicRoughnessTexture: GLTFTextureInfo? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.baseColorFactor = baseColorFactor
        self.baseColorTexture = baseColorTexture
        self.metallicFactor = metallicFactor
        self.roughnessFactor = roughnessFactor
        self.metallicRoughnessTexture = metallicRoughnessTexture
        self.extensions = extensions
        self.extras = extras
    }
}


/// Material Normal Texture Info
///
/// Reference to a texture.
///
/// - Seealso: [Material Normal Texture Info](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-material-normaltextureinfo)
public struct GLTFNormalTextureInfo: Sendable, Codable {
    /// The index of the texture.
    public var index: Int
    
    
    /// This integer value is used to construct a string in the format `TEXCOORD_<set index>` which is a reference to a key in `mesh.primitives.attributes` (e.g. a value of 0 corresponds to `TEXCOORD_0`). A mesh primitive **MUST** have the corresponding texture coordinate attributes for the material to be applicable to it.
    public var texCoord: Int? // = 0
    
    
    /// The scalar parameter applied to each normal vector of the texture.
    ///
    /// This value scales the normal vector in X and Y directions using the formula: `scaledNormal = normalize<sampled normal texture value> * 2.0 - 1.0) * vec3(<normal scale>, <normal scale>, 1.0`.
    public var scale: Int? // = 1
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(index: Int, texCoord: Int? = nil, scale: Int? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.index = index
        self.texCoord = texCoord
        self.scale = scale
        self.extensions = extensions
        self.extras = extras
    }
}


/// Material Occlusion Texture Info
///
/// Reference to a texture.
///
/// - Seealso: [Material Occlusion Texture Info](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-material-occlusiontextureinfo)
public struct GLTFOcclusionTextureInfo: Sendable, Codable {
    /// The index of the texture.
    public var index: Int
    
    
    /// This integer value is used to construct a string in the format `TEXCOORD_<set index>` which is a reference to a key in `mesh.primitives.attributes` (e.g. a value of 0 corresponds to `TEXCOORD_0`). A mesh primitive **MUST** have the corresponding texture coordinate attributes for the material to be applicable to it.
    public var texCoord: Int? // = 0
    
    
    /// A scalar parameter controlling the amount of occlusion applied.
    ///
    /// A value of `0.0` means no occlusion. A value of `1.0` means full occlusion. This value affects the final occlusion value as: `1.0 + strength * (<sampled occlusion texture value> - 1.0)`.
    public var strength: Int? // = 1
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(index: Int, texCoord: Int? = nil, strength: Int? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.index = index
        self.texCoord = texCoord
        self.strength = strength
        self.extensions = extensions
        self.extras = extras
    }
}


public enum GLTFMaterialAlphaMode: String, Codable, Sendable {
    /// The alpha value is ignored, and the rendered output is fully opaque.
    case opaque = "OPAQUE"
    
    
    /// The rendered output is either fully opaque or fully transparent depending on the alpha value and the specified alphaCutoff value; the exact appearance of the edges **MAY** be subject to implementation-specific techniques such as “Alpha-to-Coverage”.
    case mask = "MASK"
    
    
    /// The alpha value is used to composite the source and destination areas. The rendered output is combined with the background using the normal painting operation (i.e. the Porter and Duff over operator).
    case blend = "BLEND"
}


/// Material
///
/// The material appearance of a primitive.
///
/// - Seealso: [Material](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-material)
public struct GLTFMaterial: Sendable, Codable {
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    /// A set of parameter values that are used to define the metallic-roughness material model from Physically Based Rendering (PBR) methodology.
    ///
    /// When undefined, all the default values of `pbrMetallicRoughness` **MUST** apply.
    public var pbrMetallicRoughness: GLTFMaterialPBRMetallicRoughness?
    
    
    /// A set of parameter values that are used to define the metallic-roughness material model from Physically Based Rendering (PBR) methodology.
    ///
    /// When undefined, all the default values of pbrMetallicRoughness **MUST** apply.
    public var normalTexture: GLTFNormalTextureInfo?
    
    
    /// The occlusion texture.
    ///
    /// The occlusion values are linearly sampled from the R channel. Higher values indicate areas that receive full indirect lighting and lower values indicate no indirect lighting. If other channels are present (GBA), they **MUST** be ignored for occlusion calculations. When undefined, the material does not have an occlusion texture.
    public var occlusionTexture: GLTFOcclusionTextureInfo?
    
    
    /// The emissive texture.
    ///
    /// It controls the color and intensity of the light being emitted by the material. This texture contains RGB components encoded with the sRGB transfer function. If a fourth component (A) is present, it **MUST** be ignored. When undefined, the texture **MUST** be sampled as having 1.0 in RGB components.
    public var emissiveTexture: GLTFTextureInfo?
    
    
    /// The factors for the emissive color of the material.
    ///
    /// This value defines linear multipliers for the sampled texels of the emissive texture. Each element in the array **MUST** be greater than or equal to 0 and less than or equal to 1.
    public var emissiveFactor: [Float]? // = [0,0,0]
    
    
    /// The material’s alpha rendering mode enumeration specifying the interpretation of the alpha value of the base color.
    public var alphaMode: GLTFMaterialAlphaMode? // = .opaque
    
    
    /// Specifies the cutoff threshold when in MASK alpha mode.
    ///
    /// If the alpha value is greater than or equal to this value then it is rendered as fully opaque, otherwise, it is rendered as fully transparent. A value greater than 1.0 will render the entire material as fully transparent. This value **MUST** be ignored for other alpha modes. When alphaMode is not defined, this value **MUST NOT** be defined.
    public var alphaCutoff: Float? // = 0.5
    
    
    /// Specifies whether the material is double sided.
    ///
    /// When this value is false, back-face culling is enabled. When this value is true, back-face culling is disabled and double-sided lighting is enabled. The back-face **MUST** have its normals reversed before the lighting equation is evaluated.
    public var doubleSided: Bool? // = false
    
    
    public init(name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil, pbrMetallicRoughness: GLTFMaterialPBRMetallicRoughness? = nil, normalTexture: GLTFNormalTextureInfo? = nil, occlusionTexture: GLTFOcclusionTextureInfo? = nil, emissiveTexture: GLTFTextureInfo? = nil, emissiveFactor: [Float]? = nil, alphaMode: GLTFMaterialAlphaMode? = nil, alphaCutoff: Float? = nil, doubleSided: Bool? = nil) {
        self.name = name
        self.extensions = extensions
        self.extras = extras
        self.pbrMetallicRoughness = pbrMetallicRoughness
        self.normalTexture = normalTexture
        self.occlusionTexture = occlusionTexture
        self.emissiveTexture = emissiveTexture
        self.emissiveFactor = emissiveFactor
        self.alphaMode = alphaMode
        self.alphaCutoff = alphaCutoff
        self.doubleSided = doubleSided
    }
}


// MARK: Meshes

public enum GLTFMeshPrimitiveTopologyMode: Int, Codable, Sendable {
    case points = 0
    case lines = 1
    case lineLoop = 2
    case lineStrip = 3
    case triangles = 4
    case triangleStrip = 5
    case triangleFan = 6
}

/// Mesh Primitive
///
/// - Seealso: [Mesh Primitive](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-mesh-primitive)
public struct GLTFMeshPrimitive: Sendable, Codable {
    //struct GLTFAttributes: Sendable, Codable {
    //    // TODO : This should be a plain json object. Anything below a result of observation of some gltf files
    //    public var JOINTS_0: Int?
    //    public var NORMAL: Int?
    //    public var POSITION: Int?
    //    public var TANGENT: Int?
    //    public var TEXCOORD_0: Int?
    //    public var WEIGHTS_0: Int?
    //}
    //var attributes: GLTFAttributes?
    
    
    /// A plain JSON object, where each key corresponds to a mesh attribute semantic and each value is the index of the accessor containing attribute’s data.
    public var attributes: [String : Int]
    
    
    /// The index of the accessor that contains the vertex indices.
    ///
    /// When this is undefined, the primitive defines non-indexed geometry. When defined, the accessor **MUST** have SCALAR type and an unsigned integer component type.
    public var indices: Int?
    
    
    /// The index of the material to apply to this primitive when rendering.
    public var material: Int?
    
    
    /// The topology type of primitives to render.
    public var mode: GLTFMeshPrimitiveTopologyMode? // = .triangles
    
    
    // TODO: Check if it's okay to use dictionary as a json object just like attributes
    // /// An array of morph targets.
    // var targets: [String : Int]?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(attributes: [String : Int], indices: Int? = nil, material: Int? = nil, mode: GLTFMeshPrimitiveTopologyMode? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.attributes = attributes
        self.indices = indices
        self.material = material
        self.mode = mode
        self.extensions = extensions
        self.extras = extras
    }
}

/// Mesh
///
/// A set of primitives to be rendered. Its global transform is defined by a node that references it.
///
/// - Seealso: [Mesh](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-mesh)
public struct GLTFMesh: Sendable, Codable {
    /// An array of primitives, each defining geometry to be rendered.
    public var primitives: [GLTFMeshPrimitive]
    
    
    /// Array of weights to be applied to the morph targets.
    ///
    /// The number of array elements **MUST** match the number of morph targets.
    public var weights: [Float]?
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(primitives: [GLTFMeshPrimitive], weights: [Float]? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.primitives = primitives
        self.weights = weights
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Nodes

/// Node
///
/// A node in the node hierarchy. When the node contains `skin`, all `mesh.primitives` **MUST** contain `JOINTS_0` and `WEIGHTS_0` attributes. A node **MAY** have either a `matrix` or any combination of `translation/rotation/scale` (TRS) properties. TRS properties are converted to matrices and postmultiplied in the `T * R * S` order to compose the transformation matrix; first the scale is applied to the vertices, then the rotation, and then the translation. If none are provided, the transform is the identity. When a node is targeted for animation (referenced by an animation.channel.target), `matrix` **MUST NOT** be present.
///
/// - Seealso: [Node](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-node)
public struct GLTFNode: Sendable, Codable {
    /// The index of the camera referenced by this node.
    public var camera: Int?
    
    
    /// The indices of this node’s children.
    ///
    /// - Each element in the array **MUST** be unique.
    /// - Each element in the array **MUST** be greater than or equal to 0.
    public var children: [Int]?
    
    
    /// The index of the skin referenced by this node.
    ///
    /// When a skin is referenced by a node within a scene, all joints used by the skin **MUST** belong to the same scene. When defined, mesh **MUST** also be defined.
    public var skin: Int?
    
    
    /// A floating-point 4x4 transformation matrix stored in column-major order.
    public var matrix: [Float]? // = [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]
    
    
    /// The index of the mesh in this node.
    public var mesh: Int?
    
    
    /// The node’s unit quaternion rotation in the order (x, y, z, w), where w is the scalar.
    public var rotation: [Float]? // = [0,0,0,1]
    
    
    /// The node’s non-uniform scale, given as the scaling factors along the x, y, and z axes.
    public var scale: [Float]? // = [1,1,1]
    
    
    /// The node’s translation along the x, y, and z axes.
    public var translation: [Float]? // = [0,0,0]
    
    
    /// The weights of the instantiated morph target.
    ///
    /// The number of array elements **MUST** match the number of morph targets of the referenced mesh. When defined, mesh **MUST** also be defined.
    public var weights: [Float]?
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(camera: Int? = nil, children: [Int]? = nil, skin: Int? = nil, matrix: [Float]? = nil, mesh: Int? = nil, rotation: [Float]? = nil, scale: [Float]? = nil, translation: [Float]? = nil, weights: [Float]? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.camera = camera
        self.children = children
        self.skin = skin
        self.matrix = matrix
        self.mesh = mesh
        self.rotation = rotation
        self.scale = scale
        self.translation = translation
        self.weights = weights
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Samplers

public enum GLTFTextureMagFilterMode: Int, Codable, Sendable {
    case nearest = 9728
    case linear = 9729
}

public enum GLTFTextureMinFilterMode: Int, Codable, Sendable {
    case nearest = 9728
    case linear = 9729
    case nearestMipmapNearest = 9984
    case linearMipmapNearest = 9985
    case nearestMipmapLinear = 9986
    case linearMipmapLinear = 9987
}

public enum GLTFTextureWrapMode: Int, Codable, Sendable {
    case clampToEdge = 33071
    case mirroredRepeat = 33648
    case repeatPattern = 10497
}


/// Sampler
///
/// Texture sampler properties for filtering and wrapping modes.
///
/// - Seealso: [Sampler](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-sampler)
public struct GLTFSampler: Sendable, Codable {
    /// Magnification filter.
    public var magFilter: GLTFTextureMagFilterMode?
    
    
    /// Minification filter.
    public var minFilter: GLTFTextureMinFilterMode?
    
    
    /// S (U) wrapping mode.
    ///
    /// All valid values correspond to WebGL enums.
    public var wrapS: GLTFTextureWrapMode? // = .repeatPattern
    
    
    /// T (V) wrapping mode.
    public var wrapT: GLTFTextureWrapMode? // = .repeatPattern
    
    
    /// The user-defined name of this object.
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(magFilter: GLTFTextureMagFilterMode? = nil, minFilter: GLTFTextureMinFilterMode? = nil, wrapS: GLTFTextureWrapMode? = nil, wrapT: GLTFTextureWrapMode? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.magFilter = magFilter
        self.minFilter = minFilter
        self.wrapS = wrapS
        self.wrapT = wrapT
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Scenes

/// Scene
///
/// The root nodes of a scene.
///
/// - Seealso: [Scene](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-scene)
public struct GLTFScene: Sendable, Codable {
    /// The indices of each root node.
    ///
    /// - Each element in the array **MUST** be unique.
    /// - Each element in the array **MUST** be greater than or equal to 0.
    public var nodes: [Int]?
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(nodes: [Int]? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.nodes = nodes
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Skins

/// Skin
///
/// Joints and matrices defining a skin.
///
/// - Seealso: [Skin](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-skin)
public struct GLTFSkin: Sendable, Codable {
    /// The index of the accessor containing the floating-point 4x4 inverse-bind matrices.
    ///
    /// Its `accessor.count` property **MUST** be greater than or equal to the number of elements of the `joints` array. When undefined, each matrix is a 4x4 identity matrix.
    public var inverseBindMatrices: Int?
    
    
    /// The index of the node used as a skeleton root.
    ///
    /// The node **MUST** be the closest common root of the joints hierarchy or a direct or indirect parent node of the closest common root.
    public var skeleton: Int?
    
    
    /// Indices of skeleton nodes, used as joints in this skin.
    ///
    /// - Each element in the array **MUST** be unique.
    /// - Each element in the array **MUST** be greater than or equal to 0.
    public var joints: [Int]
    
    
    /// The user-defined name of this object.
    ///
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(inverseBindMatrices: Int? = nil, skeleton: Int? = nil, joints: [Int], name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.inverseBindMatrices = inverseBindMatrices
        self.skeleton = skeleton
        self.joints = joints
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: Textures

/// Texture
///
/// A texture and its sampler.
///
/// - Seealso: [Texture](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-texture)
public struct GLTFTexture: Sendable, Codable {
    /// The index of the sampler used by this texture.
    ///
    /// When undefined, a sampler with repeat wrapping and auto filtering **SHOULD** be used.
    public var sampler: Int?
    
    
    /// The index of the image used by this texture.
    /// When undefined, an extension or other mechanism **SHOULD** supply an alternate texture source, otherwise behavior is undefined.
    public var source: Int?
    
    
    /// The user-defined name of this object.
    /// This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
    public var name: String?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(sampler: Int? = nil, source: Int? = nil, name: String? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.sampler = sampler
        self.source = source
        self.name = name
        self.extensions = extensions
        self.extras = extras
    }
}


// MARK: GLTF

/// The root object for a glTF asset.
///
/// - Seealso: [glTF](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#reference-gltf)
public struct GLTF: Sendable, Codable {
    /// Names of glTF extensions used in this asset.
    ///
    /// Each element in the array **MUST** be unique.
    public var extensionsUsed: [String]?
    
    
    /// Names of glTF extensions required to properly load this asset.
    ///
    /// Each element in the array **MUST** be unique.
    public var extensionsRequired: [String]?
    
    
    /// An array of accessors. An accessor is a typed view into a bufferView.
    public var accessors: [GLTFAccessor]?
    
    
    /// An array of keyframe animations.
    public var animations: [GLTFAnimation]?
    
    
    /// Metadata about the glTF asset.
    public var asset: GLTFAsset
    
    
    /// An array of buffers.
    ///
    /// A buffer points to binary geometry, animation, or skins.
    public var buffers: [GLTFBuffer]?
    
    
    /// An array of bufferViews.
    ///
    /// A bufferView is a view into a buffer generally representing a subset of the buffer.
    public var bufferViews: [GLTFBufferView]?
    
    
    /// An array of cameras.
    ///
    /// A camera defines a projection matrix.
    public var cameras: [GLTFCamera]?
    
    
    /// An array of images.
    ///
    /// An image defines data used to create a texture.
    public var images: [GLTFImage]?
    
    
    /// An array of materials.
    ///
    /// A material defines the appearance of a primitive.
    public var materials: [GLTFMaterial]?
    
    
    /// An array of meshes.
    ///
    /// A mesh is a set of primitives to be rendered.
    public var meshes: [GLTFMesh]?
    
    
    /// An array of nodes.
    public var nodes: [GLTFNode]?
    
    
    /// An array of samplers.
    /// A sampler contains properties for texture filtering and wrapping modes.
    public var samplers: [GLTFSampler]?
    
    
    /// The index of the default scene.
    ///
    /// This property **MUST NOT** be defined, when scenes is undefined.
    public var scene: Int?
    
    
    /// An array of scenes.
    public var scenes: [GLTFScene]?
    
    
    /// An array of skins.
    ///
    /// A skin is defined by joints and matrices.
    public var skins: [GLTFSkin]?
    
    
    /// An array of textures.
    public var textures: [GLTFTexture]?
    
    
    /// JSON object with extension-specific objects.
    public var extensions: JSONValue?
    
    
    /// Application-specific data.
    public var extras: JSONValue?
    
    
    public init(extensionsUsed: [String]? = nil, extensionsRequired: [String]? = nil, accessors: [GLTFAccessor]? = nil, animations: [GLTFAnimation]? = nil, asset: GLTFAsset, buffers: [GLTFBuffer]? = nil, bufferViews: [GLTFBufferView]? = nil, cameras: [GLTFCamera]? = nil, images: [GLTFImage]? = nil, materials: [GLTFMaterial]? = nil, meshes: [GLTFMesh]? = nil, nodes: [GLTFNode]? = nil, samplers: [GLTFSampler]? = nil, scene: Int? = nil, scenes: [GLTFScene]? = nil, skins: [GLTFSkin]? = nil, textures: [GLTFTexture]? = nil, extensions: JSONValue? = nil, extras: JSONValue? = nil) {
        self.extensionsUsed = extensionsUsed
        self.extensionsRequired = extensionsRequired
        self.accessors = accessors
        self.animations = animations
        self.asset = asset
        self.buffers = buffers
        self.bufferViews = bufferViews
        self.cameras = cameras
        self.images = images
        self.materials = materials
        self.meshes = meshes
        self.nodes = nodes
        self.samplers = samplers
        self.scene = scene
        self.scenes = scenes
        self.skins = skins
        self.textures = textures
        self.extensions = extensions
        self.extras = extras
    }
    
    
    public static func from(_ url: URL) async throws -> GLTF {
        // Text JSON
        if url.pathExtension.lowercased() == "gltf" {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(GLTF.self, from: data)
        }
        
        // Binary
        // Binary glTF Layout:
        // https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#binary-gltf-layout
        
        throw GLTFError.notSupported
    }
    
    
    static func from(_ data: Data) async throws -> GLTF {
        try JSONDecoder().decode(GLTF.self, from: data)
    }
}


public struct GLTFData: Sendable {
    public var url: String
    public var data: Data
    
    
    public init(url: String, data: Data) {
        self.url = url
        self.data = data
    }
}


fileprivate extension Data {
    mutating func write<SomeType: BinaryInteger>(_ value: SomeType) {
        withUnsafePointer(to: value) { pointer in
            append(Data(bytes: pointer, count: MemoryLayout<SomeType>.size))
        }
    }
}


//fileprivate struct DataReader {
//    private let data: Data
//    private(set) var offset: Int = 0
//    
//    
//    public init(_ data: Data) {
//        self.data = data
//    }
//    
//    
//    mutating func read<SomeType>() throws -> SomeType {
//        let length = MemoryLayout<SomeType>.size
//        guard length > 0 else {
//            throw GLTFError.other("Strange data size")
//        }
//        
//        let endIndex = offset + length
//        guard offset >= 0 && endIndex <= data.count else {
//            throw GLTFError.other("Index out of range")
//        }
//        
//        let value = try data[data.startIndex.advanced(by: offset) ..< data.startIndex.advanced(by: endIndex)].withUnsafeBytes {
//            guard let value = $0.baseAddress?.loadUnaligned(as: SomeType.self) else {
//                throw GLTFError.other("Unwrap memory error")
//            }
//            
//            return value
//        }
//        
//        offset = endIndex
//        return value
//    }
//    
//    
//    mutating func readData<Integer: BinaryInteger>(ofLength length: Integer) throws -> Data {
//        guard length >= 0 else {
//            throw GLTFError.other("Strange data size")
//        }
//        
//        if length == 0 {
//            return Data()
//        }
//        
//        let endIndex = offset + Int(length)
//        guard offset >= 0 && endIndex <= data.count else {
//            throw GLTFError.other("Index out of range")
//        }
//        
//        let value = data[data.startIndex.advanced(by: offset) ..< data.startIndex.advanced(by: endIndex)]
//        
//        offset = endIndex
//        return value
//    }
//}


extension Data {
    mutating func alignSize(to alignment: Int = 4) {
        let dataLength = count
        if dataLength % alignment != 0 {
            let paddingLength = alignment - (dataLength % alignment)
            append(contentsOf: Array(repeating: 0, count: paddingLength))
        }
    }
}


public func alignValue(_ value: Int, to alignment: Int = 4) -> Int {
    if value % alignment != 0 {
        let padding = alignment - (value % alignment)
        return value + padding
    }
    
    return value
}


public struct GLTFLibrary: Sendable {
    public var gltf: GLTF
    /// Possibly pairs of external data url + their data, for instance image url + image data.
    public var data: [GLTFData] = []
    /// Actually there should be only one chunk of data, according to glTF specification
    public var binaryChunks: [Data] = []
    
    
    public init(gltf: GLTF, data: [GLTFData] = [], binaryChunks: [Data] = []) {
        self.gltf = gltf
        self.data = data
        self.binaryChunks = binaryChunks
    }
    
    
    public static func from(_ url: URL) async throws -> GLTFLibrary {
        let data = try Data(contentsOf: url)
        return try await from(data)
    }
    
    
    public static func from(_ data: Data) async throws -> GLTFLibrary {
        var reader = DataReader(data)
        
        // GLB header
        let magic: UInt32 = try reader.read()
        let version: UInt32 = try reader.read()
        // Total length of the Binary glTF, including header and all chunks, in bytes
        let _: UInt32 = try reader.read()
        
        // Check magic number
        guard magic == 0x46546C67 else {
            throw GLTFError.other("Unknown header magic number")
        }
        
        // Check GLTF version
        guard version == 2 else {
            throw GLTFError.other("Unknown header version: \(version)")
        }
        
        // JSON chunk data
        let jsonChunkLength: UInt32 = try reader.read()
        
        // 0x4E4F534A: Structured JSON content
        // 0x004E4942: Binary buffer
        let jsonChunkType: UInt32 = try reader.read()
        guard jsonChunkType == 0x4E4F534A else {
            throw GLTFError.other("\"Structured JSON content\" chunk type (0x4E4F534A) was expected, received \(jsonChunkType) instead")
        }
        
        let jsonData: Data = try reader.readData(ofLength: jsonChunkLength)
        // Print JSON contents
        //if let string = String(data: jsonData, encoding: .utf8) {
        //    print(string)
        //}
        
        let gltf = try await GLTF.from(jsonData)
        
        var binaryChunks = [Data]()
        
        // Binary chunk data is optional
        func readChunks(_ action: () throws -> Void) throws {
#if false
            // In case if there are more than one binary chunk
            let numBuffers = gltf.buffers?.count ?? 0
            for _ in 0 ..< numBuffers {
                try action()
            }
#else
            // According to the GLB specification, there may be only one binary chunk
            if reader.offset < reader.data.count {
                try action()
            }
#endif
        }
        
        try readChunks {
            let chunkLength: UInt32 = try reader.read()
            
            let chunkType: UInt32 = try reader.read()
            guard chunkType == 0x004E4942 else {
                throw GLTFError.other("\"Binary buffer\" chunk type (0x004E4942) was expected, received \(chunkType) instead")
            }
            
            let chunkData: Data = try reader.readData(ofLength: chunkLength)
            binaryChunks.append(chunkData)
        }
        
        return GLTFLibrary(gltf: gltf, binaryChunks: binaryChunks)
    }
    
    
    /// Export to GLB data
    ///
    /// - Seealso: [Binary glTF Layout](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#binary-gltf-layout)
    public func exportToGLB() async throws -> Data {
        // Binary data
        var binaryData = Data()
        for chunk in binaryChunks {
            // 4 bytes of length
            do {
                let length = UInt32(chunk.count)
                binaryData.write(length)
            }
            
            // 4 bytes of chunk type
            do {
                let chunkType: UInt32 = 0x004E4942
                binaryData.write(chunkType)
            }
            
            // data bytes with length aligned to 4
            do {
                binaryData.append(chunk)
                
                let dataLength = chunk.count
                if dataLength % 4 != 0 {
                    let paddingLength = 4 - (dataLength % 4)
                    binaryData.append(contentsOf: Array(repeating: 0, count: paddingLength))
                }
            }
        }
        
        
        // JSON data
        let jsonData = try JSONEncoder().encode(gltf)
        let jsonDataPadding = alignValue(jsonData.count) - jsonData.count
        
        
        // GLB data
        var glb = Data()
        
        
        // Header
        do {
            // 4 bytes of magic header
            do {
                guard let bytes = "glTF".data(using: .utf8) else {
                    throw GLTFError.other("Cannot convert the \"glTF\" string to UTF-8 data")
                }
                
                guard bytes.count == 4 else {
                    throw GLTFError.other("Cannot convert string to data")
                }
                
                glb.append(bytes)
            }
            
            
            // 4 bytes of version
            do {
                let version: [UInt8] = [2, 0, 0, 0]
                glb.append(Data(version))
            }
            
            
            // 4 bytes of total length
            do {
                let totalLength = 12 + 8 + jsonData.count + jsonDataPadding + binaryData.count
                if totalLength > UInt32.max {
                    throw GLTFError.other("Exceeded maximum 32-bit integer value for binary size")
                }
                glb.write(UInt32(totalLength))
            }
        }
        
        
        // json chunk
        do {
            // 4 bytes of length
            do {
                let length = UInt32(jsonData.count + jsonDataPadding)
                glb.write(length)
            }
            
            // 4 bytes of chunk type
            do {
                let chunkType: UInt32 = 0x4E4F534A
                glb.write(chunkType)
            }
            
            // data bytes with length aligned to 4
            do {
                glb.append(jsonData)
                
                if jsonDataPadding > 0 {
                    glb.append(contentsOf: Array(repeating: 0x20, count: jsonDataPadding))
                }
            }
        }
        
        
        // binary data chunk
        do {
            glb.append(binaryData)
        }
        
        
        return glb
    }
}
