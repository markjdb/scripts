listdb()
{
    [ $# -ne 0 ] && echo "Usage: listdb" 1>&2 && return 1
    ls -1 ${HOME}/src/cscope
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

regendb()
{
    local DB_DIR DB dirs

    DB_DIR=${HOME}/src/cscope
    if [ $# -eq 0 ]; then
        dirs="find $DB_DIR -type d -depth 1 -exec basename {} \;"
    else
        dirs="echo $@"
    fi

    for DB in $(eval $dirs); do
        echo "Regenerating cscope database for '$DB'" 1>&2
        if [ ! -d "${DB_DIR}/${DB}" ]; then
            echo "regendb: unknown src tree '$DB'" 1>&2
            return 1
        fi
        (
            cd ${DB_DIR}/${DB}
            . dirs
            truncate -s 0 cscope.files
            tmpf=$(mktemp -t cscope.sh.XXXXXX)
            if [ $? -ne 0 ]; then
                tmpf=/tmp/cscope.$$
            fi

            findargs='( -name *.[chSs] -o -name *.cpp -o -name *.cc -o -name *.hpp )'
            for dir in ${SRCDIRS}; do
                find $(readlink -f $dir) $findargs -exec readlink -f {} \; >> $tmpf
            done
            for dir in ${DEPDIRS}; do
                find $(readlink -f $dir) $findargs -exec readlink -f {} \; >> cscope.files
            done
            cat $tmpf >> cscope.files

            cscope -b -q -k
            case $(uname) in
            Linux)
                sed -i -e '/ '${DB}'$/d' ../filelist
                ;;
            FreeBSD)
                sed -i '' -e '/ '${DB}'$/d' ../filelist
                ;;
            *)
                echo "regendb: unhandled OS" >&2
                ;;
            esac
            cat $tmpf | sed 's/$/ '${DB}'/' >> ../filelist
            rm -f $tmpf
        )
    done
}

unsetdb()
{
    [ $# -ne 0 ] && echo "Usage: unsetdb" 1>&2 && return 1

    unset CSCOPE_DB
}

edit()
{
    local DB_DIR DB file

    if [ $# -eq 1 -a -f "$1" -a -z "$CSCOPE_DB" ]; then
        DB_DIR=${HOME}/src/cscope
        file=$(readlink -f $1 | sed 's/\//\\\//g') # Escape slashes.
        DB=$(awk '/^'${file}' / {print $NF}' ${DB_DIR}/filelist)
        if [ -n "$DB" -a $(echo "$DB" | wc -l) -eq 1 ]; then
            setdb $DB
        fi
    fi

    $EDITOR $@
}
