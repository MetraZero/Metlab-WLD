// MET_UI_ZTestAlways
// UI Image (背景パネル) 用の ZTest Always シェーダー。
// Unity の標準 UI/Default は ZTest LEqual のため壁に埋まる。
// このシェーダーは ZTest Always にすることで壁貫通表示を実現する。
//
// Render Queue を Overlay-1 (3999) にすることで
// TMP_SDF Overlay テキスト (Overlay = 4000) より先に描画され
// 背景が文字を上書きしない順序を保証する。
// ※ Transparent 帯 (〜3000) はミラーで描画されないケースがあるため
//    Overlay 帯 (4000 前後) に揃えることでミラーへの映り込みを確保する。
//
// 使い方:
//   1. Project ウィンドウでこのシェーダーを選択
//   2. 背景 Image の Material を新規作成し Shader を "Metlab/UI_ZTestAlways" に設定
//   3. Image コンポーネントの Material にアサイン

Shader "Metlab/UI_ZTestAlways"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp    ("Stencil Comparison", Float) = 8
        _Stencil        ("Stencil ID",         Float) = 0
        _StencilOp      ("Stencil Operation",  Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask  ("Stencil Read Mask",  Float) = 255

        _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue"           = "Overlay-1"        // 3999: TMP_SDF Overlay (4000) より前に描画・ミラー対応
            "IgnoreProjector" = "True"
            "RenderType"      = "Transparent"
            "PreviewType"     = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref       [_Stencil]
            Comp      [_StencilComp]
            Pass      [_StencilOp]
            ReadMask  [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull     Off
        ZWrite   Off
        ZTest    Always         // 壁・オブジェクトを貫通して常に描画
        Blend    SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #pragma target   2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4    _Color;
            fixed4    _TextureSampleAdd;
            float4    _ClipRect;
            float4    _MainTex_ST;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.worldPos = v.vertex;
                OUT.vertex   = UnityObjectToClipPos(OUT.worldPos);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                OUT.color    = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPos.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(color.a - 0.001);
                #endif

                return color;
            }
            ENDCG
        }
    }
}
