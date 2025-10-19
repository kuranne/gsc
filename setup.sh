#!/usr/bin/env zsh

nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)" #define path of command directory

if ! command -v gsc &> /dev/null; then
    echo -e "\nexport PATH=${nowDir}:\${PATH}" >> $HOME/.zshrc || { echo "Failed to add PATH to .zshrc"; exit 1; }
    echo "Added ${nowDir} to PATH in .zshrc"
else
    echo "Command already Worked"
fi

exit 0