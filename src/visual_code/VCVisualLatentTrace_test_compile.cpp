// File: src/visual_code/VCVisualLatentTrace_test_compile.cpp
// Purpose: Minimal compile-time check for VCVisualLatentTrace.hpp.
// This file is not linked into the game; it only verifies the header compiles.

#include "VCVisualLatentTrace.hpp"

using namespace vcvisual;

class DummyEncoder final : public IVisualEncoder {
public:
    VCVisualEmbedding encode(
        const std::uint8_t* image_rgb,
        int width,
        int height,
        int stride_bytes = 0) const override
    {
        (void)image_rgb;
        (void)width;
        (void)height;
        (void)stride_bytes;
        VCVisualEmbedding emb;
        return emb;
    }
};

class DummyLatentGen final : public ILatentGenerator {
public:
    VCLatentBundle generate_latents(
        const VCVisualEmbedding& visual_emb,
        const VCFloatVec& text_vec,
        int seed) const override
    {
        (void)visual_emb;
        (void)text_vec;
        (void)seed;
        VCLatentBundle bundle;
        return bundle;
    }
};

class DummyImageDec final : public IImageDecoder {
public:
    void decode_image(
        const VCLatentBundle& latents,
        int width,
        int height,
        std::vector<std::uint8_t>& out_rgba) const override
    {
        (void)latents;
        out_rgba.assign(static_cast<std::size_t>(width * height * 4), 0);
    }
};

class DummyAssetDec final : public IAssetDecoder {
public:
    void decode_asset(
        const VCLatentBundle& latents,
        std::vector<std::uint8_t>& out_asset_bytes) const override
    {
        (void)latents;
        out_asset_bytes.clear();
    }
};

static int test_vcfloatvec()
{
    VCFloatVec v(4);
    v[0] = 1.0f;
    v[1] = 2.0f;
    v[2] = 2.0f;
    v[3] = 1.0f;
    v.normalize_l2();
    // Norm should be ~1; tolerate small error.
    long double acc = 0.0L;
    for (std::size_t i = 0; i < v.dim(); ++i) {
        acc += static_cast<long double>(v[i]) * static_cast<long double>(v[i]);
    }
    return (acc > 0.999L && acc < 1.001L) ? 0 : 1;
}

int main()
{
    DummyEncoder    enc;
    DummyLatentGen  gen;
    DummyImageDec   img_dec;
    DummyAssetDec   asset_dec;

    VCVisualTracePipeline pipeline(&enc, &gen, &img_dec, &asset_dec);

    std::vector<std::uint8_t> dummy_rgb(16 * 16 * 3, 0);
    VCFloatVec text_vec(VCVisualDims::VISUAL_EMB_DIM);
    std::vector<std::uint8_t> out_rgba;
    std::vector<std::uint8_t> out_asset;

    auto trace = pipeline.run(
        dummy_rgb.data(),
        16,
        16,
        text_vec,
        "test prompt",
        "test-request-id",
        42,
        true,
        true,
        32,
        32,
        out_rgba,
        out_asset
    );

    int rc = 0;
    rc |= (trace.trace_vector.dim() == VCVisualDims::TRACE_VECTOR_DIM) ? 0 : 1;
    rc |= test_vcfloatvec();
    return rc;
}
