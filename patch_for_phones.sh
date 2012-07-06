#!/bin/bash

#{JAR_DIVIDE}:i9100:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:sensation:framework.jar.out|widget.jar.out
#{JAR_DIVIDE}:razr:framework.jar.out|framework-ext.jar.out

PHONES=honor:lt18i:p1:i9100:gnote:mx:sensation:onex:ones:razr:i9300:lt26i

ANDROID_PATH=$PORT_ROOT/android
GIT_UPLOAD_TOOL_PATH=$PORT_ROOT/.repo/repo/subcmds
GIT_UPLOAD_TOOL_NO_VERIFY=$PORT_ROOT/tools/git_upload_no_verify.py
PATCH_SH=$PORT_ROOT/tools/patch_for_phones.sh
PATCH_SWAP_PATH=$PORT_ROOT/android/patch
MERGE_DIVIDE_TOOLS=$PORT_ROOT/tools/merge_divide_jar_out.sh

function check_parameter {
    cd $ANDROID_PATH
    all_commit=`git log --oneline | cut -d' ' -f1`
    all_commit=`echo $all_commit | sed -e "s/\s\+/:/g"`
    if [ "$1" = "$2" ]; then
        echo "ERROR: commit NO. is same"
        return 1
    fi
    echo $all_commit | grep -q "$1"
    if [ $? -ne 0 ]; then
        echo "ERROR: can't find commit $1"
        return 1
    fi
    echo $all_commit | grep -q "$2" 
    if [ $? -ne 0 ]; then 
        echo "ERROR: can't find commit $2"
        return 1
    fi
    OLD_IFS="$IFS"
    IFS=$':'
    for commit in $all_commit;do
        echo $commit | grep -q $1 && echo "ERROR: $1 is ahead than $2" && IFS="$OLD_IFS" && return 1 
        echo $commit | grep -q $2 && break
    done
    IFS="$OLD_IFS"
    return 0
}

function get_commit_list {
    cd "$ANDROID_PATH"
    all_commit=`git log --oneline | cut -d' ' -f1`
    all_commit=`echo $all_commit | sed -e "s/\s\+/:/g"`

    commit_list=`echo $all_commit | sed -e "s/$1.*$//g" | sed -e "s/^.*$2//g"`
    commit_list="$2$commit_list$1:"
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
    commit="$1"
    msg="$2"
    phone="$3"

    echo -n "$phone"
    cd "$PORT_ROOT/$phone"
    result="success"
    git clean -df  2>/dev/null 1>/dev/null
    git checkout . 2>/dev/null 1>/dev/null
    git checkout for-upload 2>/dev/null 1>/dev/null
    repo sync . 2>/dev/null 1>/dev/null

    $MERGE_DIVIDE_TOOLS -m $phone
    apply_log=`git.apply $ANDROID_PATH/patch/patch.$commit 2>&1`
    $MERGE_DIVIDE_TOOLS -d $phone

    echo $apply_log | grep -q "error: while searching for:" && result="failed"
    echo $apply_log | grep -q -e "error:.*: No such file or directory" && result="failed"
    echo $apply_log | grep -q "Rejected" && result="failed"
    git status | grep -q "smali.rej" && result="failed"
   
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
    commit="$1"
    msg="$2"
    OLD_IFS="$IFS"
    IFS=$':'
    for phone in $PHONES
    do
        patch_for_one_phone "$commit" "$msg" "$phone"
    done
    IFS="$OLD_IFS"
    
}

function patch_one_commit {
    cd "$ANDROID_PATH"
    t="$1"
    h="$2"
    mkdir $ANDROID_PATH/patch -p
    git.patch $t..$h > $PATCH_SWAP_PATH/patch.$2
    msg=`git log $h --oneline -1 -1 | sed "s/$h //g"`
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo "[ID] $h [MSG] $msg"
    patch_for_phones "$h" "$msg"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo -e "\n"
}

function patch_commits {
    pre=$1
    post=$2

    check_parameter $pre $post || exit 1
    commit_list=`get_commit_list $pre $post`
    echo
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo "THESE COMMITS NEED TO PATCH:"
    echo -n "  "
    echo "|->"`echo $commit_list | sed "s/:/ /g" | sed "s/$pre//g"`"->|"
    echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo 
    
    while [ "$post" != "`echo $commit_list | cut -d':' -f1`" ]
    do
        h=`echo $commit_list | cut -d':' -f2`
        t=`echo $commit_list | cut -d':' -f1`
        commit_list="`echo $commit_list | sed \"s/$t://g\"`"
        replace_git_upload_tool

        patch_one_commit $t $h

        recovery_git_upload_tool
    done
}

if [ "/android" =  "$ANDROID_PATH" ]; then
    echo "ERROR: didn't config env"
    exit 1 
fi

if [ "$1" = "-m" ];then
    merge_divide_jar_out "-m" $2
elif [ "$1" = "-d" ];then
    merge_divide_jar_out "-d" $2
elif [ "$1" = "-h" ];then
    length=$2
    pre=`git log --oneline HEAD~$length -1 | cut -d' ' -f1`
    post=`git log --oneline HEAD -1 | cut -d' ' -f1`
    patch_commits $pre $post
elif [ "$1" = "-c" ];then
    pre=$2
    post=$3
    patch_commits $pre $post
else
    echo "usage:"
    echo -e "\t -m phone"
    echo -e "\t\t merge phone's jar out"
    echo -e "\t -d phone"
    echo -e "\t\t divide phone's jar out"
    echo -e "\t -c commit_pre commit_post"
    echo -e "\t\t patch from commit_pre(without change of commit_pre) to commit_post to phones"
    echo -e "\t -h length"
    echo -e "\t\t patch first length commits to phones"
fi
