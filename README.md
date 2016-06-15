# opamconfig — Detect and store parameters of opam installations

The **opamconfig** project produces an **opam** virtual package which
detects and store parameters of opam installations. These parameters
can be used by other packages in their build instructions, *e.g.* to
provide `./configure` scripts with sensible *CFLAGS* and *LDFLAGS*
parameters.


## Example

The values detected by **opamconfig** when it is installed can be used
in build instructions of other packages.  For instance, the
not-very-satisfying sequence

```opam
build: [
  ["./configure" "--prefix=%{prefix}%"] { os != "darwin" }
  ["./configure" "LDFLAGS=-L/usr/local/lib" "--prefix=%{prefix}%"] { os = "darwin" }
  [make]
]
```

can be unified to

```opam
build: [
   ["./configure" "--prefix" prefix opamconfig:ldflags]
   [make]
]
```

Please note that using the OS as a proxy for the correct values of
*LDFLAGS* or *CFLAGS* as in the first snippet is broken, as it ignores
special deployments, ignores user-installed software and ignores the
variety of package systems (*brew*, *macports*, *PKGSRC* to quote the
three most used on *darwin* systems).  In contrast, the second snippet
uses values detected by **opamconfig** to provide sensible parameters
to the `./configure` script.

When using in your scripts, do not forget to depend on **opamconfig**,
adding **opamconfig** to the `depends` list.


## Setup guide

It is easy to install **opamconfig** using **opam** and its *pinning*
feature.  In a shell visiting the repository, say

```console
% opam pin add opamconfig .
```


## Parameters detected

The list of paramaters that are currently detected follows, each
variable is accompanied with an example value in lieu of an actual
documentation:


- **cflags:** `CFLAGS=-I/opt/local/Library/Frameworks/Python.framework/Versions/2.7/include -I/opt/X11/include -I/opt/local/include -I/usr/include -I/usr/local/include`

- **cppflags:** `CPPFLAGS=-I/opt/local/Library/Frameworks/Python.framework/Versions/2.7/include -I/opt/X11/include -I/opt/local/include -I/usr/include -I/usr/local/include`

- **ldflags:** `LDFLAGS=-L/opt/local/Library/Frameworks/Python.framework/Versions/2.7/lib -L/opt/X11/lib -L/opt/local/lib -L/usr/lib -L/usr/local/lib`

- **ocamlflags:** `OCAMLFLAGS=-ccopt -I/opt/local/Library/Frameworks/Python.framework/Versions/2.7/include -ccopt -I/opt/X11/include -ccopt -I/opt/local/include -ccopt -I/usr/include -ccopt -I/usr/local/include -cclib -L/opt/local/Library/Frameworks/Python.framework/Versions/2.7/lib -cclib -L/opt/X11/lib -cclib -L/opt/local/lib -cclib -L/usr/lib -cclib -L/usr/local/lib`


## Free software

**opamconfig** is free software: copying it and redistributing it is very
much welcome under conditions of the [MIT][licence-url] licence
agreement, found in the [LICENSE][licence-file] file of the
distribution.

Michael Grünewald in Bonn, on June 14, 2016

  [licence-url]:        https://opensource.org/licenses/MIT
  [licence-file]:       LICENSE
