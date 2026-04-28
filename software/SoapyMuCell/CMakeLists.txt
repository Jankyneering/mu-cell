########################################################################
# Project setup -- only needed if device support is a stand-alone build
# We recommend that the support module be built in-tree with the driver.
########################################################################
cmake_minimum_required(VERSION 3.3...3.10)
project(SoapyMuCell CXX)
enable_testing()

#select the release build type by default to get optimization flags
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Release")
   message(STATUS "Build type not specified: defaulting to release.")
endif(NOT CMAKE_BUILD_TYPE)
set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "")

########################################################################
# Header and library resources needed to communicate with the device.
# These may be found within the build tree or in an external project.
########################################################################
set(MY_DEVICE_INCLUDE_DIRS "")
set(MY_DEVICE_LIBRARIES "asound")

########################################################################
# OpenSSL (required for EEPROM signature verification)
########################################################################
find_package(OpenSSL REQUIRED)
if(NOT OPENSSL_FOUND)
    message(FATAL_ERROR "OpenSSL not found. Install libssl-dev (Debian/Ubuntu) or openssl-devel (Fedora/RHEL).")
endif()
message(STATUS "OpenSSL version: ${OPENSSL_VERSION}")

########################################################################
# Embed public keys from public_keys/ into generated_keys.hpp
#
# Drop any number of <name>.pem files into the public_keys/ directory.
# Each file becomes one entry in the EMBEDDED_KEYS[] array.
# The array is keyed by filename stem (without .pem extension) so you can
# differentiate batches in log output, e.g. "batch_2024_q1".
#
# The header is regenerated whenever any .pem file or the generator script
# changes, or when the git index changes (same trigger as version.cpp).
########################################################################
set(PUBLIC_KEYS_DIR   "${CMAKE_SOURCE_DIR}/public_keys")
set(GENERATED_KEYS_HPP "${CMAKE_BINARY_DIR}/generated_keys.hpp")
set(GENERATE_KEYS_SCRIPT "${CMAKE_SOURCE_DIR}/generate_keys.cmake")

# Collect all .pem files so CMake knows to re-run when they change
file(GLOB PUBLIC_KEY_FILES "${PUBLIC_KEYS_DIR}/*.pem")

if(NOT PUBLIC_KEY_FILES)
    message(WARNING
        "No .pem files found in ${PUBLIC_KEYS_DIR}. "
        "The driver will be built without any embedded public keys and will "
        "report AUTH=NO_KEYS_COMPILED_IN at runtime. "
        "Add public key PEM files to public_keys/ and rebuild.")
endif()

add_custom_command(
    OUTPUT  "${GENERATED_KEYS_HPP}"
    COMMAND ${CMAKE_COMMAND}
            -DKEYS_DIR="${PUBLIC_KEYS_DIR}"
            -DOUTPUT_FILE="${GENERATED_KEYS_HPP}"
            -P "${GENERATE_KEYS_SCRIPT}"
    DEPENDS ${PUBLIC_KEY_FILES} ${GENERATE_KEYS_SCRIPT}
    COMMENT "Generating embedded public keys header"
)

add_custom_target(generate_keys DEPENDS "${GENERATED_KEYS_HPP}")

########################################################################
# Source files
########################################################################
set(MY_SOURCE_FILES SoapyMuCell.cpp)

########################################################################
# Add version
########################################################################
set(VERSION_SOURCE_FILE version.cpp)
set(VERSION_SCRIPT "${CMAKE_SOURCE_DIR}/version.sh")

find_package(Git REQUIRED)

add_custom_command(
    OUTPUT ${VERSION_SOURCE_FILE}
    COMMAND "${VERSION_SCRIPT}" "${GIT_EXECUTABLE}" > "${VERSION_SOURCE_FILE}"
    DEPENDS ../.git/index ${VERSION_SCRIPT} ${MY_SOURCE_FILES}
)

########################################################################
# build the module
########################################################################
find_package(SoapySDR CONFIG)

if (NOT SoapySDR_FOUND)
    message(WARNING "SoapySDR development files not found - skipping support")
    return()
endif ()

include_directories(
    ${MY_DEVICE_INCLUDE_DIRS}
    ${OPENSSL_INCLUDE_DIR}
    ${CMAKE_BINARY_DIR}        # so #include "generated_keys.hpp" resolves
    ${CMAKE_SOURCE_DIR}        # so #include "eeprom_auth.hpp" resolves
)

SOAPY_SDR_MODULE_UTIL(
    TARGET MuCellSupport
    SOURCES ${MY_SOURCE_FILES} ${VERSION_SOURCE_FILE}
    LIBRARIES ${MY_DEVICE_LIBRARIES} ${OPENSSL_LIBRARIES}
)

# Ensure the header is generated before compiling SoapyMuCell.cpp
add_dependencies(MuCellSupport generate_keys)

########################################################################
# Other files to install
########################################################################

option(INSTALL_PIPEWIRE_CONF "Install PipeWire configuration to prevent it from trying to use SX1255 as a normal sound card" ON)
if (INSTALL_PIPEWIRE_CONF)
install(FILES 60-pipewire-do-not-use-i2s.lua DESTINATION /usr/share/wireplumber/main.lua.d/)
endif (INSTALL_PIPEWIRE_CONF)
