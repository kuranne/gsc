gitTagCreate() {
    gitValidateRepo || errorExit
    git tag "$tagName" || { echo "$ERROR Failed to create tag $tagName"; errorExit; }
    echo "$SUCCESS Created tag: $tagName"
    }

gitTagList() {
    gitValidateRepo || errorExit
    git tag
}

gitTagDelete() {
    gitValidateRepo || errorExit
    git tag -d "$tagDeleteName" || { echo "$ERROR Failed to delete tag $tagDeleteName"; errorExit; }
    echo "$SUCCESS Deleted tag: $tagDeleteName"
}