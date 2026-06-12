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

// # Semantic Search
//
// This example demonstrates how to use the TEI `/embed` endpoint to
// convert text into dense vector embeddings and perform cosine-similarity
// based semantic search over a small document corpus.
//
// ## Prerequisites
// - A running TEI instance with an embedding model (e.g. BAAI/bge-base-en-v1.5)
// - Set `serviceUrl` in Config.toml
//
// ## Run the example
// ```bash
// bal run
// ```

import ballerina/io;
import ballerinax/huggingface.tei;

configurable string serviceUrl = "http://localhost:8080";

// Compute cosine similarity between two vectors
function cosineSimilarity(float[] a, float[] b) returns float {
    float dot = 0.0;
    float normA = 0.0;
    float normB = 0.0;

    foreach int i in 0 ..< a.length() {
        dot += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }

    float denom = float:sqrt(normA) * float:sqrt(normB);
    if denom == 0.0 {
        return 0.0;
    }
    return dot / denom;
}

// A ranked search result
type SearchResult record {|
    string document;
    float score;
|};

public function main() returns error? {
    tei:Client teiClient = check new ({}, serviceUrl);

    io:println("=== HuggingFace TEI Semantic Search ===\n");

    // Small document corpus
    string[] documents = [
        "Ballerina is a cloud-native programming language for integration.",
        "Python is widely used for data science and machine learning.",
        "Kubernetes orchestrates containerised workloads at scale.",
        "REST APIs allow services to communicate over HTTP.",
        "Ballerina has built-in support for HTTP, gRPC, and Kafka."
    ];

    string query = "What programming language is good for API integration?";
    io:println("Query: \"" + query + "\"\n");

    // Embed the query
    tei:EmbedRequest queryReq = {inputs: query, normalize: true};
    tei:EmbedResponse queryEmbedResp = check teiClient->/embed.post(queryReq);
    float[] queryVec = queryEmbedResp[0];

    // Embed all documents and compute similarity
    SearchResult[] results = [];
    foreach string doc in documents {
        tei:EmbedRequest docReq = {inputs: doc, normalize: true};
        tei:EmbedResponse docEmbedResp = check teiClient->/embed.post(docReq);
        float[] docVec = docEmbedResp[0];
        float score = cosineSimilarity(queryVec, docVec);
        results.push({document: doc, score: score});
    }

    // Sort by descending score
    SearchResult[] sorted = from SearchResult r in results
        order by r.score descending
        select r;

    io:println("Results (ranked by similarity):");
    foreach int i in 0 ..< sorted.length() {
        io:println(string `  ${i + 1}. [${sorted[i].score.toString().substring(0, 6)}] ${sorted[i].document}`);
    }
}
