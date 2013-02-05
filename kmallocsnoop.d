#!/usr/sbin/dtrace -s

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing. Hit Ctrl-C to quit.\n");

	printf("%-14s ", "TIMESTAMP");
	printf("%-8s  ", "TYPE");
	printf("%-10s ", "SIZE");
	printf("%-30s ", "DESCRIPTION");
	printf("%-16s ", "ADDRESS");
	printf("\n");
}

fbt::malloc:entry
{
	self->size = args[0];
	self->type = (struct malloc_type *)args[1];
}

fbt::malloc:return
{
	printf("%-14d ",  walltimestamp);
	printf("%-8s  ",  "ALLOC");
	printf("%-10lu ", self->size);
	printf("%-30s ",  stringof(self->type->ks_shortdesc));
	printf("%-16p ",  args[1]);
	printf("\n");
}

fbt::free:entry
/args[0] != NULL/
{
	mtype = (struct malloc_type *)args[1];

	printf("%-14d ",  walltimestamp);
	printf("%-8s  ",  "FREE");
	printf("%-10s ",  "-");
	printf("%-30s ",  stringof(mtype->ks_shortdesc));
	printf("%-16p ",  args[0]);
	printf("\n");
}
