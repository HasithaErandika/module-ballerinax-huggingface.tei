# TEI Document Reranker Example

This example demonstrates how to use the HuggingFace TEI connector's `/rerank` endpoint to perform second-stage reranking on a list of candidate documents relative to a query using a cross-encoder model.

## Prerequisites

- A running TEI instance with a reranking model (e.g. `BAAI/bge-reranker-base`).
- A `Config.toml` file in the example directory specifying the endpoint:
  ```toml
  serviceUrl = "http://localhost:8080"
  ```

## Running the Example

Run the following command to execute the example:

```bash
bal run
```
