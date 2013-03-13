#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* taken from original <private/android_filesystem_config.h> */

#define AID_ROOT             0  /* traditional unix root user */
#define AID_SYSTEM        1000  /* system server */
#define AID_SHELL         2000  /* adb and debug shell user */

struct fs_path_config {
    unsigned mode;
    unsigned uid;
    unsigned gid;
    const char *prefix;
};

/* Rules for directories. (simplified)
*/
static struct fs_path_config android_dirs[] = {
    { 00750, AID_ROOT,   AID_SHELL,  "sbin" },
    { 00755, AID_ROOT,   AID_SHELL,  "system/bin" },
    { 00755, AID_ROOT,   AID_SHELL,  "system/vendor" },
    { 00755, AID_ROOT,   AID_ROOT,   0 },
};

/* Rules for files. (simplified)
*/
static struct fs_path_config android_files[] = {
    { 00755, AID_ROOT,      AID_SHELL,     "system/bin/*" },
    { 00755, AID_ROOT,      AID_SHELL,     "system/xbin/*" },
    { 00755, AID_ROOT,      AID_SHELL,     "system/vendor/bin/*" },
    { 00750, AID_ROOT,      AID_SHELL,     "sbin/*" },
    { 00755, AID_ROOT,      AID_ROOT,      "bin/*" },
    { 00644, AID_ROOT,      AID_ROOT,       0 },
};

static inline void fs_config(const char *path, int dir,
                             unsigned *uid, unsigned *gid, unsigned *mode)
{
    struct fs_path_config *pc;
    int plen;

    if (path[0] == '/') {
        path++;
    }

    pc = dir ? android_dirs : android_files;
    plen = strlen(path);
    for(; pc->prefix; pc++){
        int len = strlen(pc->prefix);
        if (dir) {
            if(plen < len) continue;
            if(!strncmp(pc->prefix, path, len)) break;
            continue;
        }
        /* If name ends in * then allow partial matches. */
        if (pc->prefix[len -1] == '*') {
            if(!strncmp(pc->prefix, path, len - 1)) break;
        } else if (plen == len){
            if(!strncmp(pc->prefix, path, len)) break;
        }
    }
    *uid = pc->uid;
    *gid = pc->gid;
    *mode = (*mode & (~07777)) | pc->mode;
}

#define DO_DEBUG 1

#define ERROR(fmt,args...) \
	do { \
		fprintf(stderr, "%s:%d: ERROR: " fmt,  \
		        __FILE__, __LINE__, ##args);    \
	} while (0)

#if DO_DEBUG
#define DEBUG(fmt,args...) \
	do { fprintf(stderr, "DEBUG: " fmt, ##args); } while(0)
#else
#define DEBUG(x...)               do {} while(0)
#endif

void
print_help(void)
{
	fprintf(stderr, "fs_get_stats: retrieve the target file stats "
	        "for the specified file\n");
	fprintf(stderr, "usage: fs_get_stats cur_perms is_dir filename\n");
	fprintf(stderr, "\tcur_perms - The current permissions of "
	        "the file\n");
	fprintf(stderr, "\tis_dir    - Is filename is a dir, 1. Otherwise, 0.\n");
	fprintf(stderr, "\tfilename  - The filename to lookup\n");
	fprintf(stderr, "\n");
}

int
main(int argc, const char *argv[])
{
	char *endptr;
	char is_dir = 0;
	unsigned perms = 0;
	unsigned uid = (unsigned)-1;
	unsigned gid = (unsigned)-1;

	if (argc < 4) {
		ERROR("Invalid arguments\n");
		print_help();
		exit(-1);
	}

	perms = (unsigned)strtoul(argv[1], &endptr, 0);
	if (!endptr || (endptr == argv[1]) || (*endptr != '\0')) {
		ERROR("current permissions must be a number. Got '%s'.\n", argv[1]);
		exit(-1);
	}

	if (!strcmp(argv[2], "1"))
		is_dir = 1;

	uint64_t capabilities;
	fs_config(argv[3], is_dir, &uid, &gid, &perms, &capabilities);
	fprintf(stdout, "%d %d 0%o\n", uid, gid, perms);

	return 0;
}
