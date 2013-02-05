#!/usr/sbin/dtrace -s

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing. Hit Ctrl-C to quit.\n");

	printf("%-20s ", "TIME");
	printf("%-10s ", "SIZE");
	printf("%-30s ", "DESCRIPTION");
}

fbt::malloc:entry
{
	mtype = (struct malloc_type *)args[1];

	printf("%-20Y ",  walltimestamp);
	printf("%-10lu ", args[0]);
	printf("%-30s ",  stringof(mtype->ks_shortdesc));
	printf("\n");
}
