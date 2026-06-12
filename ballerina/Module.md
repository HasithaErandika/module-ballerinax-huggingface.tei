# Overview

[HuggingFace Text Embeddings Inference (TEI)](https://huggingface.co/docs/text-embeddings-inference) is a high-throughput, low-latency serving solution for text embedding models, rerankers, and sequence classifiers. It is the engine powering [HuggingFace Inference Endpoints](https://huggingface.co/inference-endpoints) and supports popular open models such as BGE, Nomic, Jina, GTE, E5, and cross-encoder rerankers.

The `ballerinax/huggingface.tei` package offers APIs to connect with the [TEI REST API v1](https://huggingface.github.io/text-embeddings-inference/), enabling:

| Capability | Endpoint |
|---|---|
| Dense embeddings | `POST /embed` |
| Token-level embeddings | `POST /embed_all` |
| Sparse embeddings | `POST /embed_sparse` |
| Cross-encoder reranking | `POST /rerank` |
| Sequence classification | `POST /predict` |
| Sentence similarity | `POST /similarity` |
| Tokenization | `POST /tokenize` |
| Decoding | `POST /decode` |
| OpenAI-compatible embeddings | `POST /v1/embeddings` |
| Model info | `GET /info` |
| Health check | `GET /health` |
| Prometheus metrics | `GET /metrics` |

> **Note:** For LLM text generation and chat completions, see [`ballerinax/huggingface.tgi`](https://central.ballerina.io/ballerinax/huggingface.tgi).

## Setup guide

To use the `ballerinax/huggingface.tei` connector, you need access to a running TEI instance. Choose the option that fits your environment:

### Option A — HuggingFace Inference Endpoints (recommended for production)

1. Log in to [huggingface.co](https://huggingface.co) and navigate to **Inference Endpoints**.

2. Click **New Endpoint**, select an embedding model (e.g. `BAAI/bge-base-en-v1.5`), and choose your cloud region and hardware.

3. Once deployed, copy the endpoint URL — it will look like:
   ```
   https://<name>.<region>.aws.endpoints.huggingface.cloud
   ```

4. Go to [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens), click **New token**, select **Read** scope, and copy the token.

### Option B — Self-hosted with Docker (recommended for development)

**GPU:**
```bash
docker run --gpus all -p 8080:80 \
  ghcr.io/huggingface/text-embeddings-inference:latest \
  --model-id BAAI/bge-base-en-v1.5
```

**CPU-only:**
```bash
docker run -p 8080:80 \
  ghcr.io/huggingface/text-embeddings-inference:cpu-latest \
  --model-id BAAI/bge-base-en-v1.5
```

> If you are running TEI locally without authentication, the `auth` field in `ConnectionConfig` can be omitted.

**Model selection guide:**

| Task | Recommended Models |
|---|---|
| Dense embeddings / semantic search | `BAAI/bge-base-en-v1.5`, `nomic-ai/nomic-embed-text-v1.5`, `thenlper/gte-base` |
| Sparse embeddings (hybrid search) | `prithivida/Splade_PP_en_v1` |
| Reranking | `BAAI/bge-reranker-base`, `cross-encoder/ms-marco-MiniLM-L-6-v2` |
| Classification | `ProsusAI/finbert`, `SamLowe/roberta-base-go_emotions` |

## Quickstart

To use the `ballerinax/huggingface.tei` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/huggingface.tei;
```

### Step 2: Create a new connector instance

Create a `tei:Client` with your Bearer token and the TEI endpoint URL.

```ballerina
configurable string token = ?;
configurable string serviceUrl = ?;

final tei:Client teiClient = check new ({
    auth: {token}
}, serviceUrl);
```

### Step 3: Invoke the connector operation

Now you can use the available connector operations.

#### Generate dense embeddings

```ballerina
public function main() returns error? {
    tei:EmbedResponse embeddings = check teiClient->/embed.post({
        inputs: "Ballerina is a cloud-native programming language.",
        normalize: true
    });

    // embeddings[0] is the float[] vector for the first input
    int dims = embeddings[0].length();
    io:println("Embedding dimensions: ", dims);
}
```

#### Rerank documents

```ballerina
public function main() returns error? {
    tei:RerankResponse ranked = check teiClient->/rerank.post({
        query: "What is the best language for API integration?",
        texts: [
            "Ballerina is designed for integration.",
            "Python is used for data science.",
            "Ballerina has built-in HTTP and gRPC support."
        ],
        returnText: true
    });

    io:println("Top result: ", ranked[0].text);
}
```

#### Classify text

```ballerina
public function main() returns error? {
    tei:PredictResponse result = check teiClient->/predict.post({
        inputs: "This product is absolutely amazing!"
    });

    if result is tei:Prediction[] {
        io:println("Label: ", result[0].label, " | Score: ", result[0].score);
    }
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The `ballerinax/huggingface.tei` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/), covering the following use cases:

1. [Semantic Search](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/semantic-search) - Embed a query and a document corpus into dense vectors, then rank the documents by cosine similarity to find the most relevant results.

2. [Document Reranker](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/document-reranker) - Use a cross-encoder reranker as the second stage of a RAG pipeline to produce more accurate relevance scores over a set of candidate passages.

3. [Text Classifier](https://github.com/ballerina-platform/module-ballerinax-huggingface.tei/tree/main/examples/text-classifier) - Classify customer feedback into sentiment categories using a sequence classification model and produce a summary report.

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
