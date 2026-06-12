# Tests — `ballerinax/huggingface.tei`

This directory contains the test suite for the `huggingface.tei` Ballerina connector.

## Structure

| File | Purpose |
|---|---|
| `mock_service.bal` | An in-process HTTP mock that replicates every TEI endpoint. Tests run against this mock — no live HuggingFace endpoint required. |
| `test.bal` | All `@test:Config` test functions, covering every resource: embed, embed_all, embed_sparse, rerank, predict, similarity, tokenize, decode, v1/embeddings, info, health, metrics. |
| `Config.toml` | Local test configuration. **Not committed with real tokens.** |

## Running the tests

```bash
# From the ballerina/ directory:
bal test
```

To run a specific group:

```bash
bal test --groups embed
bal test --groups rerank
bal test --groups predict
bal test --groups similarity
bal test --groups tokenize
bal test --groups decode
bal test --groups openai_compat
bal test --groups info
bal test --groups health
bal test --groups metrics
bal test --groups types
```

## Configuration

The tests target the mock listener on `http://localhost:9091` by default. The `token` config value is required by the client constructor but is not validated by the mock service — any non-empty string works locally.

Create or update `Config.toml` in this directory:

```toml
token = "<YOUR_HF_TOKEN>"
```

> For CI, the `token` secret is injected via GitHub Actions secrets. Do **not** commit a real token.

## Mock service

The mock service (`mock_service.bal`) starts an `http:Listener` on port `9091` and returns hardcoded but structurally valid JSON responses for every TEI endpoint. This approach lets the full test suite run offline and without a GPU, making it safe for CI and local development alike.
