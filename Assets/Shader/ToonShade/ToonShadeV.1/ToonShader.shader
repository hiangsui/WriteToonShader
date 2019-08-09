Shader "Unlit/UnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)									// Edit //

		[HDR]																// Edit // 
		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)				// Edit //
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
			#pragma multi_compile_fwdbase	// Edit // 

            #include "UnityCG.cginc"
			#include "Lighting.cginc"		// Edit // 
			#include "AutoLight.cginc"		// Edit // 

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;		// Edit // 
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;		// Edit pos แก้จาก vertex เป็น pos ไม่งั้นจะ Error //
				float3 worldNormal : NORMAL;	// Edit // 
				SHADOW_COORDS(2)				// Edit	Shadow //
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);			// Edit pos แก้จาก vertex เป็น pos ไม่งั้นจะ Error //
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);		// Edit // 
				TRANSFER_SHADOW(o)										// Edit	Shadow //
                return o;
            }

			float4 _AmbientColor;										// Edit //
			float4 _Color;												// Edit //


            fixed4 frag (v2f i) : SV_Target
            {
				// สิ่งใหม่ที่เพิ่มเข้ามาจะเพิ่มเข้ามาอยู่บรรทัดล่างสุดเสมอ //

				float3 normal = normalize(i.worldNormal);						// Edit // 
				float NdotL = dot(_WorldSpaceLightPos0, normal);				// Edit (ทำให้เกิดเงา แต่เงายังเป็น Gradient) // 
				float shadow = SHADOW_ATTENUATION(i);							// Edit	Shadow //
				float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);		// Edit (ทำให้ Object หรือสีของส่วนเงาไม่เป็น Gradient หรือ แบบ ToonShade และเพิ่ม smoothstep ไว้สำหรับการปรับค่าความเข้มความจาง และ + shadow เข้าไปด้วย) // 
				float4 light = lightIntensity * _LightColor0;					// Edit (ทำให้ Object รับแสง หรือมีการเปลี่ยนแปลงสี ตามค่าความสว่างหรือสีของ Light) // 

                fixed4 mainTexture = tex2D(_MainTex, i.uv);						// MainTexture //
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return mainTexture * _Color * (_AmbientColor + light);					// Edit Return ค่ากลับไป หรือสั่งให้แสดงผล // 
            }
            ENDCG
        }

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"							// Edit // 
    }
}
