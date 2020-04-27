Shader "Hidden/Burning"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_TargetTex("Target tex", 2D) = "white" {}
		_AnimationTime("Animation time", float) = 0
		_FlameColor("Flame color", Color) = (0.9, 0.35, 0.1)
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
			sampler2D _TargetTex;
			float _AnimationTime;
			float3 _FlameColor;

			float Hash(float2 p)
			{
				float d = dot(p, float2(12.9898, 78.233));
				return frac(sin(d) * 43758.5453123);
			}

			float noise(float2 p)
			{
				float2 i = floor(p);
				float2 f = frac(p);
				f = smoothstep(0.0, 1.0, f);
				float a = Hash(i + float2(0.0, 0.0));
				float b = Hash(i + float2(0.0, 1.0));
				float c = Hash(i + float2(1.0, 0.0));
				float d = Hash(i + float2(1.0, 1.0));

				return lerp(lerp(a, c, f.x), lerp(b, d, f.x), f.y);
			}

			float fbm(float2 p)
			{
				float v = 0.0;
				v += noise(p * 15.0) * 0.35;
				v += noise(p * 30.0) * 0.175;
				v += noise(p * 45.0) * 0.0875;
				return v;
			}

			float3 TextureSource(float2 uv)
			{
				return tex2D(_MainTex, uv).rgb;
			}

			float3 TextureTarget(float2 uv)
			{
				float3 col = tex2D(_MainTex, uv);
				float lum = col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
				return lum * 0.5;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = i.uv;

				float3 src = TextureSource(uv);

				float3 tgt = TextureTarget(uv);

				uv.x -= 1.5;

				float offset = uv.x + uv.y * 0.5;

				float d = fbm(uv) + _AnimationTime + offset;

				float d1 = 0.35;//better to const
				float w12 = 0.10;//black width
				float w23 = 0.03;//flame width
				float d2 = d1 + w12;
				
				float s1 = 1 - step(d1, d);
				float3 col = src * s1;

				float s2 = step(d2 + w23, d);
				col += tgt * s2;

				float s3 = step(d2, d);
				s3 *= 1 - s2;
				float3 flame = _FlameColor * d * 5 * noise(100. * uv + float2(-_AnimationTime * 2.0, _AnimationTime * 0.4));
				col += flame * s3;

				return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
