macro(add_keyboard KEYBOARD_FOLDER)  
  # not entirely sure why this is necessary
  set(TEMP_PATH ${KEYBOARD_FOLDER})
  cmake_path(IS_RELATIVE TEMP_PATH IS_FOLDER_RELATIVE)
  if(${IS_FOLDER_RELATIVE})
    set(KEYBOARD_FOLDER_ABS ${CMAKE_SOURCE_DIR}/keyboards/${KEYBOARD_FOLDER})
    if(NOT EXISTS ${KEYBOARD_FOLDER_ABS})
      message(FATAL_ERROR "Keyboard does not exist in QMK - try using an absolute path to the keyboard folder")
    endif()
  else()
    set(KEYBOARD_FOLDER_ABS ${KEYBOARD_FOLDER})
    if(NOT EXISTS ${KEYBOARD_FOLDER_ABS})
      message(FATAL_ERROR "Absolute path to keyboard does not exist")
    endif()
  endif()

  # find the right toolchain
  message(STATUS "Reading config from ${KEYBOARD_FOLDER_ABS}/info.json")
  file(READ ${KEYBOARD_FOLDER_ABS}/info.json JSON_STRING)
  string(JSON PROCESSOR GET ${JSON_STRING} processor)
  if(${PROCESSOR} MATCHES "^at.*")
    set(PLATFORM "avr")
    include(FindAVRToolchain)
    find_avr_toolchain()
  elseif(
    ${PROCESSOR} MATCHES "^STM.*" OR
    ${PROCESSOR} MATCHES "^WB32.*" OR
    ${PROCESSOR} MATCHES "^MK.*" OR
    ${PROCESSOR} MATCHES "RP2040" OR
    ${PROCESSOR} MATCHES "^GD32.*")
    set(PLATFORM "chibios")
    include(FindARMToolchain)
    find_arm_toolchain()
  endif()
  if(NOT DEFINED PLATFORM)
    message(FATAL_ERROR "Could not find platform for ${KEYBOARD_FOLDER}")
  endif()

  if(${IS_FOLDER_RELATIVE})
    string(REPLACE "/" "_" KEYBOARD_NAME ${KEYBOARD_FOLDER})
  else()
    string(JSON KEYBOARD_NAME GET ${JSON_STRING} keyboard_name)
    string(REPLACE " " "_" KEYBOARD_NAME ${KEYBOARD_NAME})
  endif()

  ExternalProject_Add(${KEYBOARD_NAME}
    SOURCE_DIR ${CMAKE_SOURCE_DIR}
    PREFIX ${CMAKE_SOURCE_DIR}/build/keyboards/${KEYBOARD_FOLDER}
    TMP_DIR ${CMAKE_SOURCE_DIR}/build/keyboards/${KEYBOARD_FOLDER}/tmp
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/build/keyboards/${KEYBOARD_FOLDER}/Download
    BINARY_DIR ${CMAKE_SOURCE_DIR}/build/keyboards/${KEYBOARD_FOLDER}/Build
    STAMP_DIR ${CMAKE_SOURCE_DIR}/build/keyboards/${KEYBOARD_FOLDER}/Stamp
    LOG_DIR ${CMAKE_SOURCE_DIR}/build/keyboards/${KEYBOARD_FOLDER}/Log
    INSTALL_DIR ${CMAKE_SOURCE_DIR}/build/keyboards/${KEYBOARD_FOLDER}/Install
    INSTALL_COMMAND cmake -E echo "No install needed"
    # this seems to work well for all systems so far - not sure if it'd be useful to customize
    CMAKE_GENERATOR "Unix Makefiles"
    CMAKE_ARGS 
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/platforms/${PLATFORM}/toolchain.cmake
      -DTOOLCHAIN_ROOT=${TOOLCHAIN_ROOT}
      -DMAKE_ROOT=${MAKE_ROOT}
      -DQMK_KEYBOARD=${KEYBOARD_NAME}
      -DQMK_KEYBOARD_FOLDER=${KEYBOARD_FOLDER}
  )
endmacro(add_keyboard)