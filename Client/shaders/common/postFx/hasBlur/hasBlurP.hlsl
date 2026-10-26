#include "../postFx.h.hlsl"

#ifdef SHADER_STAGE_VS
    #define mainV main
#else
    #define mainP main
#endif

cbuffer perDraw
{
    float blurAmount;
    POSTFX_UNIFORMS
};

uniform_sampler2D(backBuffer, 0);

#include "../postFx.hlsl"

float4 mainP(PFXVertToPix IN) : SV_Target
{
    float2 uv = IN.uv0.xy;
    float2 offset = float2(blurAmount, blurAmount);
    float4 blurred = tex2D(backBuffer, uv) * 0.16;
    blurred += tex2D(backBuffer, uv + float2(offset.x, 0)) * 0.10;
    blurred += tex2D(backBuffer, uv - float2(offset.x, 0)) * 0.10;
    blurred += tex2D(backBuffer, uv + float2(0, offset.y)) * 0.10;
    blurred += tex2D(backBuffer, uv - float2(0, offset.y)) * 0.10;
    blurred += tex2D(backBuffer, uv + offset) * 0.07;
    blurred += tex2D(backBuffer, uv - offset) * 0.07;
    blurred += tex2D(backBuffer, uv + float2(offset.x, -offset.y)) * 0.07;
    blurred += tex2D(backBuffer, uv + float2(-offset.x, offset.y)) * 0.07;
    blurred += tex2D(backBuffer, uv + float2(offset.x * 2, 0)) * 0.04;
    blurred += tex2D(backBuffer, uv - float2(offset.x * 2, 0)) * 0.04;
    blurred += tex2D(backBuffer, uv + float2(0, offset.y * 2)) * 0.04;
    blurred += tex2D(backBuffer, uv - float2(0, offset.y * 2)) * 0.04;
    return blurred;
}

PFXVertToPix mainV(PFXVert IN)
{
    return processPostFxVert(IN);
}
