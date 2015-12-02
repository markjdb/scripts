_CSCOPE_DB_DIR=${HOME}/src/cscope2
_CSCOPE_DB_LIST=${_CSCOPE_DB_DIR}/dbs
_CSCOPE_FILE_LIST=${_CSCOPE_DB_DIR}/files
_CSCOPE_TEMPLATE_DIR=${_CSCOPE_DB_DIR}/templates

# Add a source directory to the cscope DB set.
csc-add-db()
{
    if [ $# -ne 2 ]; then
        echo "usage: csc-add-db <template> <base dir>" >&2
        return 1
    fi

    local base db template uuid

    template=$1
    base=$(readlink -f "$2")

    if [ ! -d ${_CSCOPE_TEMPLATE_DIR}/$template ]; then
        echo "csc-add-db: non-existent template $template" >&2
        return 1
    fi

    db=$(awk "{if (\$2 == \"${base}\") print \$1}" ${_CSCOPE_DB_LIST})
    if [ -n "${db}" ]; then
        echo "csc-add-db: database already exists" >&2
        return 1
    fi

    uuid=$(uuidgen)
    echo "$uuid $base" >> $_CSCOPE_DB_LIST

    db=$uuid
    mkdir -p ${_CSCOPE_DB_DIR}/$db
    echo $template > ${_CSCOPE_DB_DIR}/${db}/template
    ( _csc-regen-db $base $db )
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

    truncate -s 0 cscope.files
    for dir in ${SRCDIRS}; do
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

csc-regen-db()
{
    local base db

    if [ $# -eq 0 ]; then
        base=$(readlink -f .)
    elif [ $# -ne 1 ]; then
        echo "usage: csc-regen-db <base dir>" >&2
        return 1
    else
        base=$(readlink -f $1)
    fi

    db=$(awk "{if (\$2 == \"${base}\") print \$1}" ${_CSCOPE_DB_LIST})
    if [ -z "$db" ]; then
        echo "csc-regen-db: no such db" >&2
        return 1
    fi

    ( _csc-regen-db $base $db )
    return $?
}
