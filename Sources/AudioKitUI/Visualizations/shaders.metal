
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position  [[ position ]];
    float2 t;
};

constant float2 verts[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };

vertex VertexOut waveformVertex(uint vid [[ vertex_id ]]) {

    VertexOut out;
    out.position = float4(verts[vid], 0.0, 1.0);
    out.t = (verts[vid] + float2(1)) * .5;
    out.t.y = 1.0 - out.t.y;
    return out;

}

constexpr sampler s(coord::normalized,
                    filter::linear);

// This must be in sync with the definition in FloatPlot.swift
struct FragmentConstants {
    float4 foregroundColor;
    float4 backgroundColor;
    bool isFFT;
    bool isCentered;
    bool isFilled;
};

fragment half4 genericFragment(VertexOut in [[ stage_in ]],
                               texture1d<float, access::sample> waveform,
                               constant FragmentConstants& c) {

    float sample = waveform.sample(s, c.isFFT ? (pow(10, in.t.x) - 1.0) / 9.0 : in.t.x).x;

    float y = (-in.t.y + (c.isCentered ? 0.5 : 1));
    float d = c.isFilled ? fmax(fabs(y) - fabs(sample), 0) : fabs(y - sample);
    float alpha = c.isFFT ? fabs(1/(50 * d)) : smoothstep(0.01, 0.02, d);
    return half4( mix(c.foregroundColor, c.backgroundColor, alpha) );
}
