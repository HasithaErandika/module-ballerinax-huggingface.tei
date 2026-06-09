// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com)
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific
// language governing permissions and limitations under the License.

import ballerina/http;
import ballerina/io;
import ballerina/test;

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
configurable string serviceUrl = "http://localhost:8080";
configurable string token = ?;

// ---------------------------------------------------------------------------
// Mock HTTP listener
// ---------------------------------------------------------------------------
listener http:Listener mockListener = new (9091);

service / on mockListener {

    // POST /embed
    resource function post embed(http:Caller caller, http:Request req) returns error? {
        // EmbedResponse = float[][] — one embedding vector per input
        json payload = [[0.12, -0.34, 0.56, 0.78, -0.91]];
        check caller->respond(payload);
    }

    // POST /embed_all
    resource function post embed_all(http:Caller caller, http:Request req) returns error? {
        // EmbedAllResponse = float[][][] — token-level embeddings
        json payload = [[[0.1, 0.2], [0.3, 0.4]], [[0.5, 0.6]]];
        check caller->respond(payload);
    }

    // POST /embed_sparse
    resource function post embed_sparse(http:Caller caller, http:Request req) returns error? {
        // EmbedSparseResponse = SparseValue[][]
        json payload = [[{"index": 42, "value": 0.87}, {"index": 100, "value": 0.43}]];
        check caller->respond(payload);
    }

    // POST /rerank
    resource function post rerank(http:Caller caller, http:Request req) returns error? {
        // RerankResponse = Rank[]
        json payload = [
            {"score": 0.9821, "index": 0, "text": "Ballerina is a cloud-native language."},
            {"score": 0.6543, "index": 2, "text": "Python is used for data science."},
            {"score": 0.3210, "index": 1, "text": "Kubernetes orchestrates containers."}
        ];
        check caller->respond(payload);
    }

    // POST /predict  — single-input returns Prediction[]
    resource function post predict(http:Caller caller, http:Request req) returns error? {
        json payload = [
            {"label": "POSITIVE", "score": 0.9512},
            {"label": "NEGATIVE", "score": 0.0312},
            {"label": "NEUTRAL",  "score": 0.0176}
        ];
        check caller->respond(payload);
    }

    // POST /similarity
    resource function post similarity(http:Caller caller, http:Request req) returns error? {
        // SimilarityResponse = float[]
        json payload = [0.9231, 0.4512, 0.1023];
        check caller->respond(payload);
    }

    // POST /tokenize
    resource function post tokenize(http:Caller caller, http:Request req) returns error? {
        // TokenizeResponse = SimpleToken[][]
        json payload = [
            [
                {"id": 1,   "text": "hello", "start": 0,  "stop": 5,  "special": false},
                {"id": 2,   "text": " world","start": 5,  "stop": 11, "special": false},
                {"id": 2,   "text": "</s>",  "start": 11, "stop": 14, "special": true}
            ]
        ];
        check caller->respond(payload);
    }

    // POST /decode
    resource function post decode(http:Caller caller, http:Request req) returns error? {
        // DecodeResponse = string[]
        json payload = ["hello world"];
        check caller->respond(payload);
    }

    // POST /v1/embeddings  (OpenAI-compatible)
    resource function post v1/embeddings(http:Caller caller, http:Request req) returns error? {
        json payload = {
            "object": "list",
            "model": "mock-embed-model",
            "data": [
                {"index": 0, "object": "embedding", "embedding": [0.12, -0.34, 0.56]}
            ],
            "usage": {"prompt_tokens": 4, "total_tokens": 4}
        };
        check caller->respond(payload);
    }

    // GET /info
    resource function get info(http:Caller caller, http:Request req) returns error? {
        json payload = {
            "model_id": "BAAI/bge-base-en-v1.5",
            "model_sha": "abc123",
            "model_dtype": "float32",
            "model_type": {"embedding": {"pooling": "mean"}},
            "max_concurrent_requests": 512,
            "max_input_length": 512,
            "max_batch_tokens": 4096,
            "max_client_batch_size": 32,
            "tokenization_workers": 4,
            "version": "1.5.0",
            "sha": "def456",
            "docker_label": "latest",
            "auto_truncate": false,
            "served_model_name": "bge-base-en-v1.5"
        };
        check caller->respond(payload);
    }

    // GET /health
    resource function get health(http:Caller caller, http:Request req) returns error? {
        check caller->respond(http:STATUS_OK);
    }

    // GET /metrics
    resource function get metrics(http:Caller caller, http:Request req) returns error? {
        check caller->respond(
            "# HELP tei_embed_count Total embeddings\n" +
            "# TYPE tei_embed_count counter\n" +
            "tei_embed_count 128\n"
        );
    }
}


