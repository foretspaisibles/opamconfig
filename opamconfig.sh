### opamconfig.sh -- Detect configure settings

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

PACKAGE='opamconfig'

: ${ac_opam_os:=@AC_OPAM_OS@}
: ${ac_path_apk:=@AC_PATH_APK@}
: ${ac_path_apt:=@AC_PATH_APT@}
: ${ac_path_aptitude:=@AC_PATH_APTITUDE@}
: ${ac_path_apt_get:=@AC_PATH_APT_GET@}
: ${ac_path_brew:=@AC_PATH_BREW@}
: ${ac_path_dpkg:=@AC_PATH_DPKG@}
: ${ac_path_emerge:=@AC_PATH_EMERGE@}
: ${ac_path_nix_env:=@AC_PATH_NIX_ENV@}
: ${ac_path_ocamlfind:=@AC_PATH_OCAMLFIND@}
: ${ac_path_pacman:=@AC_PATH_PACMAN@}
: ${ac_path_pkg:=@AC_PATH_PKG@}
: ${ac_path_pkg_add:=@AC_PATH_PKG_ADD@}
: ${ac_path_port:=@AC_PATH_PORT@}
: ${ac_path_setup_exe:=@AC_PATH_SETUP_EXE@}
: ${ac_path_yum:=@AC_PATH_YUM@}
: ${ac_path_zypper:=@AC_PATH_ZYPPER@}


# wlog PRINTF-LIKE-ARGV
#  Print PRINTF-LIKE-ARGV on stderr

wlog()
{
    { printf "$@"; printf '\n'; } 1>&2
}


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


# uniq
#  Filter skipping duplicate lines

uniq()
{
    awk '
!( $0 in seen ) {
  print
  seen[$0]
}
'
}


# fold
#  Fold input lines into a single line
#
# Previous lines are separated by a ':'.

fold()
{
    tr '\n' ':'
}


# variabledb
#  Print the configuration variable database

variabledb()
{
    cat <<'EOF'
CFLAGS|cflags|-I${PREFIX}/include/${PACKAGEDIR}
CPPFLAGS|cppflags|-I${PREFIX}/include/${PACKAGEDIR}
LDFLAGS|ldflags|-L${PREFIX}/lib/${PACKAGEDIR}
OCAMLFLAGS|ocamlflags|-ccopt -I${PREFIX}/include/${PACKAGEDIR} -cclib -L${PREFIX}/lib/${PACKAGEDIR}
EOF
}


# prefixdb
#  Print the prefix database

prefixdb()
{
    if [ -z "${OPAMCONFIG_PREFIX}" ]; then
        prefixdb__heuristic | tr ':' '\n'
    else
        printf '%s' "${OPAMCONFIG_PREFIXDB}" | tr ':' '\n'
    fi
}

