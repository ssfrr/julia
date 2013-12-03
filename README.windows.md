# General Information for Windows

This file provides information specific to using Julia on Windows. Please see the [README](https://github.com/JuliaLang/julia/blob/master/README.md) for more complete information about Julia itself.

Julia runs on Windows XP SP2 or later (including Windows Vista, Windows 7, and Windows 8). Both the 32-bit and 64-bit versions are supported. The 32-bit i686 binary will run on either 32-bit and 64-bit operating systems. The 64-bit x86_64 binary will only run on 64-bit Windows.

Downloading additional libraries (Tk, Cairo, etc) is not necessary. Julia's package manager will acquire them as needed. For this to work, you must have `7z` installed (not the command-line version / 7za) (see below), and it must be on your path.

Julia requires that the lib and lib/julia directories be part of your `%PATH%` variable to startup. The `julia.bat` script will attempt to do this for you and is the recommended way of running julia on your system. The julia.bat file can be given arguments (e.g. `julia.bat -p 2 script.jl` for running script.jl on two processors) which will be passed directly to julia.exe.

# Binary Downloads

1. Install the full [7-Zip](http://www.7-zip.org/download.html) program.
2. Download [the latest version of Julia](http://julialang.org/downloads)
3. Extract the downloaded archive.
4. Double-click the file `julia.bat` to launch Julia.

# Building from source

## Building on Windows using MinGW/MSYS2

1. Install the full [7-Zip](http://www.7-zip.org/download.html) program.

2. Install [MinGW-builds](http://sourceforge.net/projects/mingwbuilds/), a Windows port of GCC.
  a. Download the [MinGW-builds installer](http://downloads.sourceforge.net/project/mingwbuilds/mingw-builds-install/mingw-builds-install.exe) from the [MinGW-builds homepage](http://sourceforge.net/projects/mingwbuilds/). 
  b. Run the installer. When prompted, choose:
    - Version: the most recent version (these instructions were tested with 4.8.1)
    - Architecture: x32 or x64 as desired 
    - Threads: win32 (not posix)
    - Exception: sjlj (for x32) or seh (for x64). Do not choose dwarf2.
    - Build revision: most recent available (tested with 5)
  c. Do **not** install to a directory with spaces in the name. You will have to change the default installation path. Choose instead something like

    C:\mingw-builds\x64-4.8.1-win32-seh-rev5\mingw64

3. Install and configure [MSYS2](http://sourceforge.net/projects/msys2), a minimal POSIX-like environment for Windows.
  a. Download the latest base [32-bit](http://sourceforge.net/projects/msys2/files/Base/32-bit) or [64-bit](http://sourceforge.net/projects/msys2/files/Base/64-bit) distribution as apprpriate.
  b. Using [7-Zip](http://www.7-zip.org/download.html), extract the archive to a convenient directory, e.g. **C:\msys2\x64-20131126**. You may need to extract the tarball in a separate step. This will create an additional `msys32`/`msys64` subdirectory.
    - Some versions of this archive contain zero-byte files that clash with existing files. If prompted, choose to not overwrite all existing files.
  c. Launch `msys2_shell.bat`, which will initialize MSYS2.
  d. Install the necessary packages:

    pacman-key --init #Download keys
    pacman -Syu #Update package database and full system upgrade
    pacman -S git make patch python tar
    
  e. Edit the `/etc/fstab` file and append a line of the form

    C:/mingw-builds/x64-4.8.1-win32-seh-rev5/mingw64 /mingw ext3 binary 0 0

   Use the actual installation directory of MinGW from Step 2c. Consult the
  [Cygwin manual](http://cygwin.com/cygwin-ug-net/using.html#mount-table) for
  details of how to enter the directory name.

  e. Edit the `~/.bashrc` file and append the line
   
    export PATH=$PATH:/mingw/bin

  f. `exit` the MSYS2 shell.
  g. (Optional) Create a shortcut to the `msys2_shell.bat`. This shortcut can be used to launch the MSYS2 shell.


3. Build Julia and its dependencies from source.
  a. Relaunch the MSYS2 shell and type

    . ~/.bashrc #Some versions of MSYS do not run this automatically
    git clone https://github.com/JuliaLang/julia.git
    cd julia
    make

  b. Some versions of PCRE (e.g. 8.31) will compile correctly but have a single
  test fail with an error like

    ** Failed to set locale "fr_FR

  which will break the entire build. To circumvent the test and allow the rest
  of the build to continue, create an empty `checked` file in the `deps/pcre*`
  directory and rerun `make`.

## Cross-compile on Linux/Mac

### Setting up a cross-compiling environment on Ubuntu/Mac OSX (or general Linux distribution)

We need wine, a system compiler, and some downloaders.

On Ubuntu:

    apt-get install wine subversion cvs gcc wget p7zip-full

On Mac: Install
- [XCode](http://developer.apple.com/xcode)
- XCode command line tools:

    xcode-select --install

- [XQuartz](http://xquartz.macosforge.org/)
- [Homebrew](http://mxcl.github.io/homebrew/)
- Wine and wget: 

    brew install wine wget

On Both:

Versions of gcc that are 4.6.x or older do not compile OpenBLAS correctly.
Sometimes gfortran is also unavailable. You may follow these instructions to
obtain a cross-compiling gcc (or obtain an archive copy from @vtjnash). This is
typically quite a bit of work, so we will use [this
script](https://code.google.com/p/mingw-w64-dgn/) to make it easy. 

1. `svn checkout http://mingw-w64-dgn.googlecode.com/svn/trunk/ mingw-w64-dgn`
2. `cd mingw-w64-dgn`
3. edit `rebuild_cross.sh` and make the following two changes:
  a. uncomment `export MAKE_OPT="-j 2"`, if appropriate for your machine
  b. add `fortran` to the end of `--enable-languages=c,c++,objc,obj-c++`
5. `bash update_source.sh`
4. `bash rebuild_cross.sh`
5. `mv cross ~/cross-w64`
6. `export PATH=$HOME/cross-w64/bin:$PATH` # NOTE: it is important that you remember to always do this before using make in the following steps!, you can put this line in your .profile to make it easy

Then we can essentially just repeat these steps for the 32-bit compiler, reusing some of the work:

7. `cd ..`
8. `cp -a mingw-w64-dgn mingw-w32-dgn`
9. `cd mingw-w32-dgn`
10. `rm -r cross build`
11. `bash rebuild_cross.sh 32r`
12. `mv cross ~/cross-w32`
13. `export PATH=$HOME/cross-w32/bin:$PATH` # NOTE: it is important that you remember to always do this before using make in the following steps!, you can put this line in your .profile to make it easy

Note: for systems that support rpm-based package managers, the OpenSUSE build service appears to contain a fully up-to-date versions of the necessary dependencies.

### Arch Linux Dependencies

1. Install the following packages from the official Arch repository:

    sudo pacman -S cloog gcc-ada libmpc p7zip ppl subversion zlib

2. The rest of the prerequisites consist of the mingw-w64 packages, which are available in the AUR Arch repository. They must be installed exactly in the order they are given or else their installation will fail. The `yaourt` package manager is used for illustration purposes; you may instead follow the [Arch instructions for installing packages from AUR](https://wiki.archlinux.org/index.php/Arch_User_Repository#Installing_packages) or may use your preferred package manager. To start with, install `mingw-w64-binutils` via the command
`yaourt -S mingw-w64-binutils`
3. `yaourt -S mingw-w64-headers-svn`
4. `yaourt -S mingw-w64-headers-bootstrap`
5. `yaourt -S mingw-w64-gcc-base`
6. `yaourt -S mingw-w64-crt-svn`
7. Remove `mingw-w64-headers-bootstrap` without removing its dependent mingw-w64 installed packages by using the command
`yaourt -Rdd mingw-w64-headers-bootstrap`
8. `yaourt -S mingw-w64-winpthreads`
9. Remove `mingw-w64-gcc-base` without removing its installed mingw-w64 dependencies:
`yaourt -Rdd mingw-w64-gcc-base`
10. Complete the installation of the required `mingw-w64` packages:
`yaourt -S mingw-w64-gcc`

### Cross-building Julia

Finally, the build and install process for Julia:

1. `git clone https://github.com/JuliaLang/julia.git julia-win32`
2. Set the cross-compile host architecture.
  a. For 32-bit windows:

    echo override XC_HOST = i686-w64-mingw32 >> Make.user

  b. For 32-bit windows:

    echo override XC_HOST = x86_64-w64-mingw32 >> Make.user`

3. `echo override DEFAULT_REPL = basic >> Make.user`
4. `make`
5. `make win-extras`
6. `make run-julia[-release|-debug] [DEFAULT_REPL=(basic|readline)]` (e.g. `make run-julia`)
7. Launch the `julia.bat` script in `usr/bin` to see if it works
8. `make dist`
9. move the julia-* directory / zip file to the target machine

### Troubleshooting

- On the Mac, wine only runs in 32-bit mode.
- Do not use GCC 4.6 or earlier or gcc-dw2, stuff will be broken.
- Julia uses a [patched version](http://github.com/JuliaLang/readline/tarball/master)
  of GNU Readline (this should be downloaded automatically by the build script).
- Run `make win-extras` to download additional runtime dependencies not provided by default in MinGW.
- Do not use the mingw/msys environment from [mingw.org](http://www.mingw.org) as it will miscompile the OpenBLAS math library.
- If you plan to build Cairo (for graphics), you'll also need to install [CMake](http://www.cmake.org/cmake/resources/software.html).

