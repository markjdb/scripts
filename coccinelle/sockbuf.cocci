// This needs to be run with --no-loops --no-gotos to have any chance
// of completing in a reasonable time frame.
//
// N.B. I am sure there is a nicer way to write these rules..

@rule1@
expression so;
@@

(
- SOCKBUF_LOCK(&so->so_snd);
+ SOCK_SENDBUF_LOCK(so);
|
- SOCKBUF_LOCK(&so->so_rcv);
+ SOCK_RECVBUF_LOCK(so);
|
- SOCKBUF_UNLOCK(&so->so_snd);
+ SOCK_SENDBUF_UNLOCK(so);
|
- SOCKBUF_UNLOCK(&so->so_rcv);
+ SOCK_RECVBUF_UNLOCK(so);
|
- SOCKBUF_LOCK_ASSERT(&so->so_snd);
+ SOCK_SENDBUF_LOCK_ASSERT(so);
|
- SOCKBUF_UNLOCK_ASSERT(&so->so_snd);
+ SOCK_SENDBUF_UNLOCK_ASSERT(so);
|
- SOCKBUF_LOCK_ASSERT(&so->so_rcv);
+ SOCK_RECVBUF_LOCK_ASSERT(so);
|
- SOCKBUF_UNLOCK_ASSERT(&so->so_rcv);
+ SOCK_RECVBUF_UNLOCK_ASSERT(so);
)

@rule2@
expression so;
identifier sb;
@@

(
struct sockbuf *sb = &so->so_snd;
|
sb = &so->so_snd;
)
<...
(
- SOCKBUF_LOCK(sb);
+ SOCK_SENDBUF_LOCK(so);
|
- SOCKBUF_UNLOCK(sb);
+ SOCK_SENDBUF_UNLOCK(so);
|
- SOCKBUF_LOCK_ASSERT(sb);
+ SOCK_SENDBUF_LOCK_ASSERT(so);
|
- SOCKBUF_UNLOCK_ASSERT(sb);
+ SOCK_SENDBUF_UNLOCK_ASSERT(so);
)
...>

@rule3@
expression so;
identifier sb;
@@

(
struct sockbuf *sb = &so->so_rcv;
|
sb = &so->so_rcv;
)
<...
(
- SOCKBUF_LOCK(sb);
+ SOCK_RECVBUF_LOCK(so);
|
- SOCKBUF_UNLOCK(sb);
+ SOCK_RECVBUF_UNLOCK(so);
|
- SOCKBUF_LOCK_ASSERT(sb);
+ SOCK_RECVBUF_LOCK_ASSERT(so);
|
- SOCKBUF_UNLOCK_ASSERT(sb);
+ SOCK_RECVBUF_UNLOCK_ASSERT(so);
)
...>
