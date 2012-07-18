#!/bin/bash

PHONES=honor:lt18i:p1:i9100:gnote:mx:sensation:onex:ones:razr:i9300:lt26i:vivo:x515m

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

function check_commits_parameter {
    phone="$1"
    pre="$2"
    post="$3"

    cd "$PORT_ROOT/$phone" 2>/dev/null 1>/dev/null 
    if [ $? -ne 0 ]; then
        echo -e "***\n$ERROR:[$phone] is wrong phone's name\n***" 
        return 1
    fi

    all_commit=`git log --oneline | cut -d' ' -f1`
    all_commit=`echo $all_commit | sed -e "s/\s\+/:/g"`
    if [ "$pre" = "$post" ]; then
        echo -e "$ERROR: commit NO. is same"
        return 1
    fi

    echo $all_commit | grep -q "$pre"
    if [ $? -ne 0 ]; then
        echo -e "$ERROR: can't find commit $pre"
        return 1
    fi
    echo $all_commit | grep -q "$post" 
    if [ $? -ne 0 ]; then 
        echo -e "$ERROR: can't find commit $post"
        return 1
    fi

    OLD_IFS="$IFS"
    IFS=$':'
    for commit in $all_commit;do
        echo $commit | grep -q $pre && echo -e "$ERROR: $pre is ahead than $post" && IFS="$OLD_IFS" && return 1 
        echo $commit | grep -q $post && break
    done
    IFS="$OLD_IFS"
    return 0
}

function get_commit_list {
    phone="$1"
    pre="$2"
    post="$3"

    cd "$PORT_ROOT/$phone"
    all_commit=`git log --oneline | cut -d' ' -f1`
    all_commit=`echo $all_commit | sed -e "s/\s\+/:/g"`

    commit_list=`echo $all_commit | sed -e "s/$pre.*$//g" | sed -e "s/^.*$post//g"`
    commit_list="$post$commit_list$pre:"
    commit_list=`echo $commit_list | tac -s ":"`
    echo "$commit_list"
}

function replace_git_upload_tool {
    cp $GIT_UPLOAD_TOOL_NO_VERIFY $GIT_UPLOAD_TOOL_PATH/upload.py
}

function recovery_git_upload_tool {
    cd $GIT_UPLOAD_TOOL_PATH 
    git checkout . 2>/dev/null 1>/dev/null
    cd - 2>/dev/null 1>/dev/null
}
    
function patch_for_one_phone {
    from="$1"
    phone="$2"
    commit="$3"
    msg="$4"

    echo -n "$phone"

    cd "$PORT_ROOT/$phone" 2>/dev/null 1>/dev/null 
    if [ $? -ne 0 ]; then
        echo -e "${RED}\t\t NO SUCH PHONE$ENDC" 
        return 1
    fi

    result="success"
    git clean -df  2>/dev/null 1>/dev/null
    git checkout . 2>/dev/null 1>/dev/null
    git checkout for-upload 2>/dev/null 1>/dev/null
    repo sync . 2>/dev/null 1>/dev/null

    $MERGE_DIVIDE_TOOLS -m $phone
    apply_log=`git.apply $PATCH_SWAP_PATH/$from-patch.$commit 2>&1`
    $MERGE_DIVIDE_TOOLS -d $phone

    echo $apply_log | grep -q "error: while searching for:" && result="${RED}failed$ENDC"
    echo $apply_log | grep -q -e "error:.*: No such file or directory" && result="${RED}failed$ENDC"
    echo $apply_log | grep -q "Rejected" && result="${RED}failed$ENDC"
    git status | grep -q "smali.rej" && result="${RED}failed$ENDC"
   
    if [ $result = "success" ];then
        git add .  2>/dev/null 1>/dev/null
        git commit -m "$msg" 2>/dev/null 1>/dev/null
        repo upload .  2>/dev/null 1>/dev/null
    else
        git clean -df 2>/dev/null 1>/dev/null
        git checkout . 2>/dev/null 1>/dev/null
    fi

    if [ $phone = "sensation" ];then
        echo -e "\t $result"
    else
        echo -e "\t\t $result"
    fi
}

function patch_for_phones {
    from="$1"
    to="$2"
    commit="$3"
    msg="$4"

    OLD_IFS="$IFS"
    IFS=$':'
    for phone in $to
    do
        patch_for_one_phone "$from" "$phone" "$commit" "$msg"
    done
    IFS="$OLD_IFS"
}

function patch_one_commit {
    from="$1"
    to="$2"
    tail="$3"
    head="$4"

    cd "$PORT_ROOT/$from"
    mkdir $PATCH_SWAP_PATH -p
    git.patch $tail..$head > $PATCH_SWAP_PATH/$from-patch.$head
    msg=`git log $head --oneline -1 -1 | sed "s/$head //g"`
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo -e "${BLUE}[ID] $head [MSG] $msg$ENDC"
    patch_for_phones "$from" "$to" "$head" "$msg"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo -e "\n"
}

function patch_commits {
    from="$1"
    to="$2"
    pre="$3"
    post="$4"

    check_commits_parameter $from $pre $post || exit 1

    commit_list=`get_commit_list $from $pre $post`
    echo
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo -e "THESE COMMITS FROM [${RED}$from$ENDC] NEED TO PATCH:"
    echo -n "  "
    echo -e "${YELLOW}|->"`echo $commit_list | sed "s/:/ /g" | sed "s/$pre//g"`"->|$ENDC"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo 
    
    while [ "$post" != "`echo $commit_list | cut -d':' -f1`" ]
    do
        head=`echo $commit_list | cut -d':' -f2`
        tail=`echo $commit_list | cut -d':' -f1`
        commit_list="`echo $commit_list | sed \"s/$tail://g\"`"
        replace_git_upload_tool

        patch_one_commit $from $to $tail $head

        recovery_git_upload_tool
    done
}

