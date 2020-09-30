Shader "Unlit/StarField"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Iterations("Iterations", Range(1, 20)) = 13
        _FormulaCoefficient("Coefficient", Range(0, 1)) = 0.53
        _VolumeSteps("Steps", Range(1, 20)) = 15
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

            static float _sin30 = -0.99;
            static float _cos30 = 0.15;
            static float _sin45 = 0.85;
            static float _cos45 = 0.52;
            static float2x2 _rotation1 = float2x2(_cos30, _sin30, -_sin30, _cos30);
            static float2x2 _rotation2 = float2x2(_cos45, _sin45, -_sin45, _cos45);

            float3 rotate(float3 dir)
            {
                dir.xz = mul(_rotation1, dir.xz);
                dir.xy = mul(_rotation2, dir.xy); 
                return dir;
            }

            float mod(float x, float y)
            {
                return x - y * floor(x/y);
            }

            float3 mod3(float3 x, float3 y)
            {
                return x - y * floor(x/y);
            }

            float3 colorByDistance(float distance)
            {
                return float3(distance, distance * distance, distance * distance * distance * distance);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - 0.5;
                float3 dir = float3(uv * _Zoom, 1.0);
                dir = rotate(dir);
                
                float time = mod(_Time.y * _Speed, 7200);
                float3 from = float3(1, 0.5, 0.5);
                from += float3(time * 2.0, time, -1.0);
                from = rotate(from);

                //volumetric rendering
                float distance = 0.1, fade = 1.0;
                float3 color = 0;
                
                for (int r = 0; r < _VolumeSteps; r++) 
                {
                    float3 p = from + distance * dir;
                    p = abs(_Tile - mod3(p, _Tile * 2.0)); // tiling fold
                    
                    float pa = 0.0, a = 0.0;
                    for (int i = 0; i < _Iterations; i++) 
                    { 
                        p = abs(p) / dot(p, p) - _FormulaCoefficient; // the magic formula
                        a += abs(length(p) - pa); // absolute sum of average change
                        pa = length(p);
                    }

                    if (r > 6) fade *= 1.0 - max(0.0, _Darkness - a * a * 0.001); // dark matter, don't render near
                        
                    a *= a * a; // add contrast
                    color += fade;
                    color += colorByDistance(distance) * a * _Brightness * fade; // coloring based on distance
                    fade *= _DistFading; // distance fading
                    distance += _StepSize;
                }

                float3 greyScale = length(color);
                color = lerp(greyScale, color, _Saturation); //color adjust
                return float4(color * 0.01, 1.0);	
            }
            ENDCG
        }
    }
}
