### configure.ac -- Autoconf for opamconfig

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

AC_INIT([opamconfig.sh])

AC_PATH_PROG([PIP], [pip], [no])

# At the time of writing, the following systems appear in depexts
# statements, with their canonical package manager, if any, in the
# second column.
#
#
#   alpine		apk
#   arch		pacman
#   archlinux		pacman
#   centos		yum
#   cygwin		setup.exe
#   dragonfly		pkg
#   debian		apt,apt-get,aptitude,dpkg
#   fedora		yum
#   freebsd		pkg
#   gentoo		emerge
#   homebrew		brew
#   linux		NONE
#   macports		port
#   mageia		yum
#   netbsd		pkg_add
#   nixpkgs		nix-env
#   ocamlfind		ocamlfind
#   openbsd		pkg_add
#   opensuse		zypper
#   oraclelinux		yum
#   osx			NONE
#   rhel		yum
#   source		NONE
#   ubuntu		apt,apt-get,aptitude,dpkg
#   win32		NONE
#   xenserver		NONE
#
#
# Notes:
#
#  1. The primary source for this list is the depext.ml file from the
#     opam-depext plugin ,which ensures that at least all depext
#     supported platforms are also supported by opamconfig.
#
#  2. cygwin lacks a canonical package manager in its standard
#     installation, this is why we use the setup.exe file to discover the
#     canonical prefix for cygwin packages.
#
#  3. debian has no canonical package manager but provides several
#     utilities, I am not sure if the apt* tools can be installed
#     without dpkg, though.

AC_DEFUN([OPAMCONFIG_MACRONAME],
 [m4_quote(m4_bpatsubst(m4_toupper([$1]),[\W],[_]))])

AC_DEFUN([OPAMCONFIG_PATH_PROG],
 [AC_PATH_PROG(OPAMCONFIG_MACRONAME([$1]), [$1], [no])])

OPAMCONFIG_PATH_PROG([apk])
OPAMCONFIG_PATH_PROG([apt])
OPAMCONFIG_PATH_PROG([apt-get])
OPAMCONFIG_PATH_PROG([aptitude])
OPAMCONFIG_PATH_PROG([brew])
OPAMCONFIG_PATH_PROG([dpkg])
OPAMCONFIG_PATH_PROG([emerge])
OPAMCONFIG_PATH_PROG([nix-env])
OPAMCONFIG_PATH_PROG([ocamlfind])
OPAMCONFIG_PATH_PROG([pacman])
OPAMCONFIG_PATH_PROG([pkg])
OPAMCONFIG_PATH_PROG([pkg_add])
OPAMCONFIG_PATH_PROG([port])
OPAMCONFIG_PATH_PROG([setup.exe])
OPAMCONFIG_PATH_PROG([yum])
OPAMCONFIG_PATH_PROG([zypper])

OPAM_OS=$(opam config var os)


#
# Handle various special cases
#

AC_DEFUN([OPAMCONFIG_EXCEPTION],
  [case "${OPAM_OS}-${$2}" in
  *-no)		: ;;
  $1-*)		$2=$3;;
  *)		: ;;
esac;])


# On alpine Linux, apk is installed in /sbin but packages in /usr,
#  which is a different installation prefix.

OPAMCONFIG_EXCEPTION([alpine], [APK], [/usr])


# On FreeBSD, pkg is installed in /usr/sbin but packages are in /usr/local,
#  which is a different installation prefix.

OPAMCONFIG_EXCEPTION([freebsd], [PKG], [/usr/local])


# On NetBSD, pkg_add is installed in /usr/sbin but packages are in /usr/pkg,
#  which is a different installation prefix, while OpenBSD uses /usr/local.

OPAMCONFIG_EXCEPTION([netbsd], [PKG_ADD], [/usr/pkg])
OPAMCONFIG_EXCEPTION([openbsd], [PKG_ADD], [/usr/local])


AC_SUBST([OPAM_OS])
AC_CONFIG_FILES([Makefile.config opamconfig_conf.sh])
AC_OUTPUT

### End of file `configure.ac'
