Shader "Unlit/ToonShaderReflect"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)									// Edit //

		[HDR]																// Edit // 
		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)				// Edit //

		[HDR]																// EditReflect //
		_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)			// EditReflect //
		_Glossiness("Glossiness", Float) = 32								// EditReflect //

		[HDR]
		_RimColor("Rim Color", Color) = (1,1,1,1)							// EditRim lighting //
		_RimAmount("Rim Amount", Range(0, 1)) = 0.716						// EditRim lighting //

		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1					// EditRim lighting Rim //
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
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
					float3 viewDir : TEXCOORD1;		// EditReflect //
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);			// Edit pos แก้จาก vertex เป็น pos ไม่งั้นจะ Error //
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					UNITY_TRANSFER_FOG(o,o.vertex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);		// Edit // 
					TRANSFER_SHADOW(o)										// Edit	Shadow //
					o.viewDir = WorldSpaceViewDir(v.vertex);				// EditReflect // 
					return o;
				}

				float4 _AmbientColor;										// Edit //
				float4 _Color;												// Edit //

				float _Glossiness;											// EditReflect //
				float4 _SpecularColor;										// EditReflect //

				float4 _RimColor;											// EditRim lighting //
				float _RimAmount;											// EditRim lighting //

				float _RimThreshold;										// EditRim lighting Rim //


				fixed4 frag(v2f i) : SV_Target
				{
					// สิ่งใหม่ที่เพิ่มเข้ามาจะเพิ่มเข้ามาอยู่บรรทัดล่างสุดเสมอ //

					float3 normal = normalize(i.worldNormal);						// Edit // 

					float NdotL = dot(_WorldSpaceLightPos0, normal);				// Edit (ทำให้เกิดเงา แต่เงายังเป็น Gradient) // 
					float shadow = SHADOW_ATTENUATION(i);							// Edit	Shadow //
					float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);		// Edit (ทำให้ Object หรือสีของส่วนเงาไม่เป็น Gradient หรือ แบบ ToonShade และเพิ่ม smoothstep ไว้สำหรับการปรับค่าความเข้มความจาง และ + shadow เข้าไปด้วย) // 


					float3 viewDir = normalize(i.viewDir);												// EditReflect  ทำให้มี Reflect//
					float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);						// EditReflect  ทำให้มี Reflect//
					float NdotH = dot(normal, halfVector);												// EditReflect  ทำให้มี Reflect//
					float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);	// EditReflect  ทำให้มี Reflect//

					float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);			// EditReflect  ทำให้ Reflect เป็นแบบด้าน//
					float4 specular = specularIntensitySmooth * _SpecularColor;							// EditReflect  ทำให้ Reflect เป็นแบบด้าน//

					float4 rimDot = 1 - dot(viewDir, normal);											// EditRim lighting ทำให้ดูเงาวาว/

					float rimIntensity = rimDot * pow(NdotL, _RimThreshold);							// EditRim lighting Rim แสงขอบด้านเดียว (2)//
					rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);		// EditRim lighting Rim แสงขอบด้านเดียว (2)//

					//float rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimDot);	// EditRim lighting แสงขอบ (1)//
					float4 rim = rimIntensity * _RimColor;												// EditRim lighting แสงขอบ (1)//


					float4 light = lightIntensity * _LightColor0;					// Edit (ทำให้ Object รับแสง หรือมีการเปลี่ยนแปลงสี ตามค่าความสว่างหรือสีของ Light) // 

					fixed4 mainTexture = tex2D(_MainTex, i.uv);						// MainTexture //
					// apply fog
					UNITY_APPLY_FOG(i.fogCoord, col);

					return mainTexture * _Color * (_AmbientColor + light + specular + rim);					// Edit Return ค่ากลับไป หรือสั่งให้แสดงผล // 
				}
				ENDCG
			}

			UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"							// Edit Shadow // 
		}
}