function execute {
    OLD_IFS="$IFS"
    IFS=$' \t\n'
    cmdstr=$1
    echo $cmdstr | grep ";" -q
    if [ $? -eq 0 ];then
        for (( i = 1; ; i++ ))
        {
            cmd=`echo $cmdstr | cut -d';' -f$i`
            [ -z "$cmd" ] && break
            echo -e "$YELLOW++++RESULT OF [$cmd]++++$ENDC"
            $cmd
            echo
        }
    else
        echo -e "$YELLOW++++RESULT OF [$cmdstr]++++$ENDC"
        $cmdstr
    fi
    IFS=$OLD_IFS
}

function execute_for_phones {
    phones="$1"
    if [ "$phones" = "all" ];then
        phones=$PHONES
    fi
    cmdstr="$2"
    
    OLD_IFS="$IFS"
    IFS=$':'
    for phone in $phones
    do
        echo -e "\n*****************************************************"
        cd $PORT_ROOT/$phone 2>/dev/null 1>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "***\n$ERROR:[$phone] is wrong phone's name\n***" 
            continue
        fi
        echo -e "${BLUE}EXECUTE [$cmdstr] for [$phone]$ENDC"
        execute $cmdstr
    done
    IFS="$OLD_IFS"
}

function merge_jar_out_for_phones {
    phones="$1"
    
    if [ "$phones" = "all" ];then
        phones=$PHONES
    fi

    OLD_IFS="$IFS"
    IFS=$':'
    for phone in $phones
    do
        cd "$PORT_ROOT/$phone" 2>/dev/null 1>/dev/null 
        if [ $? -ne 0 ]; then
            echo -e "***\n$ERROR:[$phone] is wrong phone's name\n***" 
            continue
        fi
        echo -e "${BLUE}MERGE jar.out for [$phone]$ENDC\n"
        $MERGE_DIVIDE_TOOLS "-m" "$phone"
    done
    IFS="$OLD_IFS"
}

function divide_jar_out_for_phones {
    phones="$1"
    
    if [ "$phones" = "all" ];then
        phones=$PHONES
    fi

    OLD_IFS="$IFS"
    IFS=$':'
    for phone in $phones
    do
        cd "$PORT_ROOT/$phone" 2>/dev/null 1>/dev/null 
        if [ $? -ne 0 ]; then
            echo -e "***\n$ERROR:[$phone] is wrong phone's name\n***" 
            continue
        fi
        echo -e "${BLUE}DIVIDE jar.out for [$phone]$ENDC\n"
        $MERGE_DIVIDE_TOOLS "-d" "$phone"
    done
    IFS="$OLD_IFS"
}

function usage {
    echo "**************************** USAGE ****************************"
    echo -e "CASE 1:"
    echo -e "\t --exec --phones {[phone1:phone2:...:phoneN] or [all]} --cmdstr [\"cmdstring\"]"
    echo -e "CASE 2:"
    echo -e "\t --patch --from [phone] --to {[phone1:phone2:...:phoneN] or [all]} --head [length]"
    echo -e "CASE 3:"
    echo -e "\t --patch --from [phone] --to {[phone1:phone2:...:phoneN] or [all]} --commits [pre_commit] [post_commit]"
    echo -e "CASE 4:"
    echo -e "\t --merge-jar-out --phones {[phone1:phone2:...:phoneN] or [all]}"
    echo -e "CASE 5:"
    echo -e "\t --divide-jar-out --phones {[phone1:phone2:...:phoneN] or [all]}"  

    exit 1
}

if [ -z "$PORT_ROOT" ];then
    echo -e "$ERROR: didn't config env"
    exit 1 
fi

if [ "$1" = "--exec" ];then 
    if [ "$2" = "--phones" ];then
        phones="$3"
    else 
        usage
    fi
    if [ "$4" = "--cmdstr" ];then
        cmdstr="$5"
    else
        usage
    fi

    execute_for_phones "$phones" "$cmdstr"
elif [ "$1" = "--patch" ];then
    if [ "$2" = "--from" ];then
        from="$3"
    else 
        usage
    fi

    if [ "$4" = "--to" ];then
        to="$5"
        if [ "$to" = "all" ];then
            to="$PHONES"
        fi
    else
        usage
    fi

    cd "$PORT_ROOT/$from" 2>/dev/null 1>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "***\n$ERROR:[$from] is wrong phone's name\n***" 
        exit 1
    fi    

    if [ "$6" = "--head" ];then
        length="$7"
        pre=`git log --oneline HEAD~$length -1 | cut -d' ' -f1`
        post=`git log --oneline HEAD -1 | cut -d' ' -f1`
    elif [ "$6" = "--commits" ];then
        pre="$7"
        post="$8"
    else
        usage
    fi

    if [ -z "$pre" -o -z "$post" ];then
        usage
    fi

    patch_commits "$from" "$to" "$pre" "$post"
elif [ "$1" = "--merge-jar-out" ];then
    if [ "$2" = "--phones" ];then
        phones="$3"
    else
        usage
    fi
    merge_jar_out_for_phones "$phones"
elif [ "$1" = "--divide-jar-out" ];then
    if [ "$2" = "--phones" ];then
        phones="$3"
    else
        usage
    fi
    divide_jar_out_for_phones "$phones"
else
    usage
fi

