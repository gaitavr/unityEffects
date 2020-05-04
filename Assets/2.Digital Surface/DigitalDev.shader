Shader "Unlit/DigitalDev"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_BaseColor("Color", Color) = (1,1,1,1)
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
			float4 _BaseColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

			float rand(float n)
			{
				return frac(sin(n) * 43758.5453123);
			}

			float2 rand2(float2 p)
			{
				float a = sin(p.x * 591.68 + p.y * 168.147);
				float b = cos(p.x * 429.68 + p.y * 61.147);
				return frac(float2(a, b));
			}

			float noise1(float p)
			{
				float fl = floor(p);
				float fc = frac(p);
				return lerp(rand(fl), rand(fl + 1.0), fc);
			}

			float voronoi(float2 uv)
			{
				float2 id = floor(uv);
				float2 gv = frac(uv);

				float minD1 = 1000; 
				float minD2 = 1000;
				for (int y = -1; y <= 1; y++)
				{
					for (int x = -1; x <= 1; x++)
					{
						float2 offset = float2(x, y);
						float rnd = rand2(id + offset);
						float2 p = offset - gv + rnd;
						float d = max(abs(p.x), abs(p.y));
						if (d < minD1)
						{
							minD2 = minD1;
							minD1 = d;
						}
						else if (d < minD2)
						{
							minD2 = d;
						}
					}
				}
				return minD2 - minD1;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float flicker = noise1(_Time.y) * 0.8 + 0.4;//Translate to script, use fmod or something
				
				float2 uv = i.uv;
				uv = (uv - 0.5) * 10.0;
				float3 col = 0;

				float v = 0.0;
				float a = 0.8, f = 3.0;//a - amplitude, f = frequency

				for (int i = 0; i < 3; i++) // 4 octaves also look nice, its getting a bit slow though
				{
					float v1 = voronoi(uv * f);
					float v2 = 0.0;

					// make the moving electrons-effect for higher octaves
					if (i > 0)
					{
						v2 = voronoi(uv * f  * 0.3 + _Time.y);

						float va = 0.0, vb = 0.0;
						va = 1.0 - smoothstep(0.0, 0.15, v1);
						vb = 1.0 - smoothstep(0.0, 0.18, v2);
						v += 5.0 * a * pow(va * (0.5 + vb), 2.0);
					}

					// make sharp edges
					v1 = 1.0 - smoothstep(0.0, 0.3, v1);

					// noise is used as intensity map
					v2 = a * (noise1(v1 * 5));

					// octave 0's intensity changes a bit
					if (i == 0) v += v2 * flicker;
					else v += v2;

					f *= 3.0;
					a *= 0.5;
				}

				col = v * _BaseColor;
				return float4(col, 1.0);
            }
            ENDCG
        }
    }
}
