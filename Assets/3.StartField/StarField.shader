Shader "Unlit/StarField"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Iterations("Iterations", Range(1, 20)) = 13
        _FormulaCoefficient("Coefficient", Range(0, 1)) = 0.53
        _VolumeSteps("Steps", Range(5, 20)) = 15
        _StepSize("Size", Range(0.01, 0.3)) = 0.1
        _Zoom("Zoom", Range(0.1, 10)) = 1.8
        _Tile("Tile", Range(0.2, 5)) = 0.85
        _Speed("Speed", Range(0.0, 1.0)) = 0.05
        _Brightness("Brightness", Range(0.0, 0.01)) = 0.0015
        _Darkness("Darkness", Range(0.0, 1)) = 0.3
        _DistFading("Fading", Range(0.1, 1)) = 0.73
        _Saturation("Saturation", Range(0.1, 2)) = 0.85
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Iterations;
            float _FormulaCoefficient;
            float _VolumeSteps;
            float _StepSize;
     
            float _Zoom;
            float _Tile;
            float _Speed;
            
            float _Brightness;
            float _Darkness;
            float _DistFading;
            float _Saturation;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            static float _sin1 = 0.48;
            static float _cos1 = 0.88;
            static float _sin2 = 0.71;
            static float _cos2 = 0.7;
            static float2x2 _rotation1 = float2x2(_cos1, _sin1, -_sin1, _cos1);
            static float2x2 _rotation2 = float2x2(_cos2, _sin2, -_sin2, _cos2);

            float3 rotate(float3 dir)
            {
                dir.xz = mul(_rotation1, dir.xz);
                dir.xy = mul(_rotation2, dir.xy); 
                return dir;
            }

            float3 mod(float3 x, float3 y)
            {
                return x - y * floor(x/y);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - 0.5;
                float3 dir = float3(uv * _Zoom, 1.0);
                dir = rotate(dir);
                
                float time = _Time.y * _Speed;
                float3 from = float3(1, 0.5, 0.5);
                //from += float3(time * 2.0, time, -1.0);
                from = rotate(from);

                //volumetric rendering
                float s = 0.1, fade = 1.0;
                float3 v = 0;
                int r = 0;
                for (int r = 0; r < _VolumeSteps; r++) 
                {
                    float3 p = from + s * dir;
                    p = abs(_Tile - mod(p, _Tile * 2.0)); // tiling fold

                    float pa = 0.0, a = 0.0;
                    for (int i = 0; i < _Iterations; i++) 
                    { 
                        p = abs(p) / dot(p, p) - _FormulaCoefficient; // the magic formula
                        a += abs(length(p) - pa); // absolute sum of average change
                        pa = length(p);
                    }
                    float dm = max(0.0, _Darkness - a * a * 0.001); //dark matter
                    a *= a * a; // add contrast
                    if (r > 6) fade *= 1.0 - dm; // dark matter, don't render near
                        
                    v += fade;
                    v += float3(s, s * s, s * s * s * s) * a * _Brightness * fade; // coloring based on distance
                    fade *= _DistFading; // distance fading
                    s += _StepSize;
                }
                
                float3 v1 = length(v);
                v = lerp(v1, v, _Saturation); //color adjust
                return float4(v * 0.01, 1.0);	
            }
            ENDCG
        }
    }
}
