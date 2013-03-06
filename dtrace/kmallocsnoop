#!/usr/sbin/dtrace -s

#pragma D option quiet

#pragma D option bufsize=16m

dtrace:::BEGIN
{
	printf("Tracing. Hit Ctrl-C to quit.\n");

	printf("%-20s ", "TIMESTAMP");
	printf("%-8s  ", "TYPE");
	printf("%-10s ", "SIZE");
	printf("%-15s ", "DESCRIPTION");
	printf("%-18s ", "ADDRESS");
	printf("\n");
}

fbt::malloc:entry
{
	self->size = args[0];
	self->type = (struct malloc_type *)args[1];
}

fbt::malloc:return
/args[1] != NULL/
{
	printf("%-20d ",  walltimestamp);
	printf("%-8s  ",  "ALLOC");
	printf("%-10lu ", self->size);
	printf("%-15s ",  stringof(self->type->ks_shortdesc));
	printf("0x%-16p ",  args[1]);
	printf("\n");
}

fbt::free:entry
/args[0] != NULL/
{
	mtype = (struct malloc_type *)args[1];

	printf("%-20d ",  walltimestamp);
	printf("%-8s  ",  "FREE");
	printf("%-10s ",  "-");
	printf("%-15s ",  stringof(mtype->ks_shortdesc));
	printf("0x%-16p ",  args[0]);
	printf("\n");
}
