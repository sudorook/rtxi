#!/bin/bash

# Autogenerate plugins/Makefile.am
PLUGINS_SUBDIRS=`ls plugins/*/Makefile.am | sed -e 's/^plugins\///g' | sed -e 's/\/Makefile.am$//g' | sed -e 's/\n/ /g'`
cat > plugins/Makefile.am << EOF
# This file is automatically generated by autogen.sh

CLEANFILES = */*~
DISTCLEANFILES =
MAINTAINERCLEANFILES = Makefile.in

SUBDIRS = `echo $PLUGINS_SUBDIRS`
EOF

# Autogenerate configure.in
MAKEFILES="`find plugins -name Makefile.am | sed -e 's/.am$//g'`"
cat > configure.in << EOF
# This file is automatically generated by autogen.sh

AC_INIT([RTXI],[1.1.0],[rtxi-user@lists.sourceforge.net],rtxi)

AM_CONFIG_HEADER(include/rtxi_config.h)
AM_INIT_AUTOMAKE

AC_PROG_LIBTOOL
AC_PROG_CC
AC_PROG_CXX

BNV_HAVE_QT

if test "\$have_qt" != "yes" ; then
    AC_MSG_ERROR([Qt not found; see help on how to specify Qt location])
fi

rtos=""

AC_CHECK_RTAI
AC_ARG_ENABLE(xenomai,
  [  --enable-xenomai       build the Xenomai interface],
  [case "${enablecal}" in
    "" | y | ye | yes) rtos=xenomai;;
    n | no);;
    *) AC_MSG_ERROR(bad value ${enableval} for --enable-xenomai);;
  esac],
  [])
AC_ARG_ENABLE(posix,
  [  --enable-posix         build the POSIX non-RT interface],
  [case "${enableval}" in
    "" | y | ye | yes) rtos=posix;;
    n | no);;
    *) AC_MSG_ERROR(bad value ${enableval} for --enable-posix);;
  esac],
  [])

AM_CONDITIONAL(RTAI3, test x\$rtos = xrtai3)
AM_CONDITIONAL([XENOMAI],[test x\$rtos = xxenomai])
AM_CONDITIONAL([POSIX],[test x\$rtos = xposix])
if test x\$rtos = xrtai3; then
  RTOS_CPPFLAGS=\$RTAI_CPPFLAGS
  RTOS_LDFLAGS=\$RTAI_LDFLAGS
elif test x\$rtos = xxenomai -a -x /usr/xenomai/bin/xeno-config; then
  RTOS_CPPFLAGS=\`/usr/xenomai/bin/xeno-config --xeno-cflags\`
  RTOS_LDFLAGS="\`/usr/xenomai/bin/xeno-config --xeno-ldflags\` -lnative"
elif test x\$rtos = xposix; then
  RTOS_CPPFLAGS=
  RTOS_LDFLAGS=-lpthread
elif test x\$rtos = x;then
  AC_MSG_ERROR([no realtime system found])
fi
AC_SUBST(RTOS_CPPFLAGS)
AC_SUBST(RTOS_LDFLAGS)

AC_ARG_ENABLE(debug,
  [  --enable-debug          turn on debugging],
  [case "\${enableval}" in
    "" | y | ye | yes) debug=true ;;
    n | no) debug=false ;;
    *) AC_MSG_ERROR(bad value \${enableval} for --enable-debug) ;;
  esac],
  [debug=false])
AM_CONDITIONAL(DEBUG, test x\$debug = xtrue)

if test x\$rtos = xrtai3; then
  AC_ARG_ENABLE(comedi,
    [  --enable-comedi        build the comedi driver],
    [case "\${enableval}" in
      "" | y | ye | yes) comedi=true;;
      n | no) comedi=false;;
      *) AC_MSG_ERROR(bad value \${enableval} for --enable-comedi);;
    esac],
    [comedi=true])
  AM_CONDITIONAL(BUILD_COMEDI, test x\$comedi = xtrue)
else
  AM_CONDITIONAL(BUILD_COMEDI,false)
fi

AC_ARG_ENABLE(ni,
  [  --enable-ni            build the ni driver],
  [case "\${enableval}" in
    "" | y | ye | yes) ni=true;;
    n | no) ni=false;;
    *) AC_MSG_ERROR(bad value \${enableval} for --enable-ni);;
  esac],
  [ni=false])
AM_CONDITIONAL(BUILD_NI, test x\$ni = xtrue)

dnl Clear build variables

INCLUDES=
DEFS=
CPPFLAGS=
CXXFLAGS=
CFLAGS=
LDADD=
LDFLAGS=
LIBS=

dnl Create makefiles and other configuration files
AC_CONFIG_FILES([
Makefile
hdf/Makefile
rtxi/Makefile
scripts/Makefile
scripts/init_rtxi
scripts/rtxi_comedi
$MAKEFILES
])

dnl Generate config.status and launch it
AC_OUTPUT
EOF

aclocal -I m4
libtoolize --copy --force --automake
autoheader 
autoconf
automake  -a -c
