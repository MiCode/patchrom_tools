#!/bin/bash

if [ -z "$PORT_ROOT" ]
then
    echo -e "\033[91m Please setup environmant firstly \033[1;m"    #RED COLOR
    echo
    exit
fi

ALL_PHONES=$(sed -n '2p' $PORT_ROOT/build/makefile  | sed 's/PRODUCTS := //')
ALL_PHONES="$ALL_PHONES $EXTRA_PHONES"  #set environment variable EXTRA_PHONES to other phones that aren't in Makefile

FACTORYS=(HTC HUAWEI SONY MOTO SAMSUNG)
HTC=(sensation x515m vivo saga onex ones)
HUAWEI=(honor p1 d1)
SONY=(lt18i lt26i)
MOTO=(razr me865)
SAMSUNG=(i9100 i9300 gnote)

GIT_UPLOAD_TOOL_PATH=$PORT_ROOT/.repo/repo/subcmds
GIT_UPLOAD_TOOL_NO_VERIFY=$PORT_ROOT/tools/git_upload_no_verify.py
PATCH_SH=$PORT_ROOT/tools/patch_for_phones.sh
PATCH_SWAP_PATH=$PORT_ROOT/android/patch
MERGE_DIVIDE_TOOLS=$PORT_ROOT/tools/merge_divide_jar_out.sh

WHITE='\033[37m'
GRAY='\033[30m'
BLUE='\033[34m'
GREEN='\033[92m'
YELLOW='\033[33m'
RED='\033[91m'
ENDC='\033[1;m'

ERROR="${RED}ERROR$ENDC"

