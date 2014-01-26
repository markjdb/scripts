goto()
{
    local name path

    [ $# -ne 1 ] && echo "Usage: goto <label>" >&2 && return 1

    name=__goto_$1
    path=$(eval echo \$$name)
    if [ -n "$path" ]; then
        cd "$path"
    else
        echo "goto: undefined path label '$name'" >&2
        return 1
    fi
}

addgoto()
{
    local label oldpath path

    [ $# -ne 2 ] && echo "Usage: addgoto <label> <path>" >&2 && return 1

    if [ ! -r ${HOME}/.gotos ]; then
        touch ${HOME}/.gotos
    fi

    label=$1
    path=$2
    oldpath=$(eval echo \$__goto_$label)

    [ -n "$oldpath" ] && echo "addgoto: redefining label from '$oldpath'" >&2

    sed -i'' -e "/^[[:space:]]*${label}[[:space:]][[:space:]]*/d" ${HOME}/.gotos
    echo "$label $path" >> ${HOME}/.gotos

    sourcegotos
}

listgotos()
{
    # There's probably a better way to do this. :)
    env | grep '^__goto_' | sed -e 's/^__goto_//' | tr '=' ' ' | column -t
}

sourcegotos()
{
    local i label path

    [ $# -ne 0 ] && echo "sourcegotos: unexpected arguments" >&2 && return 1

    [ -r ${HOME}/.gotos ] || return

    i=1
    while read label path; do
        if [ -z "$label" -o -z "$path" ]; then
            echo "sourcegotos: warning: invalid goto definition on line $i" >&2
            continue
        fi

        eval export __goto_${label}=$path

        i=$(($i + 1))
    done < ${HOME}/.gotos
}

sourcegotos
