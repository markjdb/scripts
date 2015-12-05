# XXX we need locking

_CSCOPE_DB_DIR=${HOME}/src/cscope2
_CSCOPE_DB_LIST=${_CSCOPE_DB_DIR}/dbs
_CSCOPE_FILE_LIST=${_CSCOPE_DB_DIR}/files
_CSCOPE_TEMPLATE_DIR=${_CSCOPE_DB_DIR}/templates

# Look up cscope database UUIDs, given a base directory.
_csc-find-dbs()
{
    local base

    base=$(readlink -f $1)
    awk "{if (\$2 == \"${base}\") print \$1}" $_CSCOPE_DB_LIST
}

_csc-rm-db()
{
    local db

    db=$1
    rm -rf ${_CSCOPE_DB_DIR}/$db
    sed -i '' "/${db}\$/d" $_CSCOPE_FILE_LIST
    sed -i '' "/^${db}/d" $_CSCOPE_DB_LIST
}

# Add a source directory to the cscope DB set.
csc-add-db()
{
    if [ $# -ne 2 ]; then
        echo "usage: csc-add-db <template> <base dir>" >&2
        return 1
    fi

    local base db dbs template uuid

    template=$1
    base=$(readlink -f "$2")

    if [ ! -d ${_CSCOPE_TEMPLATE_DIR}/$template ]; then
        echo "csc-add-db: non-existent template $template" >&2
        return 1
    fi

    # Make sure we don't create DBs using the same base dir and template.
    dbs=$(_csc-find-dbs ${base})
    for db in ${dbs}; do
        if [ "$(cat ${_CSCOPE_DB_DIR}/${db}/template)" = $template ]; then
            echo "csc-add-db: database already exists" >&2
            return 1
        fi
    done

    uuid=$(uuidgen)
    echo "$uuid $base" >> $_CSCOPE_DB_LIST

    db=$uuid
    mkdir -p ${_CSCOPE_DB_DIR}/$db
    echo $template > ${_CSCOPE_DB_DIR}/${db}/template
    ( _csc-regen-db $base $db )
    if [ $? -ne 0 ]; then
        # Clean up.
        _csc-rm-db $db
    fi
}

csc-rm-dbs()
{
    if [ $# -ne 1 ]; then
        echo "usage: csc-rm-dbs <base dir>" >&2
        return 1
    fi

    local base db dbs

    base=$1
    dbs=$(_csc-find-dbs ${base})
    if [ -z "${db}" ]; then
        echo "csc-rm-dbs: no dbs for this dir" >&2
        return 1
    fi

    for db in ${dbs}; do
        _csc-rm-db ${db}
    done
}

# Edit a file, transparently selecting the correct cscope DB.
csc-edit()
{
    local db file nmatch

    if [ $# -eq 1 -a -f "$1" -a -z "$CSCOPE_DB" ]; then
        file=$(readlink -f "$1")
        db=$(awk "{if (\$1 == \"${file}\") print \$2}" ${_CSCOPE_FILE_LIST})
        nmatch=$(echo "$db" | wc -l)
        if [ $nmatch -gt 1 ]; then
            echo "csc-edit: multiple matches: $db" >&2
            return 1
        elif [ $nmatch -eq 0 ]; then
            echo "csc-edit: no matches" >&2
            return 1
        fi
        _csc-setdb $db
    fi

    $EDITOR $@

    unset CSCOPE_DB
}

edit()
{
    csc-edit $@
}

csc-editf()
{
    local files

    if [ $# -ne 1 ]; then
        echo "usage: csc-editf <file>" >&2
        return 1
    fi

    files=$(find . -name "$1")
    if [ $(echo "$files" | wc -l) -ne 1 ]; then
        echo "editf: found multiple matches:" >&2
        echo "$files" >&2
        return 1
    fi

    csc-edit "$files"
}

editf()
{
    csc-editf $@
}

# One-time init function.
csc-init()
{
    if [ $# -ne 0 ]; then
        echo "usage: csc-init" >&2
        return 1
    fi

    mkdir -p ${_CSCOPE_DB_DIR}
    mkdir ${_CSCOPE_TEMPLATE_DIR}
    mkdir ${_CSCOPE_TEMPLATE_DIR}/default
    touch ${_CSCOPE_DB_LIST}
    echo "SRCDIRS=." > ${_CSCOPE_TEMPLATE_DIR}/default/dirs
    mkdir ${_CSCOPE_TEMPLATE_DIR}/freebsd-kernel
    echo "SRCDIRS=sys" > ${_CSCOPE_TEMPLATE_DIR}/freebsd-kernel/dirs
    mkdir ${_CSCOPE_TEMPLATE_DIR}/onefs-kernel
    echo "SRCDIRS=sys" > ${_CSCOPE_TEMPLATE_DIR}/onefs-kernel/dirs
    mkdir ${_CSCOPE_TEMPLATE_DIR}/illumos-kernel
    echo "SRCDIRS=usr/src/uts" > ${_CSCOPE_TEMPLATE_DIR}/illumos-kernel/dirs
    mkdir ${_CSCOPE_TEMPLATE_DIR}/linux-kernel
    echo "SRCDIRS=." > ${_CSCOPE_TEMPLATE_DIR}/linux-kernel/dirs
}

_csc-setdb()
{
    local db

    db=$1
    export CSCOPE_DB=${_CSCOPE_DB_DIR}/$db
}

# Private function to generate a DB given its name and the base dir. The public
# version of this function takes only the base dir as its argument.
#
# This function must be run in a subshell to avoid polluting the environment.
_csc-regen-db()
{
    local base db dir patterns template tmpf

    set -e

    base=$1
    db=$2

    cd ${_CSCOPE_DB_DIR}/$db
    if [ $? -ne 0 ]; then
        echo "_csc-regen-db: no such db $db" >&2
        return 1
    fi

    template=$(cat template)
    if [ ! -d ${_CSCOPE_TEMPLATE_DIR}/$template ]; then
        echo "_csc-regen-db: non-existent template $template" >&2
        return 1
    fi

    . ${_CSCOPE_TEMPLATE_DIR}/${template}/dirs

    patterns='-name *.[chSs] -o -name *.cpp -o -name *.cc -o -name *.hpp'
    tmpf=$(mktemp)

    echo "base is $base"

    truncate -s 0 cscope.files
    for dir in ${SRCDIRS}; do
        echo "dir is $dir"
        find $(readlink -f ${base}/${dir}) \( $patterns \) -print >> $tmpf
    done
    for dir in ${DEPDIRS}; do
        find $(readlink -f ${base}/${dir}) \( $patterns \) -print >> cscope.files
    done
    cat $tmpf >> cscope.files

    touch $_CSCOPE_FILE_LIST

    # Clear existing file list entries for this db.
    sed -i '' -e "/ ${db}\$/d" $_CSCOPE_FILE_LIST

    awk "{print \$1, \"${db}\"}" $tmpf >> $_CSCOPE_FILE_LIST

    rm -f $tmpf

    cscope -b -q -k
}

csc-regen-dbs()
{
    local base db dbs ret

    if [ $# -eq 0 ]; then
        base=$(readlink -f .)
    elif [ $# -ne 1 ]; then
        echo "usage: csc-regen-dbs <base dir>" >&2
        return 1
    else
        base=$(readlink -f $1)
    fi

    dbs=$(_csc-find-dbs ${base})
    if [ -z "$dbs" ]; then
        echo "csc-regen-dbs: no such db" >&2
        return 1
    fi

    for db in ${dbs}; do
        ( _csc-regen-db $base $db )
        ret=$?
        if [ $ret -ne 0 ]; then
            return $ret
        fi
    done
}
