#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Получаем последний тег
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo -e "${YELLOW}Latest tag: ${LATEST_TAG}${NC}"

# Парсим версию
VERSION=${LATEST_TAG#v}
IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# Выбираем тип релиза
echo -e "${YELLOW}Select version bump:${NC}"
echo "1) Patch (v$MAJOR.$MINOR.$((PATCH+1))) - bug fixes"
echo "2) Minor (v$MAJOR.$((MINOR+1)).0) - new features"
echo "3) Major (v$((MAJOR+1)).0.0) - breaking changes"
read -p "Choice [1]: " BUMP_TYPE
BUMP_TYPE=${BUMP_TYPE:-1}

case $BUMP_TYPE in
    1) NEW_TAG="v$MAJOR.$MINOR.$((PATCH+1))" ;;
    2) NEW_TAG="v$MAJOR.$((MINOR+1)).0" ;;
    3) NEW_TAG="v$((MAJOR+1)).0.0" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo -e "${GREEN}New version: ${NEW_TAG}${NC}"

# Генерируем все файлы
echo -e "${GREEN}🔨 Generating proto files...${NC}"
./scripts/gen.sh

# Коммитим всё
if [[ -z $(git status -s) ]]; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    echo -e "${GREEN}📝 Committing changes...${NC}"
    git add .
    git commit -m "chore: release ${NEW_TAG}"
fi

# Создаем тег
echo -e "${GREEN}🏷️  Creating tag ${NEW_TAG}...${NC}"
git tag -a "${NEW_TAG}" -m "Release ${NEW_TAG}"

# Пушим
echo -e "${GREEN}📤 Pushing to remote...${NC}"
git push origin main
git push origin "${NEW_TAG}"

echo -e "${GREEN}✨ Released ${NEW_TAG} successfully!${NC}"
echo ""
echo -e "${YELLOW}📦 Usage:${NC}"
echo -e "${YELLOW}Go:   go get github.com/legendaryneobatman/shop-proto-repo@${NEW_TAG}${NC}"
echo -e "${YELLOW}NPM:  npm install @legendaryneobatman/shop-proto-repo@github:legendaryneobatman/shop-proto-repo#${NEW_TAG}${NC}"