#!/usr/sbin/dtrace -s

syscall::semop:entry
/execname == "postgres"/
{
	self->s = timestamp;
	self->id = arg0;
	self->nops = (int)arg2;
	self->op = arg1;
}

syscall::semop:return
/self->s != 0 && (timestamp - self->s) > 1000000000/
{
	buf = (struct sembuf *)copyin(self->op, 4);

	printf("%Y: long-running semop: (semid %d, nops %d, op %d, flgs 0x%x) (PID %d), %dms",
	    walltimestamp, self->id, self->nops, buf->sem_op, buf->sem_flg, curpsinfo->pr_pid,
	    (timestamp - self->s) / 1000000);
	self->nops = 0;
	self->id = 0;
	self->op = 0;
	self->s = 0;
}