// Client initialisation (mock)
Client teiClient = check new ("http://localhost:9091", {
    auth: {
        token: token
    }
});

// Health check  —  GET /health
@test:Config {groups: ["health"]}
function testHealthCheck() returns error? {
    error? result = teiClient->/health();
    if result is error {
        io:println("Health check failed with error: ", result.message(), " | Detail: ", result.detail().toString());
    }
    test:assertTrue(result is (), "Health check should return nil on success");
}

// Model info - GET /info
@test:Config {groups: ["info"]}
function testGetInfo() returns error? {
    Info info = check teiClient->/info();
    test:assertNotEquals(info.modelId, "", "modelId should not be empty");
    test:assertTrue(info.maxInputLength > 0, "maxInputLength should be positive");
    test:assertTrue(info.maxBatchTokens > 0, "maxBatchTokens should be positive");
    test:assertTrue(info.maxConcurrentRequests > 0, "maxConcurrentRequests should be positive");
    io:println("Model: ", info.modelId, " | dtype: ", info.modelDtype);
}

// Dense embeddings - POST /embed  (single string input)
@test:Config {groups: ["embed"]}
function testEmbedSingleString() returns error? {
    EmbedRequest req = {
        inputs: "What is Ballerina?",
        normalize: true,
        truncate: false
    };
    EmbedResponse resp = check teiClient->/embed.post(req);
    test:assertTrue(resp.length() > 0, "Should return at least one embedding vector");
    test:assertTrue(resp[0].length() > 0, "Embedding vector should have dimensions");
    io:println("Embedding dims: ", resp[0].length());
}

// Dense embeddings - POST /embed  (batch input)
@test:Config {groups: ["embed"]}
function testEmbedBatch() returns error? {
    // Input can be InputType[] (batch)
    EmbedRequest req = {
        inputs: ["Ballerina is great", "Python is popular", "Go is fast"],
        normalize: true
    };
    EmbedResponse resp = check teiClient->/embed.post(req);
    test:assertTrue(resp.length() > 0, "Batch should return at least one vector");
}

// Dense embeddings - POST /embed  (with prompt_name)
@test:Config {groups: ["embed"]}
function testEmbedWithPromptName() returns error? {
    EmbedRequest req = {
        inputs: "What is deep learning?",
        normalize: true,
        promptName: "query"  // e.g. for models like E5 that use prompt prefixes
    };
    EmbedResponse resp = check teiClient->/embed.post(req);
    test:assertTrue(resp.length() > 0, "Should return embeddings with prompt_name");
}

// Dense embeddings - POST /embed  (with dimensions truncation)
@test:Config {groups: ["embed"]}
function testEmbedWithDimensions() returns error? {
    EmbedRequest req = {
        inputs: "Matryoshka embedding test",
        normalize: true,
        dimensions: 3   // request reduced dimensions
    };
    EmbedResponse resp = check teiClient->/embed.post(req);
    test:assertTrue(resp.length() > 0, "Should return embeddings with reduced dims");
}

// Embed all (no pooling) - POST /embed_all
@test:Config {groups: ["embed"]}
function testEmbedAll() returns error? {
    EmbedAllRequest req = {
        inputs: "token level embeddings",
        truncate: false,
        truncationDirection: "Right"
    };
    EmbedAllResponse resp = check teiClient->/embed_all.post(req);
    // EmbedAllResponse = float[][][] — [batch][token][dim]
    test:assertTrue(resp.length() > 0, "Should return token-level embedding array");
    test:assertTrue(resp[0].length() > 0, "Should have at least one token embedding");
    io:println("Token count: ", resp[0].length(), " | Dims: ", resp[0][0].length());
}

