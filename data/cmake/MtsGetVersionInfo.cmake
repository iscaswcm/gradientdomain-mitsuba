# ============================================================================
#   HDRITools - High Dynamic Range Image Tools
#   Copyright 2008-2011 Program of Computer Graphics, Cornell University
#
#   Distributed under the OSI-approved MIT License (the "License");
#   see accompanying file LICENSE for details.
#
#   This software is distributed WITHOUT ANY WARRANTY; without even the
#   implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the License for more information.
#  ---------------------------------------------------------------------------
#  Primary author:
#      Edgar Velazquez-Armendariz <cs#cornell#edu - eva5>
# ============================================================================

# - Sets up the version info variables
# This module provides a function intended to be called ONLY from the root dir:
#  MTS_GET_VERSION_INFO()
#  MTS_VERSION       - Full version string: <major>.<minor>.<patch>
#  MTS_VERSION_MAJOR
#  MTS_VERSION_MINOR
#  MTS_VERSION_PATCH
#  MTS_VERSION_BUILD - Simple build number based on MTS_DATE,
#                      encoded as YYYYMMDD
#  MTS_HAS_VALID_REV - Flag to indicate whether MTS_REV_ID is set
#  MTS_REV_ID        - First 12 digits of the mercurial revision ID
#  MTS_DATE          - Represents the code date as YYYY.MM.DD
#  MTS_MACLS_VERSION - A version for Mac Launch Services from the version and
#                      code date, in the format nnnnn.nn.nn[hgXXXXXXXXXXXX]

function(MTS_GET_VERSION_INFO)

  # Simple, internal macro for zero padding values. Assumes that the number of
  # digits is enough. Note that this method overwrites the variable!
  macro(ZERO_PAD NUMBER_VAR NUM_DIGITS)
    set(_val ${${NUMBER_VAR}})
    set(${NUMBER_VAR} "")
    foreach(dummy_var RANGE 1 ${NUM_DIGITS})
      math(EXPR _digit "${_val} % 10")
      set(${NUMBER_VAR} "${_digit}${${NUMBER_VAR}}")
      math(EXPR _val "${_val} / 10")
    endforeach()
    unset(_val)
    unset(_digit)
  endmacro()

  if (NOT MTS_DATE)
    # The Windows "date" command output depends on the regional settings
    if (WIN32)
      set(GETDATE_CMD "${PROJECT_SOURCE_DIR}/data/windows/getdate.exe")
      set(GETDATE_ARGS "")
    else()
      set(GETDATE_CMD "date")
      set(GETDATE_ARGS "+'%Y.%m.%d'")    
    endif()
    execute_process(COMMAND "${GETDATE_CMD}" ${GETDATE_ARGS}
      OUTPUT_VARIABLE MTS_DATE
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (NOT MTS_DATE)
      message(FATAL_ERROR "Unable to get a build date!")
    endif()
    set(MTS_DATE ${MTS_DATE} PARENT_SCOPE)
  endif()

  set (MTS_HAS_VALID_REV 1)
  set(MTS_HAS_VALID_REV ${MTS_HAS_VALID_REV} PARENT_SCOPE)


  # Read version (MTS_VERSION) from include/mitsuba/core/version.h
  file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/include/mitsuba/core/version.h" MITSUBA_H REGEX "^#define MTS_VERSION \"[^\"]*\"$")
  if (MITSUBA_H MATCHES "^.*MTS_VERSION \"([0-9]+)\\.([0-9]+)\\.([0-9]+).*$")
    set(MTS_VERSION_MAJOR ${CMAKE_MATCH_1})
    set(MTS_VERSION_MINOR ${CMAKE_MATCH_2})
    set(MTS_VERSION_PATCH ${CMAKE_MATCH_3})
    set(MTS_VERSION "${MTS_VERSION_MAJOR}.${MTS_VERSION_MINOR}.${MTS_VERSION_PATCH}" PARENT_SCOPE)
    set(MTS_VERSION_MAJOR ${MTS_VERSION_MAJOR} PARENT_SCOPE)
    set(MTS_VERSION_MINOR ${MTS_VERSION_MINOR} PARENT_SCOPE)
    set(MTS_VERSION_PATCH ${MTS_VERSION_PATCH} PARENT_SCOPE)
  else()
    message(FATAL_ERROR "The mitsuba version could not be determined!")
  endif()

  # Make a super simple build number from the date
  if (MTS_DATE MATCHES "([0-9]+)\\.([0-9]+)\\.([0-9]+)")
    set(MTS_VERSION_BUILD
      "${CMAKE_MATCH_1}${CMAKE_MATCH_2}${CMAKE_MATCH_3}" PARENT_SCOPE)

    # Now make a Mac Launch Services version number based on version and date.
    # Based on specs from:
    # http://lists.apple.com/archives/carbon-dev/2006/Jun/msg00139.html (Feb 2011)
    if (MTS_VERSION_MAJOR GREATER 30 OR
        MTS_VERSION_MINOR GREATER 14 OR
        MTS_VERSION_PATCH GREATER 14 OR
        ${CMAKE_MATCH_1} GREATER 2032)
      message(AUTHOR_WARNING "Mitsuba version violates the Mac LS assumptions")
    endif()
    math(EXPR _MACLS_MAJOR "(${MTS_VERSION_MAJOR}+1)*256 + (${MTS_VERSION_MINOR}+1)*16 + ${MTS_VERSION_PATCH}+1")
    math(EXPR _MACLS_MINOR "((${CMAKE_MATCH_1}-2008)*4) + ((${CMAKE_MATCH_2}-1)*32 + ${CMAKE_MATCH_3})/100")
    math(EXPR _MACLS_BUILD "((${CMAKE_MATCH_2}-1)*32 + ${CMAKE_MATCH_3})%100")
    ZERO_PAD(_MACLS_MAJOR 4)
    ZERO_PAD(_MACLS_MINOR 2)
    ZERO_PAD(_MACLS_BUILD 2)
    set(MTS_MACLS_VERSION "${_MACLS_MAJOR}.${_MACLS_MINOR}.${_MACLS_BUILD}")
    if(MTS_HAS_VALID_REV)
      set(MTS_MACLS_VERSION "${MTS_MACLS_VERSION}${MTS_REV_ID}")
    endif()
    set(MTS_MACLS_VERSION ${MTS_MACLS_VERSION} PARENT_SCOPE)
  else()
    message(FATAL_ERROR
      "Mitsuba date has an unexpected format: ${MTS_DATE}")
  endif()

endfunction()
