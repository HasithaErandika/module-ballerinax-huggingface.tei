# Ballerina HuggingFace TEI Connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/actions/workflows/trivy-scan.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-huggingface.tei.svg)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/commits/main)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

[HuggingFace Text Embeddings Inference (TEI)](https://huggingface.co/docs/text-embeddings-inference) is a high-throughput, low-latency serving framework for text embedding models, rerankers, and sequence classifiers. It is the engine behind [HuggingFace Inference Endpoints](https://huggingface.co/inference-endpoints) and supports a wide range of popular open models including BGE, Nomic, Jina, GTE, E5, and cross-encoder rerankers.

The `ballerinax/huggingface.tei` connector provides a Ballerina client for the [TEI REST API (v1.5)](https://huggingface.github.io/text-embeddings-inference/), enabling:

| Capability | Endpoint | Use Case |
|---|---|---|
| Dense embeddings | `POST /embed` | Semantic search, RAG retrieval, clustering |
| Token-level embeddings | `POST /embed_all` | Fine-grained representation tasks |
| Sparse embeddings | `POST /embed_sparse` | Hybrid search with SPLADE models |
| Cross-encoder reranking | `POST /rerank` | Second-stage RAG reranking |
| Sequence classification | `POST /predict` | Sentiment, intent, topic classification |
| Sentence similarity | `POST /similarity` | Pairwise semantic similarity scoring |
| Tokenization | `POST /tokenize` | Token counting and pre-flight checks |
| Decoding | `POST /decode` | Convert token IDs back to text |
| OpenAI-compatible embeddings | `POST /v1/embeddings` | Drop-in OpenAI SDK replacement |
| Model info | `GET /info` | Model metadata and server limits |
| Health check | `GET /health` | Liveness probe |
| Metrics | `GET /metrics` | Prometheus metrics scraping |

> **Note:** For LLM text generation and chat completions, see [`ballerinax/huggingface.tgi`](https://central.ballerina.io/ballerinax/huggingface.tgi).

## Setup guide

### Step 1 — Choose a TEI deployment

The connector works with any TEI-compatible endpoint. Choose the option that fits your environment:

**Option A — HuggingFace Inference Endpoints (recommended for production)**

1. Log in to [huggingface.co](https://huggingface.co) and navigate to **Inference Endpoints**.
2. Create a new endpoint, select an embedding model (e.g. `BAAI/bge-base-en-v1.5`), and choose your cloud and hardware.
3. Once deployed, copy the endpoint URL — it will look like:
   ```
   https://<name>.<region>.aws.endpoints.huggingface.cloud
   ```

**Option B — Self-hosted with Docker (recommended for development)**

```bash
docker run --gpus all -p 8080:80 \
  ghcr.io/huggingface/text-embeddings-inference:latest \
  --model-id BAAI/bge-base-en-v1.5
```

For CPU-only:
```bash
docker run -p 8080:80 \
  ghcr.io/huggingface/text-embeddings-inference:cpu-latest \
  --model-id BAAI/bge-base-en-v1.5
```

**Model selection guide:**

| Task | Recommended Models |
|---|---|
| Dense embeddings / semantic search | `BAAI/bge-base-en-v1.5`, `nomic-ai/nomic-embed-text-v1.5`, `thenlper/gte-base` |
| Sparse embeddings (hybrid search) | `prithivida/Splade_PP_en_v1` |
| Reranking | `BAAI/bge-reranker-base`, `cross-encoder/ms-marco-MiniLM-L-6-v2` |
| Classification | `ProsusAI/finbert`, `SamLowe/roberta-base-go_emotions` |

### Step 2 — Obtain an API key (HF Inference Endpoints only)

1. Go to [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens).
2. Click **New token**, select **Read** scope, and copy the token.

> If you are running TEI locally or in a private network without authentication, you can use `"-"` as the API key value or omit it.

### Step 3 — Configure the connector

Create a `Config.toml` file in your Ballerina project root:

```toml
serviceUrl = "https://<your-endpoint>.endpoints.huggingface.cloud"
```

For authenticated endpoints, pass the token as a Bearer header when initialising the client (see Quickstart below).

## Quickstart

### 1. Import the module

```ballerina
import ballerinax/huggingface.tei;
```

### 2. Initialise the client

```ballerina
configurable string serviceUrl = ?;

// Without authentication (local / open endpoint)
tei:Client teiClient = check new ({}, serviceUrl);

// With Bearer token authentication (HF Inference Endpoints)
tei:Client teiClient = check new ({
    auth: {token: "hf_xxxxxxxxxxxxxxxxxxxx"}
}, serviceUrl);
```

### 3. Generate embeddings

```ballerina
import ballerina/io;
import ballerinax/huggingface.tei;

configurable string serviceUrl = ?;

public function main() returns error? {
    tei:Client teiClient = check new ({}, serviceUrl);

    tei:EmbedResponse embeddings = check teiClient->/embed.post({
        inputs: "Ballerina is a cloud-native programming language.",
        normalize: true
    });

    io:println("Embedding dimensions: ", embeddings[0].length());
    io:println("First 5 values: ", embeddings[0].slice(0, 5));
}
```

### 4. Rerank documents

```ballerina
tei:RerankResponse ranked = check teiClient->/rerank.post({
    query: "What is the best language for API integration?",
    texts: [
        "Ballerina is designed for integration.",
        "Python is used for data science.",
        "Ballerina has built-in HTTP and gRPC support."
    ],
    returnText: true
});

// ranked[0] is the most relevant document
io:println("Top result: ", ranked[0].text);
```

### 5. Classify text

```ballerina
tei:PredictResponse result = check teiClient->/predict.post({
    inputs: "This product is absolutely amazing!"
});

if result is tei:Prediction[] {
    io:println("Label: ", result[0].label, " | Score: ", result[0].score);
}
```

## Examples

The `huggingface.tei` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/), covering the following use cases:

| Example | Description |
|---|---|
| [Semantic Search](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/semantic-search) | Embed a query and rank a document corpus by cosine similarity |
| [Document Reranker](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/document-reranker) | Cross-encoder reranking for second-stage RAG retrieval |
| [Text Classifier](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/text-classifier) | Sentiment and intent classification of customer feedback |

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`huggingface.tei` package](https://central.ballerina.io/ballerinax/huggingface.tei/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
