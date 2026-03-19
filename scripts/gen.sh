#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Проверяем наличие proto файлов
PROTO_FILES=$(find api -name "*.proto")

if [ -z "$PROTO_FILES" ]; then
    echo -e "${RED}❌ No .proto files found${NC}"
    exit 1
fi

PROTO_COUNT=$(echo "$PROTO_FILES" | wc -l)
echo -e "${GREEN}Found ${PROTO_COUNT} proto files${NC}\n"

# ============================================================
# 1. ГЕНЕРАЦИЯ ДЛЯ GO
# ============================================================

print_header "Generating Go files"

rm -rf gen/go
mkdir -p gen/go

for proto_file in $PROTO_FILES; do
    echo "Processing: $proto_file"

    protoc \
        --proto_path=. \
        --go_out=gen/go \
        --go_opt=paths=source_relative \
        --go-grpc_out=gen/go \
        --go-grpc_opt=paths=source_relative \
        --experimental_allow_proto3_optional \
        "$proto_file"
done

echo -e "${GREEN}✅ Go generation complete${NC}"

# Форматируем Go код
if command -v go &> /dev/null; then
    go fmt ./gen/go/... 2>/dev/null || true
    echo -e "${GREEN}✅ Go code formatted${NC}"
fi

GO_FILES=$(find gen/go -name "*.go" | wc -l)
echo -e "${GREEN}Generated ${GO_FILES} Go files${NC}"

# ============================================================
# 2. ГЕНЕРАЦИЯ ДЛЯ NESTJS
# ============================================================

print_header "Generating NestJS/TypeScript files"

# Проверяем наличие ts-proto
if [ ! -f "node_modules/.bin/protoc-gen-ts_proto" ]; then
    echo -e "${YELLOW}⚠️  ts-proto not found. Installing...${NC}"

    # Проверяем package.json
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}Creating package.json...${NC}"
        bun init -y > /dev/null
    fi

    bun install --save-dev ts-proto > /dev/null
    echo -e "${GREEN}✅ ts-proto installed${NC}"
fi

rm -rf gen/nest
mkdir -p gen/nest

# Генерируем TypeScript файлы
bun protoc \
    --plugin=./node_modules/.bin/protoc-gen-ts_proto \
    --ts_proto_out=./gen/nest \
    --ts_proto_opt=nestJs=true \
    --ts_proto_opt=outputServices=grpc-js \
    --ts_proto_opt=esModuleInterop=true \
    --experimental_allow_proto3_optional \
    --proto_path=. \
    $PROTO_FILES

echo -e "${GREEN}✅ NestJS generation complete${NC}"

TS_FILES=$(find gen/nest -name "*.ts" | wc -l)
echo -e "${GREEN}Generated ${TS_FILES} TypeScript files${NC}"

# ============================================================
# ИТОГ
# ============================================================

print_header "Summary"
echo -e "${GREEN}✅ Proto files:      ${PROTO_COUNT}${NC}"
echo -e "${GREEN}✅ Go files:         ${GO_FILES}${NC}"
echo -e "${GREEN}✅ TypeScript files: ${TS_FILES}${NC}"
echo ""
echo -e "${GREEN}✨ All done!${NC}"