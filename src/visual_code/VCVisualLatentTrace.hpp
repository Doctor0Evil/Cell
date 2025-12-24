// File: src/visual_code/VCVisualLatentTrace.hpp
// Platform: Windows / Linux / macOS / Android / iOS
// Language: C++17+
// Purpose:
//   Unified layout for visual embeddings, latent codes, and trace metadata
//   used by external asset-generation tooling (image, 3D asset, style).
//
//   - Visual encoder → fixed-dimensional embedding for retrieval/conditioning
//   - Latent bundle → image / asset / style latent vectors
//   - Trace record → deterministic metadata for any generated asset
//
//   This header is framework-agnostic: you can plug in any encoder/decoder
//   implementation and keep the vector shapes and IDs stable.

#pragma once

#include <array>
#include <cstdint>
#include <cmath>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>
#include <algorithm>
#include <cstddef>

namespace vcvisual {

/// Dimensional contract for all visual/latent vectors.
/// Adjust with care; treat as a versioned interface.
struct VCVisualDims {
    // Global visual embedding (e.g., CLIP/ViT-style descriptor).
    static constexpr std::size_t VISUAL_EMB_DIM   = 1024;

    // Latent image code (e.g., diffusion UNet latent).
    static constexpr std::size_t LATENT_IMAGE_DIM = 256;

    // Latent 3D asset code (e.g., mesh/NeRF/point-cloud latent).
    static constexpr std::size_t LATENT_ASSET_DIM = 384;

    // Style code (palette, texture, lighting, camera mood).
    static constexpr std::size_t LATENT_STYLE_DIM = 64;

    // Compact “trace” vector for similarity search / indexing.
    static constexpr std::size_t TRACE_VECTOR_DIM = 128;
};

/// Fixed-size 1D float vector wrapper.
class VCFloatVec {
public:
    VCFloatVec() = default;

    explicit VCFloatVec(std::size_t dim)
        : data_(dim, 0.0f) {}

    std::size_t dim() const noexcept { return data_.size(); }

    float &operator[](std::size_t i) {
        if (i >= data_.size()) {
            throw std::out_of_range("VCFloatVec index out of range");
        }
        return data_[i];
    }

    const float &operator[](std::size_t i) const {
        if (i >= data_.size()) {
            throw std::out_of_range("VCFloatVec index out of range");
        }
        return data_[i];
    }

    std::vector<float> &data() noexcept { return data_; }
    const std::vector<float> &data() const noexcept { return data_; }

    void clear() noexcept {
        if (!data_.empty()) {
            std::fill(data_.begin(), data_.end(), 0.0f);
        }
    }

    void normalize_l2() noexcept {
        if (data_.empty()) {
            return;
        }
        long double acc = 0.0L;
        for (float v : data_) {
            acc += static_cast<long double>(v) * static_cast<long double>(v);
        }
        if (acc <= 0.0L) {
            return;
        }
        const long double inv_ld = 1.0L / std::sqrt(acc);
        const float inv = static_cast<float>(inv_ld);
        for (float &v : data_) {
            v *= inv;
        }
    }

private:
    std::vector<float> data_;
};

/// Visual encoder output: one global embedding plus optional patch tokens.
struct VCVisualEmbedding {
    VCFloatVec global;                   // [VISUAL_EMB_DIM]
    std::vector<VCFloatVec> patch_tokens;

    VCVisualEmbedding()
        : global(VCVisualDims::VISUAL_EMB_DIM) {}
};

/// Latent bundle for downstream generators/decoders.
struct VCLatentBundle {
    VCFloatVec image_latent;  // [LATENT_IMAGE_DIM]
    VCFloatVec asset_latent;  // [LATENT_ASSET_DIM]
    VCFloatVec style_latent;  // [LATENT_STYLE_DIM]

    VCLatentBundle()
        : image_latent(VCVisualDims::LATENT_IMAGE_DIM),
          asset_latent(VCVisualDims::LATENT_ASSET_DIM),
          style_latent(VCVisualDims::LATENT_STYLE_DIM) {}
};

/// Trace record for any generated asset (image or 3D).
/// Intended to be serialized as sidecar metadata (JSON, protobuf, etc.).
struct VCVisualTrace {
    // Stable IDs for reproducibility / provenance.
    std::string request_id;        // External request UUID.
    std::string parent_asset_id;   // Optional upstream asset or source ID.
    std::string generator_model;   // e.g., "Cell-XL-UNet-v2".
    std::string encoder_model;     // e.g., "VC-ViT-Base-1024".

    // Input prompt (sanitize prior to storage).
    std::string text_prompt;

    // Conditioning from reference imagery.
    VCVisualEmbedding visual_input;

    // Latent bundle used for decoding.
    VCLatentBundle latents;

    // Compact trace vector for similarity search / indexing.
    VCFloatVec trace_vector { VCVisualDims::TRACE_VECTOR_DIM };

    // Numeric parameters.
    int   seed           = 0;
    int   width          = 0;
    int   height         = 0;
    float guidance_scale = 0.0f;
    int   diffusion_steps = 0;
};

/// Interface: visual encoder (backed by any CNN/ViT implementation).
class IVisualEncoder {
public:
    virtual ~IVisualEncoder() = default;

