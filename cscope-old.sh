adddb()
{
    [ $# -ne 2 ] && echo "Usage: adddb <db name> <path>" >&2 && return 1

    local DB_DIR DB

    DB_DIR=${HOME}/src/cscope
    DB=$1

    [ -d ${DB_DIR}/${DB} ] && echo "adddb: db '${DB}' already exists" >&2 && return 1
    mkdir -p ${DB_DIR}/${DB}

    echo "SRCDIRS=\"$(readlink -f $2)\"" > ${DB_DIR}/${DB}/dirs

    regendb ${DB}
}

listdb()
{
    [ $# -ne 0 ] && echo "Usage: listdb" 1>&2 && return 1
    find ${HOME}/src/cscope -mindepth 2 -maxdepth 2 -name db | xargs dirname
}

setdb()
{
    [ $# -ne 1 ] && echo "Usage: setdb < db-name >" 1>&2 && return 1

    local DB_DIR DB

    DB_DIR=${HOME}/src/cscope

    for DB in $(ls ${DB_DIR}); do
        if [ "$DB" = "$1" ]; then
            export CSCOPE_DB=${DB_DIR}/${1}
            return 0
        fi
    done

    echo "setdb: unknown src tree" 1>&2
    return 1
}

_regendb()
{
    local _DB

    if [ -z "${flavour}" ]; then
        _DB=${DB}
    else
        _DB=${DB}-${flavour}
    fi

    mkdir -p ${DB_DIR}/${_DB}
    cd ${DB_DIR}/${_DB}

    echo "regendb: regenerating ${_DB}" >&2

    truncate -s 0 cscope.files
    tmpf=$(mktemp -t cscope.sh.XXXXXX)

    findargs='( -name *.[chSs] -o -name *.cpp -o -name *.cc -o -name *.hpp )'
    for dir in ${SRCDIRS}; do
        find $(readlink -f ${flavourdir}/${dir}) $findargs -exec readlink -f {} \; >> $tmpf
    done
    for dir in ${DEPDIRS}; do
        find $(readlink -f ${flavourdir}/${dir}) $findargs -exec readlink -f {} \; >> cscope.files
    done
    cat $tmpf >> cscope.files

    if [ ! -f ${DB_DIR}/filelist ]; then
        touch ${DB_DIR}/filelist
    fi

    case $(uname) in
    Linux)
        sed -i -e '/ '${_DB}'$/d' ${DB_DIR}/filelist
        ;;
    FreeBSD)
        sed -i '' -e '/ '${_DB}'$/d' ${DB_DIR}/filelist
        ;;
    *)
        echo "regendb: unhandled OS" >&2
        return 1
        ;;
    esac

    cat $tmpf | sed 's/$/ '${_DB}'/' >> ${DB_DIR}/filelist
    rm -f $tmpf

    [ -n "${flavour}" ] && echo "${DB}" > db

    cscope -b -q -k &
}

regendb()
{
    local DB_DIR DB _DB dirs findargs flavour flavourdir flavours ret tmpf

    pushd . >/dev/null

    ret=0

    DB_DIR=${HOME}/src/cscope
    if [ $# -eq 0 ]; then
        dirs="find $DB_DIR -name dirs -type f -depth 2 -exec dirname {} \;"
    else
        dirs="echo $@"
    fi

    for DB in $(eval $dirs); do
        if [ ! -d "${DB_DIR}/${DB}" ]; then
            echo "regendb: unknown src tree '$DB'" >&2
            ret=1
            break
        fi

        cd ${DB_DIR}/${DB}

        if [ -f db -a -r db ]; then
            _DB=$(cat db)
            flavours=${DB#${_DB}-}
            DB=$_DB

            cd ${DB_DIR}/${_DB}
        elif [ -f flavours -a -r flavours ]; then
            flavours=$(cat flavours)
        else
            flavours=
        fi

        . dirs

        if [ -z "${flavours}" ]; then
            flavourdir=
            _regendb
            if [ $? -ne 0 ]; then
                ret=1
            fi
        else
            for flavour in ${flavours}; do
                flavourdir=$(eval echo $(grep "^${flavour}[[:space:]]" ${DB_DIR}/trees | awk '{print $2}'))
                if [ -z "$flavourdir" ]; then
                    echo "regendb: unknown flavour '${flavour}'" >&2
                    continue
                fi

                _regendb
                if [ $? -ne 0 ]; then
                    ret=1
                fi
            done
        fi

        [ $ret -eq 0 ] || break
    done

    unset SRCDIRS DEPDIRS

    wait
    popd >/dev/null
    return $ret
}

unsetdb()
{
    [ $# -ne 0 ] && echo "Usage: unsetdb" 1>&2 && return 1

    unset CSCOPE_DB
}

edit()
{
    local DB_DIR DB

    if [ $# -eq 1 -a -f "$1" -a -z "$CSCOPE_DB" ]; then
        DB_DIR=${HOME}/src/cscope
        DB=$(fgrep "$(readlink -f $1)" ${DB_DIR}/filelist | awk '{print $NF}')
        if [ -n "$DB" -a $(echo "$DB" | wc -l) -eq 1 ]; then
            setdb $DB
        fi
    fi

    $EDITOR $@

    unset CSCOPE_DB
}

editf()
{
    local files

    [ $# -ne 1 ] && echo "Usage: editf <file>" >&2 && return 1

    files=$(find . -name "$1")
    if [ $(echo "$files" | wc -l) -ne 1 ]; then
        echo "editf: found multiple matches:"
        echo "$files"
        return 1
    fi

    edit "$files"
}

editg()
{
    local _editor

    _editor=$EDITOR
    EDITOR=gvim
    edit $@
    EDITOR=$_editor
}

editw()
{
    local file

    [ $# -ne 1 ] && echo "Usage: editw <file>" >&2 && return 1

    file=$(which "$1")
    if [ $? -ne 0 ]; then
        echo "editw: file '$1' not found in \$PATH"
        return 1
    fi

    edit "$file"
}
