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
            for dir in ${SRCDIRS}; do
                find $dir -name '*.[chSs]' -o \
                          -name '*.cpp' -o \
                          -name '*.cc' -o \
                          -name '*.hpp' | xargs realpath >> cscope.files
            done
            cscope -b -q -k
            sed -i '' -e '/ '${DB}'$/d' ../filelist
            cat cscope.files | sed 's/$/ '${DB}'/' >> ../filelist
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

    if [ $# -eq 1 ]; then
        DB_DIR=${HOME}/src/cscope
        file=$(realpath $1 | sed 's/\//\\\//g') # Escape slashes.
        DB=$(awk '/^'${file}'/ {print $NF}' ${DB_DIR}/filelist)
        if [ -n "$DB" -a $(echo "$DB" | wc -l) -eq 1 ]; then
            setdb $DB
        fi
    fi

    $EDITOR $@
}
