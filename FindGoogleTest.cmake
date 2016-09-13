#.rst:
# FindGoogleTest
# ---------
#
# Locate the Google C++ Testing Framework.
#
# Imported targets
# ^^^^^^^^^^^^^^^^
#
# This module defines the following :prop_tgt:`IMPORTED` targets:
#
# ``GoogleTest::GTest``
#   The Google Test ``gtest`` library, if found; adds Thread::Thread
#   automatically
# ``GoogleTest::Main``
#   The Google Test ``gtest_main`` library, if found
#
#
# Result variables
# ^^^^^^^^^^^^^^^^
#
# This module will set the following variables in your project:
#
# ``GTEST_FOUND``
#   Found the Google Testing framework
# ``GTEST_INCLUDE_DIRS``
#   the directory containing the Google Test headers
#
# The library variables below are set as normal variables.  These
# contain debug/optimized keywords when a debugging library is found.
#
# ``GTEST_LIBRARIES``
#   The Google Test ``gtest`` library; note it also requires linking
#   with an appropriate thread library
# ``GTEST_MAIN_LIBRARIES``
#   The Google Test ``gtest_main`` library
# ``GTEST_BOTH_LIBRARIES``
#   Both ``gtest`` and ``gtest_main``
#
# Cache variables
# ^^^^^^^^^^^^^^^
#
# The following cache variables may also be set:
#
# ``GTEST_ROOT``
#   The root directory of the Google Test installation (may also be
#   set as an environment variable)
# ``GTEST_MSVC_SEARCH``
#   If compiling with MSVC, this variable can be set to ``MD`` or
#   ``MT`` (the default) to enable searching a GTest build tree
#
#
# Example usage
# ^^^^^^^^^^^^^
#
# ::
#
#     enable_testing()
#     find_package(GoogleTest REQUIRED)
#
#     add_executable(foo foo.cc)
#     target_link_libraries(foo GoogleTest::GTest GoogleTest::GTestMain)
#
#     add_test(AllTestsInFoo foo)
#
#
# Deeper integration with CTest
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#
# If you would like each Google test to show up in CTest as a test you
# may use the following macro::
#
#     GTEST_ADD_TESTS(executable extra_args files...)
#
# ``executable``
#   the path to the test executable
# ``extra_args``
#   a list of extra arguments to be passed to executable enclosed in
#   quotes (or ``""`` for none)
# ``files...``
#   a list of source files to search for tests and test fixtures.  Or
#   ``AUTO`` to find them from executable target
#
# However, note that this macro will slow down your tests by running
# an executable for each test and test fixture.  You will also have to
# re-run CMake after adding or removing tests or test fixtures.
#
# Example usage::
#
#      set(FooTestArgs --foo 1 --bar 2)
#      add_executable(FooTest FooUnitTest.cc)
#      GTEST_ADD_TESTS(FooTest "${FooTestArgs}" AUTO)
# Thanks to Daniel Blezek <blezek@gmail.com> for the GTEST_ADD_TESTS code

function(GTEST_ADD_TESTS executable extra_args)
    if(NOT ARGN)
        message(FATAL_ERROR "Missing ARGN: Read the documentation for GTEST_ADD_TESTS")
    endif()
    if(ARGN STREQUAL "AUTO")
        # obtain sources used for building that executable
        get_property(ARGN TARGET ${executable} PROPERTY SOURCES)
    endif()
    set(gtest_case_name_regex ".*\\( *([A-Za-z_0-9]+) *, *([A-Za-z_0-9]+) *\\).*")
    set(gtest_test_type_regex "(TYPED_TEST|TEST_?[FP]?)")
    foreach(source ${ARGN})
        file(READ "${source}" contents)
        string(REGEX MATCHALL "${gtest_test_type_regex} *\\(([A-Za-z_0-9 ,]+)\\)" found_tests ${contents})
        foreach(hit ${found_tests})
          string(REGEX MATCH "${gtest_test_type_regex}" test_type ${hit})

          # Parameterized tests have a different signature for the filter
          if("x${test_type}" STREQUAL "xTEST_P")
            string(REGEX REPLACE ${gtest_case_name_regex}  "*/\\1.\\2/*" test_name ${hit})
          elseif("x${test_type}" STREQUAL "xTEST_F" OR "x${test_type}" STREQUAL "xTEST")
            string(REGEX REPLACE ${gtest_case_name_regex} "\\1.\\2" test_name ${hit})
          elseif("x${test_type}" STREQUAL "xTYPED_TEST")
            string(REGEX REPLACE ${gtest_case_name_regex} "\\1/*.\\2" test_name ${hit})
          else()
            message(WARNING "Could not parse GoogleTest ${hit} for adding to CTest.")
            continue()
          endif()
          add_test(NAME ${test_name} COMMAND ${executable} --gtest_filter=${test_name} ${extra_args})
        endforeach()
    endforeach()
endfunction()

