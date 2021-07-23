AC_DEFUN([AX_SYSREPO], [

  AC_ARG_WITH([libyang],
    AS_HELP_STRING([--with-libyang=PATH], [path to the libyang.pc file, to the libyang-cpp.pc file or to the libyang installation directory]),
    [with_library="${withval}"])

  AC_MSG_CHECKING([libyang])
  AX_FIND_LIBRARY([libyang], ["${with_library}"], [libyang/libyang.h], [libyang.so], [LIBYANG_SOVERSION])
  if "${LIBRARY_FOUND}"; then
    LIBYANG_CPPFLAGS="${LIBRARY_CPPFLAGS}"
    LIBYANG_INCLUDEDIR="${LIBRARY_INCLUDEDIR}"
    LIBYANG_LIBS="${LIBRARY_LIBS}"
    LIBYANG_VERSION="${LIBRARY_VERSION}"
    LIBYANG_PREFIX="${LIBRARY_PREFIX}"

    libyang_found=true
    AC_MSG_RESULT([yes])
  else
    libyang_found=false
    AC_MSG_RESULT([no])
  fi

  AC_MSG_CHECKING([libyang-cpp])
  AX_FIND_LIBRARY([libyang-cpp], ["${with_library}"], [libyang/Libyang.hpp], [libyang-cpp.so])
  if "${LIBRARY_FOUND}"; then

    # If include paths are equal, there's no need to include both. But if
    # they're different, we need both.
    if test "${LIBYANG_INCLUDEDIR}" != "${LIBYANGCPP_INCLUDEDIR}"; then
       LIBYANG_INCLUDEDIR="${LIBYANG_INCLUDEDIR} ${LIBYANGCPP_INCLUDEDIR}"
    fi

    if test "${LIBYANG_CPPFLAGS}" != "${LIBYANGCPP_CPPFLAGS}"; then
       LIBYANG_CPPFLAGS="${LIBYANG_CPPFLAGS} ${LIBYANGCPP_CPPFLAGS}"
    fi

    if test "${LIBYANG_LIBS}" != "${LIBYANGCPP_LIBS}"; then
       LIBYANG_LIBS="${LIBYANG_LIBS} ${LIBYANGCPP_LIBS}"
    fi

    LIBYANGCPP_CPPFLAGS="${LIBRARY_CPPFLAGS}"
    LIBYANGCPP_INCLUDEDIR="${LIBRARY_INCLUDEDIR}"
    LIBYANGCPP_LIBS="${LIBRARY_LIBS}"
    LIBYANGCPP_VERSION="${LIBRARY_VERSION}"
    LIBYANGCPP_PREFIX="${LIBRARY_PREFIX}"

    libyang_cpp_found=true
    AC_MSG_RESULT([yes])
  else
    libyang_cpp_found=false
    AC_MSG_RESULT([no])
  fi

  AC_ARG_WITH([sysrepo],
    AS_HELP_STRING([--with-sysrepo=PATH], [path to the sysrepo.pc file, to the sysrepo-cpp.pc file or to the sysrepo installation directory]),
    [with_library="${withval}"])

  AC_MSG_CHECKING([sysrepo])
  AX_FIND_LIBRARY([sysrepo], ["${with_library}"], [sysrepo.h], [libsysrepo.so], [], [])
  if "${LIBRARY_FOUND}"; then
    SYSREPO_CPPFLAGS="${LIBRARY_CPPFLAGS}"
    SYSREPO_INCLUDEDIR="${LIBRARY_INCLUDEDIR}"
    SYSREPO_LIBS="${LIBRARY_LIBS}"
    SYSREPO_VERSION="${LIBRARY_VERSION}"

    sysrepo_found=true
  else
    sysrepo_found=false
  fi

  if "${sysrepo_found}"; then
    AC_SUBST(SYSREPO_CPPFLAGS)
    AC_SUBST(SYSREPO_INCLUDEDIR)
    AC_SUBST(SYSREPO_LIBS)

    # Save flags.
    CPPFLAGS_SAVED="${CPPFLAGS}"
    LIBS_SAVED="${LIBS}"

    # Provide Sysrepo flags temporarily.
    CPPFLAGS="${CPPFLAGS} ${SYSREPO_INCLUDEDIR} ${SYSREPO_CPPFLAGS}"
    LIBS="${LIBS} ${SYSREPO_LIBS}"

    # Check that a simple program using Sysrepo C API can compile and link.
    AC_LINK_IFELSE(
      [AC_LANG_PROGRAM(
        [extern "C" {
           #include <sysrepo.h>
         }],
        [sr_conn_ctx_t *connection;
         sr_session_ctx_t *session;
         sr_disconnect(connection);])],
      [AC_MSG_RESULT([yes])],
      [AC_MSG_RESULT([no])
       AC_MSG_ERROR([Cannot integrate with Sysrepo's C API. Make sure that the sysrepo.h header and the libsysrepo.so library can be found.])]
    )

    # Restore flags.
    CPPFLAGS="${CPPFLAGS_SAVED}"
    LIBS="${LIBS_SAVED}"
  else
    AC_MSG_RESULT([no])
  fi

  AC_MSG_CHECKING([sysrepo-cpp])

  AX_FIND_LIBRARY([sysrepo-cpp], ["${with_library}"], [sysrepo-cpp/Session.hpp], [libsysrepo-cpp.so], [SR_REPO_PATH,SRPD_PLUGINS_PATH], [])
  if "${LIBRARY_FOUND}"; then
    SYSREPOCPP_CPPFLAGS="${LIBRARY_CPPFLAGS}"
    SYSREPOCPP_INCLUDEDIR="${LIBRARY_INCLUDEDIR}"
    SYSREPOCPP_LIBS="${LIBRARY_LIBS}"
    SYSREPOCPP_VERSION="${LIBRARY_VERSION}"

    sysrepo_cpp_found=true
  else
    sysrepo_cpp_found=false
  fi

  if "${sysrepo_cpp_found}"; then
    # If include paths are equal, there's no need to include both. But if
    # they're different, we need both.
    if test "${SYSREPO_INCLUDEDIR}" != "${SYSREPOCPP_INCLUDEDIR}"; then
       SYSREPO_INCLUDEDIR="${SYSREPO_INCLUDEDIR} ${SYSREPOCPP_INCLUDEDIR}"
    fi

    if test "${SYSREPO_CPPFLAGS}" != "${SYSREPOCPP_CPPFLAGS}"; then
       SYSREPO_CPPFLAGS="${SYSREPO_CPPFLAGS} ${SYSREPOCPP_CPPFLAGS}"
    fi

    if test "${SYSREPO_LIBS}" != "${SYSREPOCPP_LIBS}"; then
       SYSREPO_LIBS="${SYSREPO_LIBS} ${SYSREPOCPP_LIBS}"
    fi

    AC_SUBST(SYSREPO_INCLUDEDIR)
    AC_SUBST(SYSREPO_CPPFLAGS)
    AC_SUBST(SYSREPO_LIBS)

    # Save flags.
    CPPFLAGS_SAVED="${CPPFLAGS}"
    LIBS_SAVED="${LIBS}"

    # Provide Sysrepo flags temporarily.
    CPPFLAGS="${CPPFLAGS} ${SYSREPO_INCLUDEDIR} ${SYSREPO_CPPFLAGS}"
    LIBS="${LIBS} ${SYSREPO_LIBS}"

    # Check that a simple program using Sysrepo C++ bindings can compile and link.
    AC_LINK_IFELSE(
      [AC_LANG_PROGRAM(
        [#include <sysrepo-cpp/Session.hpp>],
        [])],
      [AC_LINK_IFELSE(
        [AC_LANG_PROGRAM(
          [#include <sysrepo-cpp/Session.hpp>],
          [sysrepo::Connection();]
        )],
        [AC_MSG_RESULT([v1.x])
         AC_DEFINE([HAVE_SYSREPO_V1], [true], [Using sysrepo 1.x])],
        [AC_LINK_IFELSE(
          [AC_LANG_PROGRAM(
            [#include <sysrepo-cpp/Session.hpp>],
            [sysrepo::S_Val value;
             value->empty();]
          )],
          [AC_MSG_RESULT([>= v0.7.7])
           AC_MSG_ERROR([Using legacy sysrepo >= 0.7.7 which is no longer supported. Upgrade to the latest version with C++ bindings: 1.4.140.])],
          [AC_LINK_IFELSE(
            [AC_LANG_PROGRAM(
              [#include <sysrepo-cpp/Session.h>],
              [Connection("conn-name");])],
            [AC_MSG_RESULT([<= v0.7.6])
             AC_MSG_ERROR([Using sysrepo <= 0.7.6 which is no longer supported. Upgrade to the latest version with C++ bindings: 1.4.140.])],
            [AC_MSG_RESULT([no])
             AC_MSG_ERROR([Found Sysrepo C++ bindings, but could not identify their version. If you think Kea should support this version of sysrepo, please contact ISC.)])]
          )]
        )]
      )],
      [AC_MSG_RESULT([no])
      AC_MSG_ERROR([Count not integrate with Sysrepo C++ bindings. Make sure that the sysrepo-cpp/Session.hpp header and the libsysrepo-cpp.so library can be found.])]
    )

    # Restore flags.
    CPPFLAGS="${CPPFLAGS_SAVED}"
    LIBS="${LIBS_SAVED}"
  else
    AC_MSG_RESULT([no])
  fi

  if "${libyang_found}" && "${libyang_cpp_found}" && "${sysrepo_found}" && "${sysrepo_cpp_found}"; then
    HAVE_SYSREPO=true
  else
    HAVE_SYSREPO=false
  fi
  AM_CONDITIONAL(HAVE_SYSREPO, "${HAVE_SYSREPO}")
  AC_SUBST(HAVE_SYSREPO)
  AC_SUBST(SYSREPO_CPPFLAGS)
  AC_SUBST(SYSREPO_INCLUDEDIR)
  AC_SUBST(SYSREPO_LIBS)
  AC_SUBST(SR_REPO_PATH)
  AC_SUBST(SRPD_PLUGINS_PATH)
  AC_SUBST(SYSREPO_VERSION)
  AC_SUBST(SYSREPOCPP_VERSION)
])