TOOL_NAME=${0##*/}
TARGETS=
COMMIT_ARRAY=
TMP_DIR=
STASH=
STASH_MSG="STASH CHANGE FOR AUTO_PATCHING"
BRANCH="for-upload"
RESULT=
COMMIT_MSG=
UPLOAD=

POS='\033['
ENDP='H'
LNUM=
CNUM=20


get_line_num()
{
    local pos
    echo -ne '\e[6n'; read -sdR pos
    pos=${pos#*[}
    LNUM=${pos%%;*}
    #col=${pos##*;}
}

function check_commits_parameter {
    local phone="$1"
    local pre="$2"
    local post="$3"
    local all_commit

    [ ${#pre} -ne 7 ]  && error_exit "length of \"$pre\" is not 7 chars"
    [ ${#post} -ne 7 ] && error_exit "length of \"$post\" is not 7 chars"

    all_commit=$(git log --oneline | cut -d' ' -f1)
    [ "$pre" = "$post" ] && error_exit "commit NO. is same"

    echo $all_commit | grep -q "$pre"  || error_exit "can't find commit $pre"
    echo $all_commit | grep -q "$post" || error_exit "can't find commit $post"

    for commit in $all_commit
    do
        echo $commit | grep -q $pre && error_exit "$pre is ahead than $post"
        echo $commit | grep -q $post && break
    done
}

function get_commit_array {
    local phone="$1"
    local pre="$2"
    local post="$3"
    local array

    cd "$PORT_ROOT/$phone"
    local all_commit=$(git log --oneline | cut -d' ' -f1)

    array=$(echo $all_commit | sed -e "s/$pre.*$//g" | sed -e "s/^.*$post//g")
    eval array="($post $array)"

    local len=${#array[*]}
    for ((i = 0; i < $len; i++))
    do
        COMMIT_ARRAY[$i]=${array[(($len-$i-1))]}
    done
}

function replace_git_upload_tool {
    cp $GIT_UPLOAD_TOOL_NO_VERIFY $GIT_UPLOAD_TOOL_PATH/upload.py
}

function recovery_git_upload_tool {
    cd $GIT_UPLOAD_TOOL_PATH 
    git checkout . 2>/dev/null 1>/dev/null
    cd - 2>/dev/null 1>/dev/null
}

function backup_untracked_files {
    local l1=$(git status | grep -n "# Untracked files:" | cut -d':' -f1)
    ((l1=l1+3))
    local l2=$(git status | wc -l)
    local files=$(git status | sed -n "${l1},${l2}p" | grep -E "^#\s+" |sed "s/#//g")
    for f in $files
    do
        mkdir -p $TMP_DIR/$(dirname $f)/
        mv $f $TMP_DIR/$(dirname $f)/
    done
}

function stash_changes {
    STASH="[stashed]"
    git stash save "$STASH_MSG" 1>/dev/null 2>/dev/null
}

function backup {
    grep -q "tmp.*" .git/info/exclude || echo "tmp.*" >> .git/info/exclude
    TMP_DIR=$(mktemp -d tmp.XXX)
    git status | grep -q "# Untracked files:" && backup_untracked_files

    STASH=
    git status | grep -q -E "(# Changes to be committed:|# Changes not staged for commit:)" && stash_changes
}

function restore {
    cp -r $TMP_DIR/* . 2>/dev/null 1>/dev/null
    cp -r $TMP_DIR/.[^.]* . 2>/dev/null 1>/dev/null   #cp hide files
    rm -rf $TMP_DIR
}

function print_result {
    get_line_num
    echo -e "$phone ${POS}${LNUM};${CNUM}${ENDP} $result ${YELLOW}${STASH}${ENDC}"
}

function patch_for_one_phone {
    local from="$1"
    local phone="$2"
    local commit="$3"
    local result="success"

    cd "$PORT_ROOT/$phone"

    backup
    if ! git checkout "$BRANCH" 2>/dev/null 1>/dev/null
    then
        result="${RED}failed [no branch $BRANCH]$ENDC"
        print_result "$phone" "$result"
        restore
        return
    fi

    if ! repo sync . 2>/dev/null 1>/dev/null
    then
        result="${RED}failed [sync failed]$ENDC"
        print_result "$phone" "$result"
        restore
        return
    fi

    $MERGE_DIVIDE_TOOLS -m $phone
    apply_log=$(git.apply $PATCH_SWAP_PATH/$from-patch.$commit 2>&1)
    $MERGE_DIVIDE_TOOLS -d $phone

    echo $apply_log | grep -q "error: while searching for:" && result="${RED}failed$ENDC"
    echo $apply_log | grep -q -e "error:.*: No such file or directory" && result="${RED}failed$ENDC"
    echo $apply_log | grep -q "Rejected" && result="${RED}failed$ENDC"
    git status | grep -q "smali.rej" && result="${RED}failed$ENDC"
   
    if [ $result = "success" ]
    then
        git add .  2>/dev/null 1>/dev/null

        IFS_OLD="$IFS"
        IFS=
        echo $MSG | git commit --file=- 2>/dev/null 1>/dev/null
        IFS="$IFS_OLD"

        [ $UPLOAD != "false" ] && repo upload .  2>/dev/null 1>/dev/null
    else
        git clean -df 2>/dev/null 1>/dev/null
        git checkout . 2>/dev/null 1>/dev/null
    fi

    restore
    print_result "$phone" "$result"
}

function patch_for_phones {
    local from="$1"
    local to="$2"
    local commit="$3"

    for phone in $to
    do
        patch_for_one_phone "$from" "$phone" "$commit"
    done
}

function patch_one_commit {
    local from="$1"
    local to="$2"
    local commit="$3"

    cd "$PORT_ROOT/$from"
    mkdir $PATCH_SWAP_PATH -p
    git.patch ${commit}^..${commit} 2>/dev/null | sed "s/framework2.jar.out/framework.jar.out/g" | sed "s/framework-ext.jar.out/framework.jar.out/g" > ${PATCH_SWAP_PATH}/${from}-patch.${commit}
    IFS_OLD="$IFS"
    IFS=
    MGS=
    MSG=$(git log  -1 ${commit} | grep  "^\s" | grep -v "Signed-off-by:" | sed "s/\s\+//" | sed "/Change-Id:/d")
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo -ne ""
    echo -e "${BLUE}[ID]${ENDC}"
    echo "    ${commit}"
    echo -e "${BLUE}[MSG]${ENDC}"
    echo "$MSG" | sed "s/^/    /"
    echo ----------------------------------------------------------
    IFS="$IFS_OLD"
    #echo "patch_for_phones $from $to ${commit}"
    patch_for_phones "$from" "$to" "${commit}"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo -e "\n"
}

function patch_commits {
    local from="$1"
    local to="$2"
    local pre="$3"
    local post="$4"

    check_commits_parameter $from $pre $post
    get_commit_array $from $pre $post

    echo
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo -e " ${BLUE}${#COMMIT_ARRAY[*]}$ENDC COMMITS FROM [${RED}$from$ENDC] NEED TO PATCH:"
    echo -n "  "
    echo -e "${YELLOW}|->${COMMIT_ARRAY[*]}->|$ENDC"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo

    for ((i = 0; i < ${#COMMIT_ARRAY[*]}; i++))
    do
        local commit="${COMMIT_ARRAY[$i]}"
        replace_git_upload_tool

        patch_one_commit "$from" "$to" "$commit"

        recovery_git_upload_tool
    done
}

function execute {
    local cmdstr="$1"
    local cmd
    if echo $cmdstr | grep ";" -q
    then
        for (( i = 1; ; i++ ))
        do
            cmd=$(echo $cmdstr | cut -d';' -f$i)
            [ -z "$cmd" ] && break
            echo -e "${YELLOW}++++OUTPUT OF [${GREEN}${cmd}${YELLOW}] @[${GREEN}$(pwd)${YELLOW}]++++$ENDC "
            eval $cmd
            echo
        done
    else
        echo -e "${YELLOW}++++OUTPUT OF [${GREEN}${cmdstr}${YELLOW}] @[${GREEN}$(pwd)${YELLOW}]++++$ENDC "
        eval $cmdstr
    fi
}

function execute_for_phones {
    local phones="$1"
    local cmdstr="$2"
    for phone in $phones
    do
          echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        echo -e "${BLUE}EXECUTE [$cmdstr] for [$phone]$ENDC"
           echo ----------------------------------------------------------
        cd $PORT_ROOT/$phone
        execute "$cmdstr"
        echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        echo
    done
}

function merge_jar_out_for_phones {
    local phones="$1"

    for phone in $phones
    do
        cd "$PORT_ROOT/$phone"
        echo -e "${BLUE}MERGE jar.out for [$phone]$ENDC\n"
        $MERGE_DIVIDE_TOOLS "-m" "$phone"
    done
}

function divide_jar_out_for_phones {
    local phones="$1"

    for phone in $phones
    do
        cd "$PORT_ROOT/$phone"
        echo -e "${BLUE}DIVIDE jar.out for [$phone]$ENDC\n"
        $MERGE_DIVIDE_TOOLS "-d" "$phone"
    done
}

function check_phones {
    local invalid
    local valid
    local t
    t="$1"
    TARGETS=
    for (( i=0; i<${#FACTORYS[*]}; i++ ))
    do
        if [ "$t" = "${FACTORYS[i]}" ]
        then
            eval t="$""{""$t""[*]}"
            break
        fi
    done
    if [ "$t" = "all" ]
    then
        t="$ALL_PHONES"
    fi

    for p in $t
    do
        if [[ -d $PORT_ROOT/$p && -n "$p" && -n "$ALL_PHONES" && ${ALL_PHONES/$p/} != ${ALL_PHONES} ]]
        then
            valid="$valid $p"
        else
            invalid="$invalid $p"
        fi
    done
    [ -z "$valid" ] && error_exit "no valid targets"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    [ -n "$invalid" ] && echo -e "${RED}INVALID TARGETS${ENDC}:\n\t$invalid"
    TARGETS=$valid
    echo -e "${GREEN}VALID TARGETS${ENDC}:"
    echo -e "\t$TARGETS"
    [ -z "$UPLOAD" ] || echo -e "${GREEN}UPLOAD${ENDC}:\n\t$UPLOAD"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo
}

function error_exit {
    echo -e "$ERROR: $1"
    exit 1
}

function usage {
    echo "*********************************************** USAGE ******************************************************"
    echo "$TOOL_NAME [OPTIN]"
    echo "OPTION"
    echo -e "CASE 1:"
    echo -e "\t --exec --phones {\"[phone1 phone2 ... phoneN] or [all]\"} --cmdstr [\"cmdstring\"]"
    echo -e "CASE 2:"
    echo -e "\t [--without-upload] --patch --from [phone] --to {\"[phone1 phone2 ... phoneN]\" or \"[FACTORY]\" or \"[all]\"} --head [length]"
    echo -e "CASE 3:"
    echo -e "\t [--without-upload] --patch --from [phone] --to {\"[phone1 phone2 ... phoneN]\" or \"[FACTORY]\" or \"[all]\"} --commits [pre_commit] [post_commit]"
    echo -e "CASE 4:"
    echo -e "\t --merge-jar-out --phones {\"[phone1 phone2 ... phoneN]\" or \"[FACTORY]\" or \"[all]\"}"
    echo -e "CASE 5:"
    echo -e "\t --divide-jar-out --phones {\"[phone1 phone2 ... phoneN]\" or \"[FACTORY]\" or \"[all]\"}"
    echo
    exit $1
}


####start###
case "$1" in
    "--exec")
        [[ "$2" = "--phones" &&  "$4" = "--cmdstr" ]] || usage 1
        cd $PORT_ROOT
        ALL_PHONES=$(find . -maxdepth 1 -type d | sed "s/\.\///" | grep -v "\.")
        check_phones "$3"
        cmdstr="$5"
        execute_for_phones "$TARGETS" "$cmdstr"
        ;;
    "--patch" | "--without-upload")
        if [ $1 = "--without-upload" ]
        then
            UPLOAD="false"
            shift
        else
            UPLOAD="true"
        fi

        [[ "$1" = "--patch" && "$2" = "--from" && "$4" = "--to" ]] || usage 1
        from="$3"
        [ ! -d "$PORT_ROOT/$from" ] && error_exit "[$from] is wrong phone's name"  #check from
        check_phones "$5"
        to="$TARGETS"
        cd "$PORT_ROOT/$from"
        case "$6" in
            "--head")
                pre=$(git log --oneline HEAD~$7 -1 | cut -d' ' -f1)
                post=$(git log --oneline HEAD -1 | cut -d' ' -f1)
                ;;
            "--commits")
                pre="$7"
                post="$8"
                ;;
            *)
                usage 1
                ;;
        esac
        [[ -z "$pre" || -z "$post" ]] && usage 1
        patch_commits "$from" "$to" "$pre" "$post"
        ;;
    "--merge-jar-out")
        [[ "$2" = "--phones" ]] || usages 1
        check_phones "$3"
        merge_jar_out_for_phones "$TARGETS"
        ;;
    "--divide-jar-out")
        [[ "$2" = "--phones" ]] || usages 1
        check_phones "$3"
        divide_jar_out_for_phones "$TARGETS"
        ;;
    *)
        usage 1
        ;;
esac

