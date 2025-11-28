
//
//  Halftone.metal
//  MetalPetal
//
//  Created by Yu Ao on 18/01/2018.
//

#include "MTIShaderLib.h"

using namespace metal;
using namespace metalpetal;

namespace metalpetal {
    namespace fractal {

        METAL_FUNC float3 permute(float3 x) { return fmod( x*x*34.+x, 289.); }
        METAL_FUNC float snoise(float2 v) {
          float2 i = floor((v.x+v.y)*.36602540378443 + v),
              x0 = (i.x+i.y)*.211324865405187 + v - i;
        float s = step(x0.x,x0.y);
          float2 j = float2(1.0-s,s),
              x1 = x0 - j + .211324865405187,
              x3 = x0 - .577350269189626;
          i = fmod(i,289.);
          float3 p = permute( permute( i.y + float3(0, j.y, 1 ))+ i.x + float3(0, j.x, 1 )   ),
               m = max( .5 - float3(dot(x0,x0), dot(x1,x1), dot(x3,x3)), 0.),
               x = fract(p * .024390243902439) * 2. - 1.,
               h = abs(x) - .5,
              a0 = x - floor(x + .5);
          return .5 + 65. * dot( pow(m,float3(4.))*(- 0.85373472095314*( a0*a0 + h*h )+1.79284291400159 ), a0 * float3(x0.x,x1.x,x3.x) + h * float3(x0.y,x1.y,x3.y));
        }


                fragment float4 fractalFragment( VertexOut vertexIn [[ stage_in ]],
                                        texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                        sampler colorSampler [[ sampler(0) ]],
                                                constant float &time [[buffer(1)]]
        )
                {
                    float2 uv = vertexIn.textureCoordinate;
                    uv /= 1.1;
                    uv += .05;
                    uv *= 1.;
                    float t = time * .3;
                    float2 c = uv - float2(0.5);
                    float d = length(c);
                    float a = atan2(c.y, c.x);
                    float s = smoothstep(.1,2.,d);

                    d += s * sin(t+a * 50.) * .05;// * snoise(uv*2.+1.+t*.3);
                    d += s * snoise(float2(d*cos(2.*a+t*.1), d*sin(2.*a+t*.1))*(4.3*(s/3.7+1.2))-float2(t*1.2,0.));

                    return colorTexture.sample(colorSampler, float2(.5+d*.6*cos(a*(1-step(0.3,d))), .5+d*.6*sin(a*(1-step(0.3,d)))));

                }

    }
}

