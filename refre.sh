#!/bin/bash

helpMessage() {
    echo "Refre.sh - Bash script to update all git repositories in a directory"
    echo
    echo "   Usage:"
    echo "      sh ./refre.sh ./... <ARGS>"
    echo "      sh ./refre.sh <ARGS> ./..."
    echo "      sh ./refre.sh <ARGS> ./... <ARGS>"
    echo
    echo "   Options:"
    echo "      -r, --recurse  Perform the same action on all subdirectories"
    echo "      -h, --help     Show this message"
    echo
}



# argument parsing

recursive=false

for arg in "$@"; do
    if [[ $arg = --* ]]; then
        case $arg in
            # command line switches
            "--help")
                helpMessage
                exit 0
                ;;
            "--recurse")
                recursive=true
                ;;
            *)
                echo Unknown argument \""$arg"\"
                helpMessage
                exit 1
        esac
    elif [[ $arg = -* ]]; then
        for (( char=1; char<${#arg}; char++ )); do
            case ${arg:$char:1} in
                # command line switches
                "h")
                    helpMessage
                    exit 0
                    ;;
                "r")
                    recursive=true
                    ;;
                *)
                    printf "\033[31;1m==>\033[37;1m Error: Unknown argument \033[33;1m-%s\033[37;1m.\033[00m\n" "${arg:$char:1}"
                    echo
                    helpMessage
                    exit 1
            esac
        done
    else
        if [ -z "$filePathDeclared" ]; then
            workingDir=$arg
            filePathDeclared=true
        else
            helpMessage
            exit 1
        fi
    fi
done


# correct working dir format and make sure it exists

if [ -z "$workingDir" ]; then
    printf "\033[33;1m==>\033[37;1m Warning: No directory specified, assuming current working directory.\033[00m\n"
    echo
    workingDir="./"
fi

if [[ $workingDir != */ ]]; then
    workingDir+="/"
fi



# check if target path exists and is a directory

if [ ! -e ${workingDir:0:-1} ]; then
    printf "\033[31;1m==>\033[37;1m Error: \033[32;1m%s\033[37;1m does not exist.\033[00m\n" ${workingDir:0:-1}
    echo
    exit -1
elif [ ! -d ${workingDir:0:-1} ]; then
    printf "\033[31;1m==>\033[37;1m Error: \033[32;1m%s\033[37;1m is not a directory.\033[00m\n" ${workingDir:0:-1}
    echo
    exit -2
fi


# find directories that contain git repos

declare -a repos

addDirs() {
    # return if subdir doesn't exist
    # fix for the recursive option going into an infinite loop when it encounters an empty directory
    if [ ! -e "$1" ]; then
        return
    fi

    for dir in "${1}"*/; do
        if git -C "$dir" rev-parse 2> /dev/null; then
            repos+=("$dir")
        else
            if [ $recursive = "true" ]; then
                addDirs "$dir"
            fi
        fi
    done
};

addDirs "$workingDir"


if [ -z "${repos[1]}" ] ; then
    printf "\033[31;1m==>\033[37;1m There is nothing to do as there were no git repos found in \033[32;1m%s\033[37;1m.\033[00m\n" $workingDir
    echo
    exit 1
fi


for repo in "${repos[@]}"; do
    printf "\033[34;1m==>\033[37;1m Updating \033[32;1m%s \033[37;1mfrom \033[36;1m%s\033[37;1m...\033[00m\n" \
        "$repo" \
        "$(cd "$repo" || return; git config --get remote.origin.url)"
    (cd "$repo" || exit
        git pull
    )
    echo
done

printf "\033[32;1m==>\033[37;1m Done.\033[00m\n"
echo
