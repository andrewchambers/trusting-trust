
int
isalpha(int c)
{
	return ((unsigned)c|32)-'a' < 26;
}

int
isblank(int c)
{
	return (c == ' ' || c == '\t');
}

int isprint(int c)
{
	return (unsigned)c-0x20 < 0x5f;
}

int isalnum(int c)
{
	return isalpha(c) || isdigit(c);
}

void
abort()
{
	exit(111);
}

int
fscanf(void *stream, const char *format, ...) {
	// abort();
	return -1;
}

int freopen(const char * pathname, const char * mode,
					 void *stream)
{
	return -1;
}

void perror(char *s)
{
}

char *strpbrk(const char *s, const char *accept) {
	unsigned int i;
	for (; *s; s++)
		for (i=0; accept[i]; i++)
			if (*s == accept[i])
				return (char*)s;
	return 0;
}