    // Encode raw RGB image data (HWC, uint8).
    // image_rgb length must be width * height * 3.
    virtual VCVisualEmbedding encode(
        const std::uint8_t* image_rgb,
        int width,
        int height,
        int stride_bytes = 0) const = 0;
};

/// Interface: latent generator (embeddings → latent bundle).
class ILatentGenerator {
public:
    virtual ~ILatentGenerator() = default;

    // text_vec is a precomputed text embedding (e.g., CLIP text tower).
    virtual VCLatentBundle generate_latents(
        const VCVisualEmbedding& visual_emb,
        const VCFloatVec& text_vec,
        int seed) const = 0;
};

/// Interface: image decoder (latent → RGBA).
class IImageDecoder {
public:
    virtual ~IImageDecoder() = default;

    // Decode image latent + style into an RGBA buffer (resized to width*height*4).
    virtual void decode_image(
        const VCLatentBundle& latents,
        int width,
        int height,
        std::vector<std::uint8_t>& out_rgba) const = 0;
};

/// Interface: 3D asset decoder (latent → serialized asset bytes).
class IAssetDecoder {
public:
    virtual ~IAssetDecoder() = default;

    // Decode asset latent to a serialized asset (e.g., GLB / USDZ).
    virtual void decode_asset(
        const VCLatentBundle& latents,
        std::vector<std::uint8_t>& out_asset_bytes) const = 0;
};

/// High-level orchestration: encode → latents → decode → trace.
class VCVisualTracePipeline {
public:
    VCVisualTracePipeline(
        const IVisualEncoder* encoder,
        const ILatentGenerator* latent_gen,
        const IImageDecoder*    image_decoder,
        const IAssetDecoder*    asset_decoder) noexcept
        : encoder_(encoder),
          latent_gen_(latent_gen),
          image_decoder_(image_decoder),
          asset_decoder_(asset_decoder) {}

    VCVisualTrace run(
        const std::uint8_t* image_rgb,
        int img_w,
        int img_h,
        const VCFloatVec& text_vec,
        std::string text_prompt,
        std::string request_id,
        int seed,
        bool want_image,
        bool want_asset,
        int out_width,
        int out_height,
        std::vector<std::uint8_t>& image_rgba_out,
        std::vector<std::uint8_t>& asset_bytes_out) const
    {
        if (!encoder_ || !latent_gen_) {
            throw std::runtime_error("VCVisualTracePipeline: encoder and latent generator must be non-null");
        }

        VCVisualTrace trace;
        trace.request_id    = std::move(request_id);
        trace.text_prompt   = std::move(text_prompt);
        trace.seed          = seed;
        trace.width         = out_width;
        trace.height        = out_height;

        // 1) Visual encoding.
        trace.visual_input = encoder_->encode(image_rgb, img_w, img_h, 0);
        trace.visual_input.global.normalize_l2();

        // 2) Latent generation.
        trace.latents = latent_gen_->generate_latents(trace.visual_input, text_vec, seed);

        // 3) Optional decoding to image.
        if (want_image && image_decoder_) {
            image_decoder_->decode_image(trace.latents, out_width, out_height, image_rgba_out);
        } else {
            image_rgba_out.clear();
        }

        // 4) Optional decoding to 3D asset.
        if (want_asset && asset_decoder_) {
            asset_decoder_->decode_asset(trace.latents, asset_bytes_out);
        } else {
            asset_bytes_out.clear();
        }

        // 5) Build deterministic trace vector.
        build_trace_vector(trace);

        return trace;
    }

private:
    const IVisualEncoder*  encoder_       = nullptr;
    const ILatentGenerator* latent_gen_   = nullptr;
    const IImageDecoder*   image_decoder_ = nullptr;
    const IAssetDecoder*   asset_decoder_ = nullptr;

    static void build_trace_vector(VCVisualTrace& trace) {
        VCFloatVec& tv = trace.trace_vector;
        const std::size_t D = tv.dim();
        if (D == 0U) {
            return;
        }

        tv.clear();

        const auto& vis = trace.visual_input.global.data();
        const auto& img = trace.latents.image_latent.data();
        const auto& as  = trace.latents.asset_latent.data();
        const auto& st  = trace.latents.style_latent.data();

        const std::size_t vis_dim = vis.size();
        const std::size_t img_dim = img.size();
        const std::size_t as_dim  = as.size();
        const std::size_t st_dim  = st.size();

        // Mix visual embedding.
        for (std::size_t i = 0; i < D && i < vis_dim; ++i) {
            tv.data()[i] += vis[i];
        }

        // Mix image latent.
        for (std::size_t i = 0; i < D && i < img_dim; ++i) {
            tv.data()[i] += 0.5f * img[i];
        }

        // Mix asset latent.
        for (std::size_t i = 0; i < D && i < as_dim; ++i) {
            tv.data()[i] += 0.5f * as[i];
        }

        // Mix style latent (wrap if needed).
        if (D > 0U) {
            for (std::size_t i = 0; i < st_dim; ++i) {
                const std::size_t idx = i % D;
                tv.data()[idx] += 0.25f * st[i];
            }
        }

        tv.normalize_l2();
    }
};

} // namespace vcvisual
