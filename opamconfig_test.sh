### opamconfig_test.sh -- Testtool for opamconfig

# opamconfig (https://github.com/michipili/opamconfig)
# This file is part of opamconfig
#
# Copyright © 2016–2017 Michael Grünewald
#
# This file must be used under the terms of the MIT license.
# This source file is licensed as described in the file LICENSE, which
# you should have received as part of this distribution. The terms
# are also available at
# https://opensource.org/licenses/MIT

opamconfig_test='yes'

. 'opamconfig_conf.sh'
. 'opamconfig.sh'

PACKAGE='opamconfig_test'

print_testhelp()
{
    iconv -f utf-8 -c <<EOF
Usage: ${PACKAGE} [-ph]
 Detect configure settings
Options:
 -I Exercise the variable function.
 -h Print a help message.
 -p Exercise the pathmatrix function.
EOF
}


test_action_help()
{
    print_testhelp
    exit 0
}


test_action_pathmatrix()
{
    wlog 'Test: Exercise the pathmatrix function.'
    wlog ' PREFIX-LIST: %s' "$1"
    wlog ' PACKAGEDIR-LIST: %s' "$2"
    wlog '================================================================================'
    pathmatrix "$@"
}

test_action_variable()
{
    wlog 'Test: Exercise the print variable function.'
    opamconfig_variable='CFLAGS'
    opamconfig_action_variable conf-gmp conf-gmp
}

test_action='help'

while getopts 'Ihp' OPTION; do
    case "${OPTION}" in
        I)	test_action='variable';;
        h)	test_action='help';;
        p)	test_action='pathmatrix';;
        ?)	test_action_usage 64;;
    esac
done

shift $(( OPTIND - 1 ))
test_action_${test_action} "$@"
