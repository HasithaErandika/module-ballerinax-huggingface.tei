# TEI Text Classifier Example

This example demonstrates how to use the HuggingFace TEI connector's `/predict` endpoint for zero-shot text classification (sentiment analysis) on customer feedback items.

## Prerequisites

- A running TEI instance with a classification model (e.g. `SamLowe/roberta-base-go_emotions` or `ProsusAI/finbert`).
- A `Config.toml` file in the example directory specifying the endpoint:
  ```toml
  serviceUrl = "http://localhost:8080"
  ```

## Running the Example

Run the following command to execute the example:

```bash
bal run
```
