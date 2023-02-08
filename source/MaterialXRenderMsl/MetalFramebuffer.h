//
// Copyright (c) 2023 Apple Inc.
// Licensed under the Apache License v2.0
//

#ifndef MATERIALX_METALFRAMEBUFFER_H
#define MATERIALX_METALFRAMEBUFFER_H

/// @file
/// Metal framebuffer handling

#include <MaterialXRenderMsl/Export.h>

#include <MaterialXRender/ImageHandler.h>

#import <Metal/Metal.h>

MATERIALX_NAMESPACE_BEGIN

class MetalFramebuffer;

/// Shared pointer to a MetalFramebuffer
using MetalFramebufferPtr = std::shared_ptr<MetalFramebuffer>;

/// @class MetalFramebuffer
/// Wrapper for an Metal framebuffer
class MX_RENDERMSL_API MetalFramebuffer
{
  public:
    /// Create a new framebuffer
    static MetalFramebufferPtr create(id<MTLDevice> device,
                                      unsigned int width, unsigned int height,
                                      unsigned int channelCount,
                                      Image::BaseType baseType,
                                      id<MTLTexture> colorTexture = nil);

    /// Destructor
    virtual ~MetalFramebuffer();

    /// Resize the framebuffer
    void resize(unsigned int width, unsigned int height);

    /// Set the encode sRGB flag, which controls whether values written
    /// to the framebuffer are encoded to the sRGB color space.
    void setEncodeSrgb(bool encode)
    {
        _encodeSrgb = encode;
    }

    /// Return the encode sRGB flag.
    bool getEncodeSrgb()
    {
        return _encodeSrgb;
    }

    /// Bind the framebuffer for rendering.
    void bind(MTLRenderPassDescriptor* renderpassDesc);

    /// Unbind the frame buffer after rendering.
    void unbind();

    /// Return our color texture handle.
    id<MTLTexture> getColorTexture() const
    {
        return _colorTexture;
    }

    /// Return our depth texture handle.
    id<MTLTexture> getDepthTexture() const
    {
        return _depthTexture;
    }

    /// Return the color data of this framebuffer as an image.
    /// If an input image is provided, it will be used to store the color data;
    /// otherwise a new image of the required format will be created.
    ImagePtr getColorImage(id<MTLCommandQueue> cmdQueue = nil, ImagePtr image = nullptr);

  protected:
    MetalFramebuffer(id<MTLDevice> device,
                     unsigned int width, unsigned int height,
                     unsigned int channelCount,
                     Image::BaseType baseType,
                     id<MTLTexture> colorTexture = nil);

  protected:
    unsigned int _width;
    unsigned int _height;
    unsigned int _channelCount;
    Image::BaseType _baseType;
    bool _encodeSrgb;

    unsigned int   _framebuffer;
    id<MTLDevice>  _device;
    id<MTLTexture> _colorTexture;
    id<MTLTexture> _depthTexture;
};

MATERIALX_NAMESPACE_END

#endif
