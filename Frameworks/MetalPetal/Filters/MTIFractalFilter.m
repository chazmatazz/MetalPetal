//
//  MTIFractalFilter.m
//  MetalPetal
//
//  Created by Charles Dietrich on 25/1/2025.
//

#import "MTIFractalFilter.h"
#import "MTIFunctionDescriptor.h"
#import "MTIVector+SIMD.h"
#import "MTIColor.h"

@implementation MTIFractalFilter

- (instancetype)init {
    if (self = [super init]) {
        _time = 1;
    }
    return self;
}

+ (MTIFunctionDescriptor *)fragmentFunctionDescriptor {
    return [[MTIFunctionDescriptor alloc] initWithName:@"fractalFragment"];
}

- (NSDictionary<NSString *,id> *)parameters {
    return @{@"time": @(self.time)};
}

+ (MTIAlphaTypeHandlingRule *)alphaTypeHandlingRule {
    return MTIAlphaTypeHandlingRule.generalAlphaTypeHandlingRule;
}

@end
