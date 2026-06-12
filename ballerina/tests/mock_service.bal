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
        check caller->respond();
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
