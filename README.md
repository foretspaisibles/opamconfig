# opamconfig — Detect and store parameters of opam installations

The **opamconfig** project produces a program which helps **opam**
virtual packages to detect and store parameters required to use
third-party libraries when building and installing **opam**
packages. These parameters can then be used by other packages in their
build instructions, *e.g.* to provide `./configure` scripts with
sensible *CFLAGS* and *LDFLAGS* parameters.

Reading this file will tell you:

- How to install **opamconfig**.
- What are the responsibilities of opam virtual packages.
- Which *de facto* standard strategy **opamconfig** uses to detect
  installation parameters of third-party libraries.
- How to use **opamconfig** to write your virtual packages.
- How to use information saved by a virtual package in a dependent
  **opam** package.
- How to get started studying **opamconfig** code and contributing to
  it.

**opamconfig** is free software: copying it and redistributing it is very
much welcome under conditions of the [MIT][licence-url] licence
agreement, found in the [LICENSE][licence-file] file of the
distribution.


## Installation of opamconfig

Users of **opamconfig** can install it with `opam install opamconfig`.

Contributors to **opamconfig** or persons who wants to study its code
should refer to the section “Studying opamconfig code” at the bottom
of this file.


## Responsibilities of opam virtual packages

The **opam** community makes extensive use of **opam** virtual
packages, which are consistently named `conf-*`, to ensure that
various third-party packages or, in some cases, other random features,
are available on a platform where **opam** package depending on them
should be installed.  An **opam** virtual package `conf-whatever`
should endorse the following responsibilities:

  1. Detect presence and installation details (such as installation
     path *e.g.*) of `whatever` feature.

  2. Save these details to the **opam** configuration file allocated
     to the `conf-whatever` package, so that packages depending on
     `conf-whatever` can use these details.

In particular, non-virtual packages using the *os* variable to
specialise their build-instructions should trigger a linter warning or
even an error.

The configuration file allocated to the `conf-whatever` package can be
referred to as `./conf-whatever.config from the build instructions.
This file is made of parameter declarations of the form (note the
usage of double quotes to enclose the value):

    parameter-name: "Parameter value"

In packages depending on `conf-whatever` these parameters can be
referred to as `conf-whatever:parameter-value`.

At the time of writing, many virtual packages do not take care of
saving the result of their detection analysis in their allocated
**opam** configuration file.  This leads to duplication of detection
analysis code, fragile *ad hoc* workarounds and in the end, many
portability and maintenance issues.


## Detection of installation parameters for third party libraries

We consider the example of C library called *PACKAGE* to describe the
detection analysis performed by **opamconfig**.  Headers for a C
library *PACKAGE* are usually installed in a path of the form

    ${PREFIX}/include/${PACKAGEDIR}

where *PREFIX* is typically one of */usr/local* or */opt/local* and
*PACKAGEDIR* is an optional path component used to prevent pathname
collision.  Only a few systems, like **brew** or **opam**, make a
consistant use of the *PACKAGEDIR* optional path component, most
systems leave it empty.  Software artifacts like relocatable libraries
are stored in paths using a similar naming scheme.

Writing a virtual package detecting our third party library would
require to implement the following functionalitites:

1. Prepare a list of *PREFIX* and *PACKAGEDIR* values where the
   *PACKAGE* should be looked up.

2. Write a small program testing *PACKAGE* artifacts can be found
   with the given *PACKAGE* and *PACKAGEDIR*.

3. When software artifacts have been found, save the corresponding parameters
   in **opam** configuration file allocated to our virtual package.

4. When parameters used by the *configure* scripts are set by the
   environment when installing the `conf-*` package, these should be
   used (and stored) instead of using automatically detected
   parameters.  This provides the user with an easy way to circumvent
   auto-detection.

The package **opamconfig** factorises steps 1, 3 and 4 above.


### Example of a virtual package: conf-gmp

Using **opamconfig** allows to write the build rules for **conf-gmp**
as follows:

    build: [
      ["opamconfig" "-d" "gmp:" "-f" "./conf-gmp.config" "sh" "-exc" "cc -c ${CFLAGS} test.c"]
    ]

The argument to the `-d` option is the list of *PACKAGEDIR*
candidates. This is a colon-separated list with two elements, `gmp`
followed by the empty string.

The argument to the `-f` option is the **opam** configuration file
allocated to the **conf-gmp** package.

Upon sucesful installation of the **conf-gmp** package, the following
configuration paramaters have been saved by **opamconfig** in the
**opam** configuration file for **conf-gmp**:

    % cat /opt/opam/4.02.3/lib/conf-gmp/opam.config
    cflags: "-I/opt/local/include/"
    cppflags: "-I/opt/local/include/"
    ldflags: "-L/opt/local/lib/"
    ocamlflags: "-ccopt -I/opt/local/include/ -cclib -L/opt/local/lib/"

These parameters can be used in packages depending on **conf-gmp** to
accurately locate that library, instead of trying to reproduce the
strategy used by **conf-gmp**

The **opamconfig** uses the following list of *PREFIX* values, as
defined by the *prefixdb* function in the source file `opamconfig.sh`:

- If the environment defines a variable *OPAMCONFIG_PREFIXDB* then its
  value is interpreted as a colon separated list of interesting
  *PREFIX* values.

- Otherwise an hard-coded list is used, that list is determined at the
  time where **opamconfig** is installed by looking for popular
  package managers in the path and deducing the corresponding *PREFIX*
  value.  See `configure.ac` and the *prefixdb__heuristic* function
  in `opamconfig.sh` for details.

If we want to use some experimental build of **gmp** we can pass its
installation *PREFIX* to **opamconfig** when we install **conf-gmp**
as:

    env OPAMCONFIG_PREFIXDB='/opt/gmp.master' opam reinstall conf-gmp

Assuming the build instructions using **opamconfig** as demonstrated
above, this would result in the following **opam** configuration file
for **conf-gmp**:

    % cat /opt/opam/4.02.3/lib/conf-gmp/opam.config
    cflags: "-I/opt/gmp-unstable/include/"
    cppflags: "-I/opt/gmp-unstable/include/"
    ldflags: "-L/opt/gmp-unstable/lib/"
    ocamlflags: "-ccopt -I/opt/gmp-unstable/include/ -cclib -L/opt/gmp-unstable/lib/"

When using **opamconfig** in your virtual packages, do not forget to
depend on **opamconfig**, adding **opamconfig** to the `depends` list.


## Example of a package depending on a virtual package: zarith

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
uses values detected by **conf-gmp** to provide sensible parameters
to the `./configure` script.


## Studying opamconfig code

Contributors to **opamconfig** or persons who wants to study its code
should run the following commands in a shell. These command require
**GNU autoconf**:

    git clone https://github.com/michipili/opamconfig
    cd opamconfig
    autoconf
    opam pin add opamconfig .

After this it is possible to amend **opamconfig** code locate in the
`opamconfig.sh` file and install the new version using `opam reinstall
opamconfig`.

Developers wishing a faster *write-test-debug* cycle should
additionally `./configure` their working copy.  When it is done, they
can amend the `opamconfig_test.sh` to test the various subfunctions of
**opamconfig** by running `sh opamconfig_test.sh`.

Michael Grünewald in Zürich, on July 30, 2016

  [licence-url]:        https://opensource.org/licenses/MIT
  [licence-file]:       LICENSE