// Sparse embeddings - POST /embed_sparse
@test:Config {groups: ["embed"]}
function testEmbedSparse() returns error? {
    EmbedSparseRequest req = {
        inputs: "SPLADE sparse embedding test",
        truncate: false
    };
    EmbedSparseResponse resp = check teiClient->/embed_sparse.post(req);
    // EmbedSparseResponse = SparseValue[][]
    test:assertTrue(resp.length() > 0, "Should return sparse embedding response");
    test:assertTrue(resp[0].length() > 0, "Should have at least one sparse value");

    SparseValue first = resp[0][0];
    test:assertTrue(first.index >= 0, "Sparse index should be non-negative");
    test:assertTrue(first.value > 0.0, "Sparse value should be positive");
    io:println("Sparse values returned: ", resp[0].length());
}

// Reranking - POST /rerank  (without text)
@test:Config {groups: ["rerank"]}
function testRerankBasic() returns error? {
    RerankRequest req = {
        query: "How does Ballerina handle HTTP?",
        texts: [
            "Ballerina has first-class HTTP client support.",
            "Kubernetes orchestrates containers.",
            "Ballerina supports REST, gRPC, and WebSockets."
        ],
        returnText: false
    };
    RerankResponse resp = check teiClient->/rerank.post(req);
    test:assertTrue(resp.length() > 0, "Should return ranked results");

    // Verify all ranks have required fields
    foreach Rank rank in resp {
        test:assertTrue(rank.index >= 0, "Rank index should be non-negative");
        test:assertTrue(rank.score >= 0.0 && rank.score <= 1.0,
            "Score should be between 0 and 1");
    }
}

// Reranking - POST /rerank (with text returned)
@test:Config {groups: ["rerank"]}
function testRerankWithText() returns error? {
    RerankRequest req = {
        query: "What is integration programming?",
        texts: [
            "Ballerina is a cloud-native integration language.",
            "Python is a general-purpose language.",
            "Ballerina has built-in HTTP, Kafka, and gRPC support."
        ],
        returnText: true
    };
    RerankResponse resp = check teiClient->/rerank.post(req);
    test:assertTrue(resp.length() > 0, "Should return at least one rank");

    // When returnText=true, text field should be populated
    Rank topRank = resp[0];
    test:assertTrue(topRank.text != "null" && topRank.text != (),
        "text should be populated when returnText=true");
    io:println("Top ranked doc: ", topRank.text);
}

// Reranking - raw scores
@test:Config {groups: ["rerank"]}
function testRerankRawScores() returns error? {
    RerankRequest req = {
        query: "test query",
        texts: ["doc one", "doc two"],
        rawScores: true,
        returnText: false
    };
    RerankResponse resp = check teiClient->/rerank.post(req);
    test:assertTrue(resp.length() > 0, "Should return results with raw scores");
}

// Predict (classification)  —  single string input
@test:Config {groups: ["predict"]}
function testPredictSingleString() returns error? {
    PredictRequest req = {
        inputs: "This connector is absolutely fantastic!",
        truncate: false,
        rawScores: false
    };
    PredictResponse resp = check teiClient->/predict.post(req);

    // PredictResponse = Prediction[] | Prediction[][]
    if resp is Prediction[] {
        test:assertTrue(resp.length() > 0, "Should return at least one prediction");
        Prediction top = resp[0];
        test:assertNotEquals(top.label, "", "Label should not be empty");
        test:assertTrue(top.score >= 0.0, "Score should be non-negative");
        io:println("Top label: ", top.label, " score: ", top.score);
    } else {
        // Batch response — still valid
        test:assertTrue(resp.length() > 0, "Batch predict should return results");
    }
}

// Predict  —  raw scores flag
@test:Config {groups: ["predict"]}
function testPredictRawScores() returns error? {
    PredictRequest req = {
        inputs: "Neutral statement about the weather.",
        rawScores: true,
        truncate: false
    };
    PredictResponse resp = check teiClient->/predict.post(req);
    test:assertTrue(resp is Prediction[] || resp is Prediction[][],
        "Should return a valid PredictResponse");
}

