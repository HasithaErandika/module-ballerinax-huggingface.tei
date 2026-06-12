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

// # Document Reranker
//
// This example demonstrates using the TEI `/rerank` endpoint to re-score
// a list of candidate documents against a query. Reranking is the second
// stage in a typical RAG pipeline — after initial retrieval by embeddings,
// a cross-encoder reranker produces a more accurate relevance score.
//
// ## Prerequisites
// - A running TEI instance with a reranking model
//   (e.g. BAAI/bge-reranker-base or cross-encoder/ms-marco-MiniLM-L-6-v2)
// - Set `serviceUrl` in Config.toml
//
// ## Run the example
// ```bash
// bal run
// ```

import ballerina/io;
import ballerinax/huggingface.tei;

configurable string serviceUrl = "http://localhost:8080";

public function main() returns error? {
    tei:Client teiClient = check new ({}, serviceUrl);

    io:println("=== HuggingFace TEI Document Reranker ===\n");

    string query = "How does Ballerina handle HTTP integrations?";

    // Candidate passages retrieved from a first-stage retriever
    string[] candidates = [
        "Ballerina provides first-class HTTP client and listener support, " +
            "making REST API integration straightforward.",
        "Python Flask is a micro web framework for building APIs.",
        "Ballerina's network-aware type system handles JSON, XML, and " +
            "protocol buffers natively.",
        "Kubernetes provides service discovery and load balancing.",
        "In Ballerina, an HTTP client is created with `check new http:Client(url)`."
    ];

    io:println("Query     : \"" + query + "\"");
    io:println("Candidates: " + candidates.length().toString() + " documents\n");

    // Rerank all candidates in a single API call
    tei:RerankRequest rerankReq = {
        query: query,
        texts: candidates,
        returnText: true   // include the original text in the response
    };

    tei:RerankResponse[] ranked = check teiClient->/rerank.post(rerankReq);

    io:println("Reranked results:");
    foreach tei:RerankResponse item in ranked {
        string textPreview = item.text is string
            ? (<string>item.text).substring(0, int:min(60, (<string>item.text).length())) + "..."
            : "(text not returned)";
        io:println(string `  [${item.score.toString().substring(0, 7)}] index=${item.index}  "${textPreview}"`);
    }

    io:println("\nTop result: \"" + (ranked[0].text ?: candidates[ranked[0].index]) + "\"");
}
