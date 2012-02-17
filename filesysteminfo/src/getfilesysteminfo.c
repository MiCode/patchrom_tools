#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#include <string.h>
#include <errno.h>
#include<fcntl.h>

#define PATH_LEN (256u)
const unsigned int ACCESS_MASK = 0000777;
//FILE *fp = NULL;

void del_last_slash(char * const fullpath){
    char *p = fullpath;
    int pos = 0;

    if(NULL == p)
        return;

    while(p[pos]){
        pos++;
    }

    if(pos > 2){
        pos--;
        if('/' == p[pos]){
            p[pos] = '\0';
        }
    }
}

void del_pre_slash(char * const fullpath){
    char *p1 = fullpath;
    char *p2 = fullpath;
    if('/' == *p2){
        while('\0' != *p2){
            *p1++= *++p2;
        }
        *p1 = '\0';
    }
}

void do_search_dir(char *path){
    DIR *dir;
    char fullpath[PATH_LEN], currfile[PATH_LEN];
    char stmp[PATH_LEN];
    struct dirent *s_dir;
    struct stat file_stat;
    //int ret = 0;

    strcpy(fullpath, path);
    dir=opendir(fullpath);

    while((s_dir = readdir(dir)) != NULL){
        if((strcmp(s_dir-> d_name, ".")==0)||(strcmp(s_dir-> d_name, "..")==0)){
            continue;
        }

        del_last_slash(fullpath);
        sprintf(currfile, "%s/%s", fullpath, s_dir-> d_name);
        stat(currfile, &file_stat);

        sprintf(stmp, "%s %d %d %o\n", currfile, file_stat.st_gid, file_stat.st_uid, ACCESS_MASK & file_stat.st_mode);
        del_pre_slash(stmp);
        printf("%s", stmp);
        //fprintf(fp, "%s", stmp);

        if(S_ISDIR(file_stat.st_mode)){

            do_search_dir(currfile);
        }
    }
    closedir(dir);
}

void get_mode_info(char * const fullpath){
    struct stat file_stat;
    //int ret = 0;
    char stmp[PATH_LEN];
    del_last_slash(fullpath);
    stat(fullpath, &file_stat);

    sprintf(stmp, "%s %d %d %o\n", fullpath, file_stat.st_uid, file_stat.st_gid, ACCESS_MASK & file_stat.st_mode);
    del_pre_slash(stmp);
    printf("%s", stmp);
    //fprintf(fp, "%s", stmp);
    if(S_ISDIR(file_stat.st_mode)){
        do_search_dir(fullpath);
    }
}

int main(int argc,char **argv){
    /*
    fp = fopen(argv[2], "w");
    if(NULL == fp){
        //printf("Open %s failed", argv[2]);
        return 0;
    }
    */
    get_mode_info(argv[1]);
    //fclose(fp);
    return 0;
}