// Predict  —  truncation enabled
@test:Config {groups: ["predict"]}
function testPredictWithTruncation() returns error? {
    string longInput = "";
    foreach int i in 0 ..< 200 {
        longInput += "word ";
    } 
    PredictRequest req = {
        inputs: longInput,
        truncate: true,
        truncationDirection: "Right"
    };
    PredictResponse resp = check teiClient->/predict.post(req);
    test:assertTrue(resp is Prediction[] || resp is Prediction[][],
        "Should handle truncated input");
}

// Sentence similarity - POST /similarity
@test:Config {groups: ["similarity"]}
function testSimilarity() returns error? {
    SimilarityRequest req = {
        inputs: {
            sourceSentence: "Ballerina is great for cloud-native integration.",
            sentences: [
                "Ballerina excels at API integration tasks.",
                "Python is popular for data science.",
                "Kubernetes manages containerised workloads."
            ]
        }
    };
    SimilarityResponse resp = check teiClient->/similarity.post(req);
    // SimilarityResponse = float[]
    test:assertTrue(resp.length() > 0, "Should return similarity scores");
    test:assertEquals(resp.length(), 3, "Should return one score per sentence");

    foreach float score in resp {
        test:assertTrue(score >= -1.0 && score <= 1.0,
            "Cosine similarity should be in [-1, 1]");
    }
    io:println("Similarity scores: ", resp);
}

// Similarity - with parameters (truncation)
@test:Config {groups: ["similarity"]}
function testSimilarityWithParameters() returns error? {
    SimilarityRequest req = {
        inputs: {
            sourceSentence: "API integration with Ballerina",
            sentences: ["REST API", "gRPC service"]
        },
        parameters: {
            truncate: true,
            truncationDirection: "Right"
        }
    };
    SimilarityResponse resp = check teiClient->/similarity.post(req);
    test:assertTrue(resp.length() > 0, "Should return scores with parameters");
}

// Tokenize - POST /tokenize (single string)
@test:Config {groups: ["tokenize"]}
function testTokenizeSingleString() returns error? {
    TokenizeRequest req = {
        inputs: "hello world",
        addSpecialTokens: true
    };
    TokenizeResponse resp = check teiClient->/tokenize.post(req);
    // TokenizeResponse = SimpleToken[][]
    test:assertTrue(resp.length() > 0, "Should return tokenized batches");
    test:assertTrue(resp[0].length() > 0, "First batch should have tokens");

    foreach SimpleToken tok in resp[0] {
        test:assertTrue(tok.id >= 0, "Token id should be non-negative");
        test:assertNotEquals(tok.text, "", "Token text should not be empty");
    }
    io:println("Token count: ", resp[0].length());
}

// Tokenize - batch input
@test:Config {groups: ["tokenize"]}
function testTokenizeBatch() returns error? {
    TokenizeRequest req = {
        inputs: ["hello world", "Ballerina connector"],
        addSpecialTokens: true
    };
    TokenizeResponse resp = check teiClient->/tokenize.post(req);
    test:assertTrue(resp.length() > 0, "Batch tokenize should return results");
}

// Tokenize - without special tokens
@test:Config {groups: ["tokenize"]}
function testTokenizeWithoutSpecialTokens() returns error? {
    TokenizeRequest req = {
        inputs: "test without special tokens",
        addSpecialTokens: false
    };
    TokenizeResponse resp = check teiClient->/tokenize.post(req);
    test:assertTrue(resp.length() > 0, "Should return tokens without special tokens");
}

// Decode - POST /decode
@test:Config {groups: ["decode"]}
function testDecodeBasic() returns error? {
    DecodeRequest req = {
        ids: [1, 2, 3],    // InputIdsOneOf1 = int:Signed32[]
        skipSpecialTokens: true
    };
    DecodeResponse resp = check teiClient->/decode.post(req);
    // DecodeResponse = string[]
    test:assertTrue(resp.length() > 0, "Should return decoded strings");
    test:assertNotEquals(resp[0], "", "Decoded text should not be empty");
    io:println("Decoded: ", resp[0]);
}