set(GOOGLETEST_ROOT ${CONAN_GOOGLETEST_ROOT})
set(GOOGLETEST_INCLUDE_DIR ${CONAN_INCLUDE_DIRS_GOOGLETEST})
set(GOOGLETEST_LIBRARY_DIR ${CONAN_LIB_DIRS_GOOGLETEST})
set(GOOGLETEST_SHAREDLIB_DIR ${CONAN_BIN_DIRS_GOOGLETEST})

if(GOOGLETEST_INCLUDE_DIRS AND GOOGLETEST_LIBRARY_DIR)
    set(GOOGLETEST_FOUND true)
endif()

if(GOOGLETEST_FOUND)
    set(GOOGLETEST_INCLUDE_DIRS ${GOOGLETEST_INCLUDE_DIR})
    
    set(GTEST_BOTH_LIBRARIES ${GTEST_LIBRARIES} ${GTEST_MAIN_LIBRARIES})

    include(CMakeFindDependencyMacro)
    find_dependency(Threads)
    
    set (LIBRARY_TYPE "STATIC")
    if(BUILD_SHARED_LIBS)
        set (LIBRARY_TYPE "SHARED")
    endif()

    if(NOT TARGET GoogleTest::GTest)
        add_library(GoogleTest::GTest ${LIBRARY_TYPE} IMPORTED)
        
        set_target_properties(GoogleTest::GTest PROPERTIES
            INTERFACE_LINK_LIBRARIES "Threads::Threads"
            INTERFACE_INCLUDE_DIRECTORIES "${GOOGLETEST_INCLUDE_DIRS}")
        
        if(EXISTS "${GOOGLETEST_LIBRARY_DIR}/gtest.lib")
           set_target_properties(GoogleTest::GTest PROPERTIES
               IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
               IMPORTED_IMPLIB "${GOOGLETEST_LIBRARY_DIR}/gtest.lib")
        endif()
        
        if(EXISTS "${GOOGLETEST_SHAREDLIB_DIR}/gtest.dll")
           set_target_properties(GoogleTest::GTest PROPERTIES
               IMPORTED_LOCATION "${GOOGLETEST_SHAREDLIB_DIR}/gtest.dll")
        endif()
    endif()   
    
    if(NOT TARGET GoogleTest::GTestMain)
        add_library(GoogleTest::GTestMain ${LIBRARY_TYPE} IMPORTED)
        
        set_target_properties(GoogleTest::GTestMain PROPERTIES
            INTERFACE_LINK_LIBRARIES "GoogleTest::GTest")
        
        if(EXISTS "${GOOGLETEST_LIBRARY_DIR}/gtest_main.lib")
           set_target_properties(GoogleTest::GTestMain PROPERTIES
               IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
               IMPORTED_IMPLIB "${GOOGLETEST_LIBRARY_DIR}/gtest_main.lib")
        endif()
        
        if(EXISTS "${GOOGLETEST_SHAREDLIB_DIR}/gtest_main.dll")
            set_target_properties(GoogleTest::GTestMain PROPERTIES
                IMPORTED_LOCATION "${GOOGLETEST_SHAREDLIB_DIR}/gtest_main.dll")
        endif()
    endif()
    
    if(NOT TARGET GoogleTest::GMock)
        add_library(GoogleTest::GMock ${LIBRARY_TYPE} IMPORTED)
    
        set_target_properties(GoogleTest::GMock PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${GOOGLETEST_INCLUDE_DIRS}")
    
        if(EXISTS "${GOOGLETEST_LIBRARY_DIR}/gmock.lib")
            set_target_properties(GoogleTest::GMock PROPERTIES
                IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
                IMPORTED_IMPLIB "${GOOGLETEST_LIBRARY_DIR}/gmock.lib"
                INTERFACE_COMPILE_DEFINITIONS "GTEST_LINKED_AS_SHARED_LIBRARY")
        endif()
    
        if(EXISTS "${GOOGLETEST_SHAREDLIB_DIR}/gmock.dll")
           set_target_properties(GoogleTest::GMock PROPERTIES
               IMPORTED_LOCATION "${GOOGLETEST_SHAREDLIB_DIR}/gmock.dll")
        endif()
    endif()
    if(NOT TARGET GoogleTest::GMockMain)
        add_library(GoogleTest::GMockMain ${LIBRARY_TYPE} IMPORTED)
    
        set_target_properties(GoogleTest::GMockMain PROPERTIES
            INTERFACE_LINK_LIBRARIES "GoogleTest::GMock")
    
        if(EXISTS "${GOOGLETEST_LIBRARY_DIR}/gmock_main.lib")
            set_target_properties(GoogleTest::GMockMain PROPERTIES
                IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
                IMPORTED_IMPLIB "${GOOGLETEST_LIBRARY_DIR}/gmock_main.lib")
        endif()
    
        if(EXISTS "${GOOGLETEST_SHAREDLIB_DIR}/gmock_main.dll")
            set_target_properties(GoogleTest::GMockMain PROPERTIES
                IMPORTED_LOCATION "${GOOGLETEST_SHAREDLIB_DIR}/gmock_main.dll")
        endif()
    endif()
endif()
