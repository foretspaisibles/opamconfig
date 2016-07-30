### opamconfig_install.sh -- A standalone installer for opamconfig

# opamconfig (https://github.com/michipili/opamconfig)
# This file is part of opamconfig
#
# Copyright © 2016 Michael Grünewald
#
# This file must be used under the terms of the MIT license.
# This source file is licensed as described in the file LICENSE, which
# you should have received as part of this distribution. The terms
# are also available at
# https://opensource.org/licenses/MIT


# This script allows to install opamconfig without depending on BSD
# Owl and bmake.

PACKAGE='opamconfig_install'


# tmpfile_initializer TMPFILE
#  Create a temporary file
#
# The path to that file is saved in TMPFILE. A hook is registered
# to remove that file upon program termination.

tmpfile_initializer()
{
    local _tmpfile _script
    _tmpfile=$(mktemp -t "${PACKAGE}-XXXXXX")
    _script=$(printf 'rm -f "%s"' "${_tmpfile}")
    trap "${_script}" INT TERM EXIT
    eval $1="${_tmpfile}"
    export $1
}


# configdb
#  Print the configuration database
#
# The database is extracted from Makefile.config thanks to a sed
# script.  It relies on the fact that REPLACESUBST is the last
# variable declared and the only to use the `+=` assignment to
# produce the correct output.

configdb()
{
    sed -n -e '
$ {
  x
  s/\n/ /g
  p
}

/^#/d
/^$/d
s/[[:blank:]]*//g
s/[?]=/=/
/^REPLACESUBST=/{
  h
  b
}
/^REPLACESUBST+=/{
  s/REPLACESUBST+=//
  H
  b
}
p
' Makefile.config
}


# configscript
#  A sed script to replace configuration values

configscript()
{
    configdb | sed -e 's/\(.*\)=\(.*\)/s|@\1@|\2|g/'
}


# replace
#  Replace configuration values in script

replace()
{
    sed -e "$(configscript)" "$@"
}


# actual_install PREFIX
#  Install the script in PREFIX

actual_install()
{
    tmpfile_initializer opamconfig_output
    if ! [ -r "${opamconfig_output}" ]; then
        wlog 'Error: %s: Cannot create temporary file.' "${opamconfig_output}"
        exit 1
    fi
    replace opamconfig.sh > "${opamconfig_output}"
    install -m 755 "${opamconfig_output}" "$1/bin/opamconfig"
    exit $?
}

actual_install "$@"
