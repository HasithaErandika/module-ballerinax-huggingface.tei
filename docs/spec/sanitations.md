_Author_: @HasithaErandika \
_Created_: 2026-06-10 \
_Updated_: 2026-06-10 \
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
   - Added the `auth` field back to `ConnectionConfig` (which was omitted by the generator) to support Hugging Face Inference Endpoint authentication.
   - Configured `client.bal`'s `init` function to pass `auth` down to the HTTP client's configurations.

6. **Resource Documentation Update**
   - Added 424 status code documentation to `embed_all` resource function in `client.bal`.

## OpenAPI CLI Command

The following command was used to generate the Ballerina client from the OpenAPI specification:

```bash
bal openapi -i docs/spec/openapi.json --mode client -o ballerina
```