prefixdb__heuristic()
{
    { sed -e '
# Skip comments
/^#/d

# Skip package managers not found by the configure script
/|no$/d

# Derive installation prefixes,
#  by removing the s?bin part of the name
s@/sbin$@@
s@/bin$@@
/^$/d
' | uniq; } <<EOF
${ac_path_apk%/*}
# ${ac_path_apt%/*}
#   On OS-X apt is also the name of a standard utiliy and Debian
#   based systems also provide dpkg.
${ac_path_aptitude%/*}
${ac_path_apt_get%/*}
${ac_path_brew%/*}
${ac_path_dpkg%/*}
${ac_path_emerge%/*}
${ac_path_nix_env%/*}
${ac_path_ocamlfind%/*}
${ac_path_pacman%/*}
${ac_path_pkg%/*}
${ac_path_pkg_add%/*}
${ac_path_port%/*}
${ac_path_setup_exe%/*}
${ac_path_yum%/*}
${ac_path_zypper%/*}
EOF
}


# packagedirdb
#  Print the packagedir database

packagedirdb()
{
    printf '%s' "${opamconfig_packagedirdb}" | tr ':' '\n'
}


# pathmatrix PREFIX-LIST PACKAGEDIR-LIST
#  Print the path matrix deduced from PATTERN by substitution
#
# Arguments PREFIX-LIST and PACKAGE-LIST are lists of path fragments,
# separated by ':'.

pathmatrix()
{
    variabledb | awk -F '|' -v "prefixlist=$1" -v "packagedirlist=$2" '
function pathelement(p, d, _a) {
  _a = pattern
  gsub("[$]{PREFIX}", p, _a)
  gsub("[$]{PACKAGEDIR}", d, _a)
  sub("/$", "", _a)
  return _a
}

function q(text, _answer, _squote) {
  _squote = sprintf("%c", 39)
  _answer = text;
  gsub(_squote, _squote _squote, _answer);
  return sprintf("%s%s%s", _squote, _answer, _squote);
}

BEGIN {
  prefixsz = split(prefixlist, prefix, ":")
  packagedirsz = split(packagedirlist, packagedir, ":")
}

{ pattern = sprintf("%s %s=%s", pattern, $1, q($3)) }

END {
  sub("^ ", "", pattern)
  for(p = 1; p <= prefixsz; ++p)
    for(d = 1; d <= packagedirsz; ++d) {
      print(pathelement(prefix[p], packagedir[d]))
    }
}
'
}


# print_config
#  Print the configuration defiend by the current environment

print_config()
{
    variabledb | awk -F '|' '
function q(text, _answer, _squote) {
  _squote = sprintf("%c", 34)
  _answer = text;
  gsub(_squote, _squote _squote, _answer);
  return sprintf("%s%s%s", _squote, _answer, _squote);
}

{printf("%s: %s\n", $2, q(ENVIRON[$1]))}
'
}


# runtest PREFIX-LIST PACKAGEDIR-LIST

runtest()
{
    local prefixlist packagedirlist

    tmpfile_initializer tmpfile

    prefixlist="$1"
    packagedirlist="$2"
    shift 2

    pathmatrix "${prefixlist}" "${packagedirlist}" | runtest__loop "$@"

    [ -s "${tmpfile}" ]
}

runtest__loop()
{
    local variable environment

    for variable in $(variabledb | awk -F '|' '{print($1)}'); do
        export ${variable}
    done

    while read environment; do
        eval ${environment}
        if "$@"; then
            print_config > "${tmpfile}"
            exit
        fi
    done
}


print_help()
{
    iconv -f utf-8 -c <<EOF
Usage: ${PACKAGE} [-d PACKAGEDIRDB]
 Detect configure settings
Options:
 -d PACKAGEDIRDB
    Use PACKAGEDIRDB as list of package directories.
 -f OUTPUT-FILE
    Write resulting configuration to OUTPUT-FILE.
EOF
}


opamconfig_action_help()
{
    print_help
    exit 0
}

opamconfig_action_runtest()
{
    if runtest "$(prefixdb|fold)" "${opamconfig_packagedirdb}" "$@"; then
        cp "${tmpfile}" "${opamconfig_outputfile}"
        wlog 'opamconfig: Results saved in %s' "${opamconfig_outputfile}"
        exit 0
    else
        wlog 'opamconfig: Could not locate third party package.'
        exit 1
    fi
}


opamconfig_action='runtest'
opamconfig_packagedirdb=':'
opamconfig_outputfile='/dev/null'

opamconfig_main()
{
    while getopts 'd:f:h' OPTION; do
        case "${OPTION}" in
            d)	opamconfig_packagedirdb="${OPTARG}";;
            f)	opamconfig_outputfile="${OPTARG}";;
            h)	opamconfig_action='help';;
            ?)	opamconfig_action_usage 64;;
        esac
    done

    shift $(( OPTIND - 1 ))
    opamconfig_action_${opamconfig_action} "$@"
}

if [ -n "${opamconfig_test}" ]; then
    : 'We run in test mode.'
else
    opamconfig_main "$@"
fi
