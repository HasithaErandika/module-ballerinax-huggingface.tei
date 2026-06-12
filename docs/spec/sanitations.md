_Author_: @ballerina-platform \
_Created_: 2026-06-10 \
_Updated_: 2026-06-12 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitations done on top of the official OpenAPI specification from Hugging Face TEI.
These changes are done in order to improve the overall usability, fix compilation errors caused by OpenAPI generator bugs, and support authentication.

## Sanitized Details

1. **Enum Default Value Case Fix**
   - The type `TruncationDirection` was generated as a union `"Left"|"Right"`, but record defaults used the lowercase `"right"`. This caused type-mismatch compilation errors.
   - Fixed the default value of `truncationDirection` from `"right"` to `"Right"` in:
     - `PredictRequest`
     - `EmbedRequest`
     - `EmbedSparseRequest`
     - `RerankRequest`
     - `SimilarityParameters`
     - `EmbedAllRequest`

2. **Nullable Field Defaults**
   - The OpenAPI generator output string `"null"` instead of Ballerina nil (`()`) for default values of optional nullable fields.
   - Changed default values from `"null"` to `()` in:
     - `SimilarityRequest.parameters`
     - `Rank.text`
     - `EmbedRequest.promptName`
     - `EmbedSparseRequest.promptName`
     - `EmbedAllRequest.promptName`
     - `SimilarityParameters.promptName`
     - `TokenizeRequest.promptName`

3. **Dead Union Type Removal**
   - Removed the dead and semantically broken type `PredictInputPredictInputPredictInputOneOf123Itemsnull` which was generated as `string[]|string[]` and never referenced.

4. **Type Renaming for Readability**
   - Renamed obscure generated types to clean, developer-friendly names:
     - `PredictResponseOneOf1` -> `SingleLabelPredictions`
     - `PredictResponsePredictResponseOneOf12` -> `BatchLabelPredictions`
     - `PredictResponse` is now a union of `SingleLabelPredictions|BatchLabelPredictions`.

5. **Authentication Support**
   - The OpenAPI generator omits the `auth` field from `ConnectionConfig`. It has been added manually as:
     ```ballerina
     http:BearerTokenConfig|http:OAuth2ClientCredentialsGrantConfig auth?;
     ```
     This is consistent with the pattern used across other `ballerinax` connectors and allows callers to pass a HuggingFace Bearer token when targeting authenticated Inference Endpoints.
   - `client.bal`'s `init` function passes `config.auth` through to `http:ClientConfiguration.auth`.

6. **`init` Signature Convention Alignment**
   - Flipped the `init` parameter order from `(string serviceUrl, ConnectionConfig config = {})` to
   `(ConnectionConfig config, string serviceUrl = "https://api-inference.huggingface.co")`.
   - This matches the established convention across other `ballerinax` connectors and gives callers a sensible default URL for the HuggingFace Inference API.

7. **Resource Documentation Update**
   - Added 424 status code documentation to `embed_all` resource function in `client.bal`.

## OpenAPI CLI Command

The following command was used to generate the Ballerina client from the OpenAPI specification:

```bash
bal openapi -i docs/spec/openapi.json --mode client -o ballerina
```
