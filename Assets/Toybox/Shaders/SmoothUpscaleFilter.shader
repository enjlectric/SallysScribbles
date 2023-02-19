Shader "EnjlBox/SmoothUpscaleFilter"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Enabled ("Enabled", float) = 1

        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }
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
            float _Enabled;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float4 texture2DAA(sampler2D tex, float2 uv, float2 texsize) {
                float2 uv_texspace = uv*texsize;
                float2 seam = floor(uv_texspace+.5);
                uv_texspace = (uv_texspace-seam)/fwidth(uv_texspace)+seam;
                uv_texspace = clamp(uv_texspace, seam-.5, seam+.5);
                float2 div = uv_texspace/texsize;
                return tex2D(tex, uv);
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                if (_Enabled > 0.5) {
                    
                    fixed4 col = texture2DAA(_MainTex, i.uv, _MainTex_TexelSize.zw);
                    // apply fog
                    UNITY_APPLY_FOG(i.fogCoord, col);
                    return col;
                } else {
                    fixed4 col = tex2D(_MainTex, i.uv);
                    // apply fog
                    UNITY_APPLY_FOG(i.fogCoord, col);
                    return col;
                }
            }
            ENDCG
        }
    }
}
