#!/bin/bash

# Define paths
MOCKOLO_EXECUTABLE=$(which mockolo)
SOURCE_DIR="Sources/Connector"
OUTPUT_DIR="Tests/ConnectorTests/Mocks"
OUTPUT_FILE="$OUTPUT_DIR/GeneratedMocks.swift"

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Run Mockolo to generate mocks
if [ -f "$MOCKOLO_EXECUTABLE" ]; then
    "$MOCKOLO_EXECUTABLE" -s "$SOURCE_DIR" -d "$OUTPUT_FILE" -i Connector --enable-args-history --allow-set-call-count
    echo "Mocks generated at $OUTPUT_FILE"
else
    echo "Error: Mockolo executable not found at $MOCKOLO_EXECUTABLE"
    exit 1
fi
