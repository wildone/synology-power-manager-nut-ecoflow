Param(
  [string]$VERSION = "0.1.0"
)

git checkout master
git pull

# delete old tag
git tag -d v${VERSION}
git push --delete origin v${VERSION}

# create new tag
npm version ${VERSION}
git commit -s -a -m "chore: release v${VERSION}"
git tag -s -a v${VERSION} -m "v${VERSION}"
git push && git push --tags
