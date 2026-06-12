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

// # Text Classifier
//
// This example demonstrates using the TEI `/predict` endpoint for zero-shot
// text classification. A sentiment analysis model is used to classify
// customer feedback into Positive / Neutral / Negative categories and
// produce a summary report.
//
// ## Prerequisites
// - A running TEI instance with a classification model
//   (e.g. SamLowe/roberta-base-go_emotions or ProsusAI/finbert)
// - Set `serviceUrl` in Config.toml
//
// ## Run the example
// ```bash
// bal run
// ```

import ballerina/io;
import ballerinax/huggingface.tei;

configurable string serviceUrl = "http://localhost:8080";

// Classification result with the top predicted label
type ClassificationResult record {|
    string text;
    string label;
    float score;
|};

// Classify a single piece of text and return the top label
function classifyText(tei:Client teiClient, string text) returns ClassificationResult|error {
    tei:PredictRequest req = {inputs: text};
    tei:PredictResponse[] predictions = check teiClient->/predict.post(req);

    // predictions is an array of {label, score} — find the highest score
    tei:PredictResponse top = predictions[0];
    foreach tei:PredictResponse p in predictions {
        if p.score > top.score {
            top = p;
        }
    }

    return {text: text, label: top.label, score: top.score};
}

public function main() returns error? {
    tei:Client teiClient = check new ({}, serviceUrl);

    io:println("=== HuggingFace TEI Text Classifier ===\n");

    // Sample customer feedback to classify
    string[] feedbackItems = [
        "The Ballerina connector was incredibly easy to set up. Saved hours!",
        "Documentation could be improved with more examples.",
        "The connector keeps throwing 422 errors and nothing in the docs explains why.",
        "Decent tool. Works as expected for basic use cases.",
        "Absolutely love the built-in streaming support. Works flawlessly."
    ];

    // Classify all items
    ClassificationResult[] results = [];
    foreach string feedback in feedbackItems {
        ClassificationResult result = check classifyText(teiClient, feedback);
        results.push(result);
    }

    // Display results
    io:println("Classification results:");
    io:println(string `${"Text",-55} ${"Label",-10} Score`);
    io:println("─".repeat(80));
    foreach ClassificationResult r in results {
        string preview = r.text.length() > 52 ? r.text.substring(0, 52) + "..." : r.text;
        io:println(string `${preview,-55} ${r.label,-10} ${r.score.toString().substring(0, 6)}`);
    }

    // Summary statistics
    io:println("\nSummary:");
    map<int> counts = {};
    foreach ClassificationResult r in results {
        counts[r.label] = (counts[r.label] ?: 0) + 1;
    }
    foreach [string, int] [label, count] in counts.entries() {
        float pct = <float>count / <float>results.length() * 100.0;
        io:println(string `  ${label}: ${count} (${pct.toString().substring(0, 4)}%)`);
    }
}
