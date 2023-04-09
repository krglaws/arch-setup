#!/bin/bash
get_input_confirm() {
    VARNAME=$1
    PROMPTNAME=$2
    while [ -z ${!VARNAME} ]; do
        read -p "Enter $PROMPTNAME: " $VARNAME
        read -p "Re-enter $PROMPTNAME: " VARNAMECONF
        if [ "${!VARNAME}" != "${VARNAMECONF}" ]; then
            unset $VARNAME
            echo "${PROMPTNAME}s do not match, try again"
        fi
    done
}


