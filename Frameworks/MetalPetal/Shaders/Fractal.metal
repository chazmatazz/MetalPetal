//
//  Fractal.metal
//  MetalPetal
//
//  Created by Charles Dietrich on 25/11/2025.
//

#include "MTIShaderLib.h"

using namespace metal;
using namespace metalpetal;

#define PI 3.14159265359
#define RSY 0.30 // length of each tree root trunk in NDC

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
        
        
        fragment float4 fractalFragment2( VertexOut vertexIn [[ stage_in ]],
                                        texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                        sampler colorSampler [[ sampler(0) ]],
                                        constant float &time [[buffer(1)]]
                                        )
        {
            float2 uv = vertexIn.textureCoordinate;
            uv /= 1.1;
            uv += .05;
            uv *= 1.;
            float t = (time -6.) * .3;
            float2 c = uv - float2(0.5);
            float d = length(c);
            float a = atan2(c.y, c.x);
            float s = smoothstep(.1,2.,d);
            
            d += s * sin(t+a * 50.) * .05;// * snoise(uv*2.+1.+t*.3);
            d += s * snoise(float2(d*cos(2.*a+t*.1), d*sin(2.*a+t*.1))*(4.3*(s/3.7+1.2))-float2(t*1.2,0.));
            
            return colorTexture.sample(colorSampler, float2(.5+d*.6*cos(a*(1-step(0.3,d))), .5+d*.6*sin(a*(1-step(0.3,d)))));
            
        }
        
        METAL_FUNC float2 hash21(float p)
        {
            float3 p3 = fract(float3(p) * float3(.1031, .1030, .0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return fract((p3.xx+p3.yz)*p3.zy);
            
        }
        METAL_FUNC bool bound(float2 p, float2 rand, float size)
        {
            return p.x>rand.x&&p.y>rand.y&&p.x<rand.x+size&&p.y<rand.y+size;
        }
        
        fragment float4 glitchFragment( VertexOut vertexIn [[ stage_in ]],
                               texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                               sampler colorSampler [[ sampler(0) ]],
                               constant float &time [[buffer(1)]]
                               )
        {
            float2 uv = vertexIn.textureCoordinate;
            
            float size = 0.05;
            bool refresh = false;
            
            for (float i=0.0;i<100.0;i++) {// the 100.0 value here is how many rects per frame to update, the 1.0 value just under it is the chance of each rect actually updating ^-1
                if (bound(uv,hash21(float(time*int(i+1.0))),size)) { // mod(float(time),1.0)==0.0 &&
                    refresh = true;
                }
            }
            
            if (refresh == false) {
                discard_fragment();
            }
            
            return colorTexture.sample(colorSampler, fract(uv));
        }
    }
    
    /* This animation is the material of my first youtube tutorial about creative
       coding, which is a video in which I try to introduce programmers to GLSL
       and to the wonderful world of shaders, while also trying to share my recent
       passion for this community.
                                           Video URL: https://youtu.be/f4s1h2YETNY
    */

    //https://iquilezles.org/articles/palettes/
    METAL_FUNC float3 palette( float t ) {
        float3 a = float3(0.5, 0.5, 0.5);
        float3 b = float3(0.5, 0.5, 0.5);
        float3 c = float3(1.0, 1.0, 1.0);
        float3 d = float3(0.263,0.416,0.557);

        return a + b*cos( 6.28318*(c*t+d) );
    }
    
    

    //https://www.shadertoy.com/view/mtyGWy
    METAL_FUNC float2 pattern (   float2 textureCoordinate,
                             float time
                           )
    {
        float2 uv = 2. * (textureCoordinate - 0.5);
        float2 uv0 = uv;
        float3 finalColor = float3(0.0);
        
        for (float i = 0.0; i < 4.0; i++) {
            uv = fract(uv * 1.5) - 0.5;

            float d = length(uv) * exp(-length(uv0));

            float3 col = palette(length(uv0) + i*.4 + time*.4);

            d = sin(d*8. + time)/8.;
            d = abs(d);

            d = pow(0.01 / d, 1.2);

            finalColor += col * d;
        }
        
        return textureCoordinate+finalColor.xy/512.;
    }
    
    // Copyright Inigo Quilez, 2013 - https://iquilezles.org/
    // I am the sole copyright owner of this Work.
    // You cannot host, display, distribute or share this Work neither
    // as it is or altered, here on Shadertoy or anywhere else, in any
    // form including physical and digital. You cannot use this Work in any
    // commercial or non-commercial product, website or project. You cannot
    // sell this Work and you cannot mint an NFTs of it or train a neural
    // network with it without permission. I share this Work for educational
    // purposes, and you can link to it, through an URL, proper attribution
    // and unmodified screenshot, as part of your educational material. If
    // these conditions are too restrictive please contact me and we'll
    // definitely work it out.

    // This shader computes the distance to the Mandelbrot Set for everypixel, and colorizes
    // it accordingly.
    //
    // Z -> Z²+c, Z0 = 0.
    // therefore Z' -> 2·Z·Z' + 1
    //
    // The Hubbard-Douady potential G(c) is G(c) = log Z/2^n
    // G'(c) = Z'/Z/2^n
    //
    // So the distance is |G(c)|/|G'(c)| = |Z|·log|Z|/|Z'|
    //
    // More info:
    // https://iquilezles.org/articles/distancefractals


    METAL_FUNC float distanceToMandelbrot(  float2 c )
    {
        // iterate
        float di =  1.0;
        float2 z  = float2(0.0);
        float m2 = 0.0;
        float2 dz = float2(0.0);
        for( int i=0; i<300; i++ )
        {
            if( m2>1024.0 ) { di=0.0; break; }

            // Z' -> 2·Z·Z' + 1
            dz = 2.0*float2(z.x*dz.x-z.y*dz.y, z.x*dz.y + z.y*dz.x) + float2(1.0,0.0);
                
            // Z -> Z² + c
            z = float2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y ) + c;
                
            m2 = dot(z,z);
        }

        // distance
        // d(c) = |Z|·log|Z|/|Z'|
        float d = 0.5*sqrt(dot(z,z)/dot(dz,dz))*log(dot(z,z));
        //if( di>0.5 ) d=0.0;
        
        return d;
    }

    METAL_FUNC float2 mandelbrot( float2 textureCoordinate, float time                           )
    {
        
        float2 p = 2. * (textureCoordinate - 0.5);
        float d = length(p);
        //float a = atan2(p.y, p.x);
        
        // animation
        float tz = 0.5 - 0.5*cos(0.225*(time-63));
        float zoo = 1.*pow( 0.5, 13.0*tz );
        float2 c = float2(-0.05,.6805) + p*zoo;

        // distance to Mandelbrot
        float mandebrotD = distanceToMandelbrot(c);
        
        // do some soft coloring based on distance
        mandebrotD = clamp( pow(4.0*mandebrotD/zoo,0.2), 0.0, 1.0 );
        //d =pow(d,.1);
        //d = 1.0-1.0/(1.0+1000.0*d);
        return textureCoordinate+d*d*float2(mandebrotD)/10.;
        
    }
    
    fragment float4 fractalFragment( VertexOut vertexIn [[ stage_in ]],
                           texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                           sampler colorSampler [[ sampler(0) ]],
                           constant float &time [[buffer(1)]]
                           )
    {
        float fade = smoothstep(140, 150, time);
        return colorTexture.sample(colorSampler, (1-fade) * pattern(vertexIn.textureCoordinate, time) + fade * mandelbrot(vertexIn.textureCoordinate, time));
    }

    // TODO:
    // - compress the image
    // - add blur dependent on local strength

    METAL_FUNC float displacement(float x, float num_stripes, float strength) {

        float modulus = 1.0 / num_stripes;
        
        return mod(x, modulus) * strength;
    }

    METAL_FUNC float fractal_glass(float x) {
        
        const float NUM_STRIPES = 25.0;
        const float STRRENGTH = 1.0;
        const float SOFTNESS = 0.0005;

        float d = 0.0;
        for (int i = -5; i <= 5; i++) {
           d += displacement(x + float(i) * SOFTNESS, NUM_STRIPES, STRRENGTH);
        }

        d = d / 11.0;
        
        return x + d;
    }


    fragment float4 glassFragment( VertexOut vertexIn [[ stage_in ]],
                           texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                           sampler colorSampler [[ sampler(0) ]],
                           constant float &time [[buffer(1)]]
                           )
    {
        // Normalized pixel coordinates (from 0 to 1)
        float2 uv = vertexIn.textureCoordinate;
     
        uv.x = fractal_glass(uv.x);
        
        
        return colorTexture.sample(colorSampler, uv);
    }
    
    //
    // Description : Array and textureless GLSL 2D simplex noise function.
    //      Author : Ian McEwan, Ashima Arts.
    //  Maintainer : stegu
    //     Lastmod : 20110822 (ijm)
    //     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
    //               Distributed under the MIT License. See LICENSE file.
    //               https://github.com/ashima/webgl-noise
    //               https://github.com/stegu/webgl-noise
    //

    METAL_FUNC float3 mod289(float3 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }

    METAL_FUNC float2 mod289(float2 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }

    METAL_FUNC float3 permute(float3 x) {
      return mod289(((x*34.0)+1.0)*x);
    }

    METAL_FUNC float snoise(float2 v)
      {
      const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                          0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                         -0.577350269189626,  // -1.0 + 2.0 * C.x
                          0.024390243902439); // 1.0 / 41.0
    // First corner
      float2 i  = floor(v + dot(v, C.yy) );
      float2 x0 = v -   i + dot(i, C.xx);

    // Other corners
      float2 i1;
      //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
      //i1.y = 1.0 - i1.x;
      i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
      // x0 = x0 - 0.0 + 0.0 * C.xx ;
      // x1 = x0 - i1 + 1.0 * C.xx ;
      // x2 = x0 - 1.0 + 2.0 * C.xx ;
      float4 x12 = x0.xyxy + C.xxzz;
      x12.xy -= i1;

    // Permutations
      i = mod289(i); // Avoid truncation effects in permutation
      float3 p = permute( permute( i.y + float3(0.0, i1.y, 1.0 ))
            + i.x + float3(0.0, i1.x, 1.0 ));

      float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
      m = m*m ;
      m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

      float3 x = 2.0 * fract(p * C.www) - 1.0;
      float3 h = abs(x) - 0.5;
      float3 ox = floor(x + 0.5);
      float3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
      m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
      float3 g;
      g.x  = a0.x  * x0.x  + h.x  * x0.y;
      g.yz = a0.yz * x12.xz + h.yz * x12.yw;
      return 130.0 * dot(m, g);
    }

    METAL_FUNC float rand(float2 co)
    {
       return fract(sin(dot(co.xy,float2(12.9898,78.233))) * 43758.5453);
    }
    
    METAL_FUNC float2 polarToXY(float d, float a) {
        return float2(.5*d*cos(a), .5*d*sin(a))+float2(0.5);
    }
 
    fragment float4 glitch2Fragment( VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    constant float &time [[buffer(1)]]
                                    )
    {
        float2 uv = vertexIn.textureCoordinate;
        
        float2 p = 2. * (uv-.5);
        float d = length(p);
        float a = atan2(p.y, p.x);
        
        // Create large, incidental noise waves
        float noise = snoise(float2(sin(time)*.5, a * 1.3) - 0.) * (1.0 / 0.7);
        
        // Offset by smaller, constant noise waves
        noise = noise + (snoise(float2(time*1.0, a * 2.4)) - 0.5) * 0.15;
        
        // Apply the noise as x displacement for every line
        d = d + d*d*noise * noise * 0.25;
        d = d * .6;
        //a = a * cos(smoothstep(0,.8, d)*acos(fract(time)));
        
        float4 fragColor = colorTexture.sample(colorSampler, polarToXY(d,a));
        
        
        // Mix in some random interference for lines
        fragColor.rgb = mix(fragColor.rgb, float3(rand(float2(d * time))), noise * 0.3).rgb;
        
        // Apply a line pattern every 4 pixels
        if (floor(mod(d * 100. * 0.25, 2.0)) == 0.0)
        {
            //fragColor.rgb *= 1.0 - (0.15 * noise);
        }
        
        // Shift green/blue channels (using the red channel)
        //fragColor.g = mix(fragColor.r, colorTexture.sample(colorSampler, polarToXY((d+ d*d*noise * 0.05 * 0.25), a)).g, 0.25);
        //fragColor.b = mix(fragColor.r, colorTexture.sample(colorSampler, polarToXY((d- d*d*noise * 0.05 * 0.25), a)).b, 0.25);
        
        return fragColor;
    }
    
    // "Psychofract" by Carlos Ureña - 2015
    // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

    // -----------------------------------------------------------------------------

    METAL_FUNC float3x3 RotateMat( float rads )
    {
       float c = cos(rads),
             s = sin( rads ) ;
       
       return float3x3(  c,  s, 0.0,
                    -s,   c, 0.0,
                   0.0, 0.0, 1.0  );
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float3x3 TranslateMat( float2 d )
    {
       return float3x3(  1.0, 0.0, 0.0,
                     0.0, 1.0, 0.0,
                     d.x, d.y, 1.0 );
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float3x3 ScaleMat( float2 s )
    {
       return float3x3( s.x, 0.0, 0.0,
                    0.0, s.y, 0.0,
                    0.0, 0.0, 1.0 );
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float3x3 ChangeFrameToMat( float2 org, float angg, float scale )
    {
       float angr = (angg*PI)/180.0 ;
       return
            ScaleMat( float2( 1.0/scale, 1.0/scale ) )
          * RotateMat( -angr )
          * TranslateMat( -org ) ;
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float RectangleDistSq( float3 p )
    {
       if ( 0.0 <= p.y && p.y <= RSY )
           return p.x * p.x;
        
       if (p.y > RSY)
           return p.x*p.x + (p.y-RSY)*(p.y-RSY) ;
        
       return p.x*p.x + p.y*p.y ;
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float BlendDistSq( float d1, float d2, float d3 )
    {
       float dmin = min( d1, min(d2,d3)) ;
          
       return 0.5*dmin ;
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float4 ColorF( float distSq, float angDeg )
    {
       float b = min(1.0, 0.1/(sqrt(distSq)+0.1)),
             v = 0.5*(1.0+cos( 200.0*angDeg/360.0 + b*15.0*PI ));
         
       return float4( b*b*b,b*b,0.0,distSq) ; // returns squared distance in alpha component
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float Trunk4DistSq( float3 p )
    {
       float d1 = RectangleDistSq( p );
        
       return d1 ;
    }

    // -----------------------------------------------------------------------------

    METAL_FUNC float Trunk3DistSq( float3x3 tran1, float3x3 tran2, float3 p )
    {
       float d1 = RectangleDistSq( p ),
             d2 = Trunk4DistSq( tran1*p ),
             d3 = Trunk4DistSq( tran2*p );
          
       return BlendDistSq( d1, d2, d3 ) ;
    }

    // -----------------------------------------------------------------------------

    METAL_FUNC float Trunk2DistSq( float3x3 tran1, float3x3 tran2, float3 p )
    {
       float d1 = RectangleDistSq( p ),
             d2 = Trunk3DistSq( tran1, tran2, tran1*p ),
             d3 = Trunk3DistSq( tran1, tran2, tran2*p );
        
       return BlendDistSq( d1, d2, d3 ) ;
    }

    // -----------------------------------------------------------------------------

    METAL_FUNC float Trunk1DistSq( float3x3 tran1, float3x3 tran2, float3 p )
    {
       float d1 = RectangleDistSq( p ) ,
             d2 = Trunk2DistSq( tran1, tran2, tran1*p ),
             d3 = Trunk2DistSq( tran1, tran2, tran2*p );
        
       return BlendDistSq( d1, d2, d3 ) ;
    }

    // -----------------------------------------------------------------------------

    METAL_FUNC float Trunk0DistSq( float3x3 tran1, float3x3 tran2, float3 p )
    {
       float d1 = RectangleDistSq( p ) ,
             d2 = Trunk1DistSq( tran1, tran2, tran1*p ),
             d3 = Trunk1DistSq(tran1, tran2, tran2*p );
        
       return BlendDistSq( d1, d2, d3 ) ;
    }
    // -----------------------------------------------------------------------------
    // compute the color and distance to tree, for a point in NDC coords

    METAL_FUNC float4 ComputeColorNDC( float3x3 tran1, float3x3 tran2, float3 p, float angDeg )
    {
       float2 org = float2(0.5,0.5) ;
       float4 col = float4( 0.0, 0.0, 0.0, 1.0 );
       float dmin ;
        
       for( int i = 0 ; i < 4 ; i++ )
       {
          float3x3 m = ChangeFrameToMat( org, angDeg + float(i)*90.0, 0.7 );
             float3 p_transf = m*p ;
          float dminc = Trunk0DistSq( tran1, tran2, p_transf ) ;
                
          if ( i == 0 )
             dmin = dminc ;
          else if ( dminc < dmin )
             dmin = dminc ;
       }
       return ColorF( dmin, angDeg ); // returns squared dist in alpha component
    }
    // -----------------------------------------------------------------------------

    METAL_FUNC float3 ComputeNormal( float3x3 tran1, float3x3 tran2, float3 p, float dd, float ang, float4 c00 )
    {
       float4   //c00  = ComputeColorNDC( p, ang )  ,
             c10  = ComputeColorNDC( tran1, tran2, p + float3(dd,0.0,0.0), ang )  ,
             c01  = ComputeColorNDC( tran1, tran2, p + float3(0.0,dd,0.0) , ang ) ;
       float h00  = sqrt(c00.a),
             h10  = sqrt(c10.a),
             h01  = sqrt(c01.a);
       float3  tanx = float3( dd, 0.0, h10-h00 ),
             tany = float3( 0.0, dd, h01-h00 );
       float3  n    = normalize( cross( tanx,tany ) );
           
       if ( n.z < 0.0 ) n *= -1.0 ;
       return n ;
    }

    // -----------------------------------------------------------------------------

    fragment float4 treeFragment( VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    constant float &time [[buffer(1)]]
                                    )
    {
       
       const float width = 0.1 ;

       
       float2  res  = float2(1.) ;
       float mind = min(res.x,res.y);
       float2  pos  = vertexIn.textureCoordinate ;
       float x0   = (res.x - mind)/2.0 ,
             y0   = (res.y - mind)/2.0 ,
             px   = pos.x - x0 ,
             py   = pos.y - y0 ;
          
      
       // compute 'tran1' and 'tran2':
        
       float2  org1      = float2( 0.0, RSY ) ;
       float ang1_deg  = +20.0 + 30.00*cos( 2.0*PI*time/4.05 ),
             scale1    = +0.85 +  0.40*cos( 2.0*PI*time/2.10 )  ;

       float2  org2      = float2( 0.0, RSY ) ;
       float ang2_deg  = -30.0 + 40.00*sin( 2.0*PI*time/2.52 ),
             scale2    = +0.75 +  0.32*sin( 2.0*PI*time/4.10 )  ;
       
       float3x3 tran1 = ChangeFrameToMat( org1, ang1_deg, scale1 ) ;
       float3x3 tran2 = ChangeFrameToMat( org2, ang2_deg, scale2 ) ;
       
       // compute pixel color (pixCol)
        
       float mainAng = 360.0*time/15.0 ,    // main angle, proportional to time
             dd      = 1.0/float(mind) ;           // pixel width or height in ndc
       float3  pixCen  = float3( px*dd, py*dd, 1.0 ) ; // pixel center
       float4  pixCol  = ComputeColorNDC( tran1, tran2, pixCen, mainAng ),
             resCol  ;
       
       // compute output color as a function 'use_normal'
       
        const bool use_gradient = false ;
        
       if ( use_gradient )
       {
          float3 nor     = ComputeNormal( tran1, tran2, pixCen, dd, mainAng, pixCol );
          float4 gradCol = float4( max(nor.x,0.0), max(nor.y,0.0), max(nor.z,0.0), 1.0 ) ;
           
          resCol = 0.8*pixCol+ 0.2*gradCol ;
       }
       else
          resCol = pixCol ;
          
        return colorTexture.sample(colorSampler, vertexIn.textureCoordinate+resCol.xy/100.);
        
       
    }
    
    
#define cProd(a, b) float2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x)

float2 cPwr( float2 z, int n )
{
    float2 memo = z;
    n--;
    
    for (int i=1; i<1000000000; i++)
    {
        memo = cProd(memo, z);
        if (i>=n) {break;}
    }
    
    return memo;
}

float2 julia( float2 z, float2 c, int d )
{
    return cPwr(z, d) + c;
}

bool checkPoint( float2 z, float2 c, int d )
{
    bool result;
    float2 memo = z;
   
    for ( int i = 0; i <= 100; i++ )
    {
        if (length( memo ) > 2.0) {break;}
        memo = julia(memo, c, d);
    }
    
    if ( length( memo ) < 2.0 )
    {
        result = true;
    }
    else
    {
        result = false;
    }
    
    return result;
}

    fragment float4 juliaFragment( VertexOut vertexIn [[ stage_in ]],
                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                    sampler colorSampler [[ sampler(0) ]],
                                    constant float &time [[buffer(1)]]
                                    )
    {
        float2 fragCoord = vertexIn.textureCoordinate;
        float2 iResolution = float2(1.);
    float scale = .5;
    float offX = 0.0;
    float offY = 0.0;
    float t = .1*sin(time);

    float2 z = fragCoord * scale + float2(-scale*(iResolution.x/2.0 - offX), -scale*(iResolution.y/2.0 - offY));
    float2 c = float2(-.391+t, -.587);
    int d = 2;
    
        float bounded = checkPoint(z, c, d)? 1.:0;
    
        //return float4(float3(bounded, 1.);
        
        
      return colorTexture.sample(colorSampler, vertexIn.textureCoordinate+float2(bounded)/100.);
}

}

