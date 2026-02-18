#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Generating protobuf files...${NC}"

rm -rf gen/go
mkdir -p gen/go

PROTO_FILES=$(find api -name "*.proto")

if [ -z "$PROTO_FILES" ]; then
    echo -e "${RED}No .proto files found${NC}"
    exit 1
fi

for proto_file in $PROTO_FILES; do
    echo "Processing: $proto_file"

    protoc \
        --proto_path=. \
        --go_out=gen/go \
        --go_opt=paths=source_relative \
        --go-grpc_out=gen/go \
        --go-grpc_opt=paths=source_relative \
        "$proto_file"
done

echo -e "${GREEN}Generation complete!${NC}"

go fmt ./gen/go/...

echo -e "${GREEN}Done!${NC}"