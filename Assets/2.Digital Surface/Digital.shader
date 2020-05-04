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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

			float2 rand2(float2 p)
			{
				float a = sin(p.x * 591.68 + p.y * 168.147);
				float b = cos(p.x * 429.68 + p.y * 61.147);
				return frac(float2(a, b));
			}

			float voronoi(float2 uv)
			{
				float2 id = floor(uv);
				float2 gv = frac(uv);
				return id;
				float minD = 100;
				for (int y = -1; y <= 1; y++)
				{
					for (int x = -1; x <= 1; x++)
					{
						float2 offset = float2(x, y);
						float rnd = rand2(id + offset);
						float2 p = offset - gv + rnd;
						float d = length(p);
						if (d < minD)
						{
							minD = d;
						}
					}
				}
				return minD;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = (i.uv - 0.5) * 30;
				float3 col = 0;
				col = voronoi(uv);
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}
