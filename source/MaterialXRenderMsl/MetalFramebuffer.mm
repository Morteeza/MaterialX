//
// Copyright (c) 2023 Apple Inc.
// Licensed under the Apache License v2.0
//

#include <MaterialXRenderMsl/MetalFramebuffer.h>

#include <MaterialXRenderMsl/MSLPipelineStateObject.h>
#include <MaterialXRenderMsl/MslRenderer.h>
#include <MaterialXRenderMsl/MetalTextureHandler.h>

MATERIALX_NAMESPACE_BEGIN

//
// MetalFramebuffer methods
//

MetalFramebufferPtr MetalFramebuffer::create(id<MTLDevice> device,
                                             unsigned int width, unsigned int height,
                                             unsigned channelCount,
                                             Image::BaseType baseType,
                                             id<MTLTexture> colorTexture)
{
    return MetalFramebufferPtr(new MetalFramebuffer(device, width, height, channelCount, baseType, colorTexture));
}

MetalFramebuffer::MetalFramebuffer(id<MTLDevice> device, unsigned int width, unsigned int height, unsigned int channelCount, Image::BaseType baseType, id<MTLTexture> colorTexture) :
    _width(width),
    _height(height),
    _channelCount(channelCount),
    _baseType(baseType),
    _encodeSrgb(false),
    _framebuffer(0),
    _colorTexture(colorTexture),
    _depthTexture(0),
    _device(device)
{
    StringVec errors;
    const string errorType("Metal target creation failure.");

    // Convert texture format to Metal
    MTLPixelFormat pixelFormat;
    MTLDataType    dataType;
    MetalTextureHandler::mapTextureFormatToMetal(baseType, channelCount, true, dataType, pixelFormat);
    
    MTLTextureDescriptor* texDescriptor = [MTLTextureDescriptor
                                           texture2DDescriptorWithPixelFormat:pixelFormat width:_width height:_height mipmapped:NO];
    [texDescriptor setStorageMode:MTLStorageModePrivate];
    [texDescriptor setUsage:MTLTextureUsageRenderTarget|MTLTextureUsageShaderRead];
    
    if(colorTexture == nil)
        _colorTexture = [device newTextureWithDescriptor:texDescriptor];
    
    texDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
    [texDescriptor setUsage:MTLTextureUsageRenderTarget];
    _depthTexture = [device newTextureWithDescriptor:texDescriptor];
}

MetalFramebuffer::~MetalFramebuffer()
{
    [_colorTexture release];
    [_depthTexture release];
}

void MetalFramebuffer::resize(unsigned int width, unsigned int height)
{
    if (width * height <= 0)
    {
        return;
    }
    if (width != _width || _height != height)
    {
        // Convert texture format to Metal
        MTLPixelFormat pixelFormat;
        MTLDataType    dataType;
        MetalTextureHandler::mapTextureFormatToMetal(_baseType, _channelCount, true, dataType, pixelFormat);

        MTLTextureDescriptor* texDescriptor = [MTLTextureDescriptor
                                               texture2DDescriptorWithPixelFormat:pixelFormat width:_width height:_height mipmapped:NO];
        [texDescriptor setStorageMode:MTLStorageModePrivate];
        [texDescriptor setUsage:MTLTextureUsageRenderTarget|MTLTextureUsageShaderRead];
        
        _colorTexture = [_device newTextureWithDescriptor:texDescriptor];
        
        texDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
        [texDescriptor setUsage:MTLTextureUsageRenderTarget];
        _depthTexture = [_device newTextureWithDescriptor:texDescriptor];

        _width = width;
        _height = height;
    }
}

void MetalFramebuffer::bind(MTLRenderPassDescriptor* renderpassDesc)
{
    [renderpassDesc.colorAttachments[0] setTexture:getColorTexture()];
    [renderpassDesc.colorAttachments[0] setLoadAction:MTLLoadActionClear];
    [renderpassDesc.colorAttachments[0] setStoreAction:MTLStoreActionStore];
    
    [renderpassDesc.depthAttachment setTexture:getDepthTexture()];
    [renderpassDesc.depthAttachment setClearDepth:1.0];
    [renderpassDesc.depthAttachment setLoadAction:MTLLoadActionClear];
    [renderpassDesc.depthAttachment setStoreAction:MTLStoreActionStore];
    [renderpassDesc setStencilAttachment:nil];
    
    [renderpassDesc setRenderTargetWidth:_width];
    [renderpassDesc setRenderTargetHeight:_height];
}

void MetalFramebuffer::unbind()
{
}

ImagePtr MetalFramebuffer::getColorImage(id<MTLCommandQueue> cmdQueue, ImagePtr image)
{
    if (!image)
    {
        image = Image::create(_width, _height, _channelCount, _baseType);
        image->createResourceBuffer();
    }
    
    if(cmdQueue == nil)
    {
        return image;
    }
    
    size_t bytesPerRow = _width*_channelCount*MetalTextureHandler::getTextureBaseTypeSize(_baseType);
    size_t bytesPerImage = _height * bytesPerRow;
    
    id<MTLBuffer> buffer = [_device newBufferWithLength:bytesPerImage options:MTLResourceStorageModeShared];
    
    id<MTLCommandBuffer> cmdBuffer = [cmdQueue commandBuffer];
    
    id<MTLBlitCommandEncoder> blitCmdEncoder = [cmdBuffer blitCommandEncoder];
    [blitCmdEncoder copyFromTexture:_colorTexture
                        sourceSlice:0
                        sourceLevel:0
                       sourceOrigin:MTLOriginMake(0, 0, 0)
                         sourceSize:MTLSizeMake(_width, _height, 1)
                           toBuffer:buffer destinationOffset:0
             destinationBytesPerRow:bytesPerRow
           destinationBytesPerImage:bytesPerImage
                            options:MTLBlitOptionNone];
    
    [blitCmdEncoder endEncoding];
    [cmdBuffer commit];
    [cmdBuffer waitUntilCompleted];
    [cmdBuffer release];
    
    memcpy(image->getResourceBuffer(), [buffer contents], bytesPerImage);
    [buffer release];

    return image;
}

MATERIALX_NAMESPACE_END
