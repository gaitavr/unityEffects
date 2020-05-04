Shader "Unlit/Digital"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			// 1D random numbers
			float rand(float n)
			{
				return frac(sin(n) * 43758.5453123);
			}

			// 2D random numbers
			float2 rand2(float2 p)
			{
				return frac(float2(sin(p.x * 591.32 + p.y * 154.077), cos(p.x * 391.32 + p.y * 49.077)));
			}

			// 1D noise
			float noise1(float p)
			{
				float fl = floor(p);
				float fc = frac(p);
				return lerp(rand(fl), rand(fl + 1.0), fc);
			}

			// voronoi distance noise, based on iq's articles
			float voronoi(float2 x)
			{
				float2 p = floor(x);
				float2 f = frac(x);

				float2 res = 8.0;
				for (int j = -1; j <= 1; j++)
				{
					for (int i = -1; i <= 1; i++)
					{
						float2 b = float2(i, j);
						float2 r = float2(b) - f + rand2(p + b);

						// chebyshev distance, one of many ways to do this
						float d = max(abs(r.x), abs(r.y));

						if (d < res.x)
						{
							res.y = res.x;
							res.x = d;
						}
						else if (d < res.y)
						{
							res.y = d;
						}
					}
				}
				return res.y - res.x;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float flicker = noise1(_Time.y) * 0.8 + 0.4;
				
				float2 uv = i.uv;
				uv = (uv - 0.5) * 10.0;

				float t = 0;

				
				for (int i = 0; i < 3; i++)
				{

				}
				return float4(t, t, t, 1.0);

				float v = 0.0;

				float a = 0.6, f = 1.0;//a - brigtness, f = noise granules

				for (int i = 0; i < 3; i++) // 4 octaves also look nice, its getting a bit slow though
				{
					float v1 = voronoi(uv * f + 5.0);
					float v2 = 0.0;

					// make the moving electrons-effect for higher octaves
					if (i > 0)
					{
						// of course everything based on voronoi
						v2 = voronoi(uv * f * 0.5 + 50.0 + _Time.y);

						float va = 0.0, vb = 0.0;
						va = 1.0 - smoothstep(0.0, 0.1, v1);
						vb = 1.0 - smoothstep(0.0, 0.08, v2);
						v += a * pow(va * (0.5 + vb), 2.0);
					}

					// make sharp edges
					v1 = 1.0 - smoothstep(0.0, 0.3, v1);

					// noise is used as intensity map
					v2 = a * (noise1(v1 * 5.5 + 0.1));

					// octave 0's intensity changes a bit
					if (i == 0)
						v += v2 * flicker;
					else
						v += v2;

					f *= 3.0;
					a *= 0.7;
				}

				float3 col = v * float3(0.8, 0.1, 0.5) * 1.5;
				return float4(col, 1.0);
            }
            ENDCG
        }
    }
}
