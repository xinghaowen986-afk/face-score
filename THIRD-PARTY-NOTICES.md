# 第三方组件声明

本项目的核心人脸关键点检测能力来自 Google 的开源项目 **MediaPipe**。为了做到「下载即可离线运行」，`vendor/` 目录里内置了以下**未经修改**的官方发布文件：

| 文件 | 说明 | 来源 |
| --- | --- | --- |
| `vendor/vision_bundle.mjs` | MediaPipe Tasks Vision 运行时（JS 包） | `@mediapipe/tasks-vision@0.10.14` |
| `vendor/wasm/vision_wasm_internal.js` / `.wasm` | WebAssembly 推理引擎（SIMD 版） | 同上 |
| `vendor/wasm/vision_wasm_nosimd_internal.js` / `.wasm` | WebAssembly 推理引擎（非 SIMD 兼容版） | 同上 |
| `vendor/face_landmarker.task` | Face Landmarker 模型（float16，478 点） | `mediapipe-models/face_landmarker` |

MediaPipe 采用 **Apache License 2.0** 许可：

- 许可证全文：<https://www.apache.org/licenses/LICENSE-2.0>
- 上游项目：<https://github.com/google-ai-edge/mediapipe>
- 版权归属：Copyright 2019 The MediaPipe Authors

以上文件在本仓库中仅作为依赖原样分发，未作修改；具体版本号见 `README.md` 与 `index.html` 中的 `MP_VER` 常量。

---

如果你要**二次分发**本程序，请保留本声明与 Apache-2.0 许可证文本。如果只想复用代码而不需要离线能力，也可以删除 `vendor/` 目录，程序会自动退回到从 CDN 加载 MediaPipe。