// Decode - keep special tokens
@test:Config {groups: ["decode"]}
function testDecodeKeepSpecialTokens() returns error? {
    DecodeRequest req = {
        ids: [1, 2],
        skipSpecialTokens: false
    };
    DecodeResponse resp = check teiClient->/decode.post(req);
    test:assertTrue(resp.length() > 0, "Should decode with special tokens retained");
}

// OpenAI-compatible embeddings  —  POST /v1/embeddings
@test:Config {groups: ["openai_compat"]}
function testOpenAICompatEmbeddings() returns error? {
    OpenAICompatRequest req = {
        input: "Ballerina OpenAI-compatible embedding",
        encodingFormat: "float"
    };
    OpenAICompatResponse resp = check teiClient->/v1/embeddings.post(req);
    test:assertNotEquals(resp.'object, "", "object field should not be empty");
    test:assertNotEquals(resp.model, "", "model should not be empty");
    test:assertTrue(resp.data.length() > 0, "data should have at least one embedding");
    test:assertTrue(resp.usage.totalTokens > 0, "totalTokens should be positive");
    io:println("OpenAI compat model: ", resp.model, " | total tokens: ", resp.usage.totalTokens);
}

// OpenAI-compatible  —  base64 encoding format
@test:Config {groups: ["openai_compat"]}
function testOpenAICompatBase64() returns error? {
    OpenAICompatRequest req = {
        input: "base64 encoded embedding",
        encodingFormat: "base64"
    };
    OpenAICompatResponse resp = check teiClient->/v1/embeddings.post(req);
    test:assertTrue(resp.data.length() > 0, "Should return data with base64 format");
}

// Prometheus metrics - GET /metrics
@test:Config {groups: ["metrics"]}
function testGetMetrics() returns error? {
    string metrics = check teiClient->/metrics();
    test:assertNotEquals(metrics, "", "Metrics response should not be empty");
    io:println("Metrics snippet: ", metrics.substring(0, int:min(100, metrics.length())));
}

// Type validation - TruncationDirection enum values
@test:Config {groups: ["types"]}
function testTruncationDirectionTypes() {
    TruncationDirection left = "Left";
    TruncationDirection right = "Right";
    test:assertEquals(left, "Left");
    test:assertEquals(right, "Right");
}

// Type validation - EncodingFormat enum values
@test:Config {groups: ["types"]}
function testEncodingFormatTypes() {
    EncodingFormat floatFmt = "float";
    EncodingFormat base64Fmt = "base64";
    test:assertEquals(floatFmt, "float");
    test:assertEquals(base64Fmt, "base64");
}

// Type validation - SparseValue structure
@test:Config {groups: ["types"]}
function testSparseValueStructure() {
    SparseValue sv = {index: 42, value: 0.87};
    test:assertEquals(sv.index, 42);
    test:assertEquals(sv.value, 0.87);
    test:assertTrue(sv.index >= 0, "Sparse index must be non-negative");
}

// Type validation - Rank structure
@test:Config {groups: ["types"]}
function testRankStructure() {
    Rank rank = {score: 0.92, index: 1, text: "sample document"};
    test:assertEquals(rank.index, 1);
    test:assertTrue(rank.score >= 0.0, "Score should be non-negative");
    test:assertEquals(rank.text, "sample document");
}

// Type validation - Prediction structure
@test:Config {groups: ["types"]}
function testPredictionStructure() {
    Prediction p = {label: "POSITIVE", score: 0.95};
    test:assertNotEquals(p.label, "");
    test:assertTrue(p.score >= 0.0 && p.score <= 1.0);
}

// Type validation - OpenAICompatUsage structure
@test:Config {groups: ["types"]}
function testOpenAICompatUsageStructure() {
    OpenAICompatUsage usage = {promptTokens: 5, totalTokens: 5};
    test:assertEquals(usage.promptTokens, 5);
    test:assertEquals(usage.totalTokens, 5);
    test:assertTrue(usage.totalTokens >= usage.promptTokens,
        "totalTokens should be >= promptTokens");
}
