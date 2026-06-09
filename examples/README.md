# Examples

The `ballerinax/huggingface.tei` connector provides practical examples illustrating usage in various scenarios.

1. [Semantic Search](./semantic-search) - Embed a query and rank a document corpus by cosine similarity.
2. [Document Reranker](./document-reranker) - Cross-encoder reranking for second-stage RAG retrieval.
3. [Text Classifier](./text-classifier) - Sentiment and intent classification of customer feedback.

## Prerequisites

- Ballerina Swan Lake (Update 13 or later) installed.
- A running HuggingFace Text Embeddings Inference (TEI) instance.
- A `Config.toml` file in the example directory with the target `serviceUrl`.

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
