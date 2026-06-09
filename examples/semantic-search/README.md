# TEI Semantic Search Example

This example demonstrates how to use the HuggingFace TEI connector to generate dense embeddings for a query and a set of documents, and perform semantic search using Cosine Similarity.

## Prerequisites

- A running TEI instance with an embedding model (e.g. `BAAI/bge-base-en-v1.5`).
- A `Config.toml` file in the example directory specifying the endpoint:
  ```toml
  serviceUrl = "http://localhost:8080"
  ```

## Running the Example

Run the following command to execute the example:

```bash
bal run
```
