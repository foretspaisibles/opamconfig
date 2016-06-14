### detect_configure_settings.sh -- Detect configure settings

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

wlog()
{
    { printf "$@"; printf '\n'; } 1>&2
}

detect_plan()
{
    awk -v envpath="${PATH}" '
function is_valid(prefix) {
  return (prefix != "") && (match(prefix, " ") == 0);
}

BEGIN {
  split(envpath, path, ":");
  for(i in path) {
    prefix = path[i];
    gsub("/s?bin", "", prefix);
    if(is_valid(prefix) && !(prefix in seen)) {
      printf("%s\n", prefix);
    }
    seen[prefix];
  }
}
'
}

detect_execute()
{
    local prefix has_include has_lib

    while read prefix; do
        if test -d "${prefix}/include"; then
            has_include='yes';
        else
            has_include='no';
        fi
        if test -d "${prefix}/lib"; then
            has_lib='yes';
        else
            has_lib='no';
        fi
        printf '%s|%s|%s\n' "${prefix}" "${has_include}" "${has_lib}"
    done
}

detect_opamconf()
{
    awk -F '|' '
function sprint_conf(flag, dir, array, _sep, _prefix, _ax) {
  _sep=""
  for(_prefix in include) {
    _ax= _ax sprintf("%s%s%s/%s", _sep, flag, _prefix, dir);
    _sep=" "
  }
  return _ax
}


$2 == "yes" { include[$1]; include_flag = 1; }
$3 == "yes" { lib[$1]; lib_flag = 1; }

END {
  if(include_flag) {
    printf("cflags: \"CFLAGS=%s\"\n", sprint_conf("-I", "include", include));
    printf("cppflags: \"CPPFLAGS=%s\"\n", sprint_conf("-I", "include", include));
  }
  if(lib_flag) {
    printf("ldflags: \"LDFLAGS=%s\"\n", sprint_conf("-L", "lib", lib));
  }
  if(include_flag || lib_flag) {
    printf("ocamlflags: \"OCAMLFLAGS=%s%s%s\"\n", sprint_conf("-ccopt -I", "include", include), (include_flag ? " " : ""), sprint_conf("-cclib -L", "lib", lib))
  }
}
'
}

(detect_plan | detect_execute | detect_opamconf) > "$1"
