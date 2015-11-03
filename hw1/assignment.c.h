#include <dirent.h>

const char*
search_exe(const char *exe) {

	char *path = getenv("PATH");
	char *tok = path;
	DIR *d = NULL;
	struct dirent *dir = NULL;
	char* ret_path;

      	while(NULL != (tok = strtok(tok, ":"))) {
		if (NULL != (d = opendir(tok))) {
			while(NULL != (dir = readdir(d))) {
				if (0 == strcmp(dir->d_name, exe)) {
					if (NULL != (ret_path = (char*)malloc(strlen(tok) + strlen(exe) + 2)));
					ret_path = strcat(ret_path, tok);
					ret_path = strcat(ret_path, "/");
					ret_path = strcat(ret_path, exe);
					return ret_path;
				}
			}	

		}
		
		tok = NULL;
	}
}
