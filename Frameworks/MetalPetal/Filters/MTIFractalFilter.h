//
//  MTIFractalFilter.h
//  MetalPetal
//
//  Created by Charles Dietrich on 25/11/2025.
//

#import <simd/simd.h>
#if __has_include(<MetalPetal/MetalPetal.h>)
#import <MetalPetal/MTIUnaryImageRenderingFilter.h>
#else
#import "MTIUnaryImageRenderingFilter.h"
#endif

__attribute__((objc_subclassing_restricted))
@interface MTIFractalFilter : MTIUnaryImageRenderingFilter

/// Specifies the time of the effect.
@property (nonatomic) float time;
@end
