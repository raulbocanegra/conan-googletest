from conans import ConanFile
import os
from conans.tools import download
from conans.tools import unzip
from conans import CMake



class GoogleTestConan(ConanFile):
    name = "googletest"
    version = "1.8.0"
    ZIP_FOLDER_NAME = "googletest-release-%s" % version
    generators = "cmake"
    settings = "os", "arch", "compiler", "build_type"
    options = {"shared": [True, False],
               "build_gtest": [True, False],
               "build_gmock": [True, False]}
    default_options = ("shared=True", "build_gtest=False", "build_gmock=True")
    #exports = "CMakeLists.txt"
    #url="http://github.com/rboc/conan-googletest"
    license="https://github.com/google/googletest/blob/master/googletest/LICENSE"
    
    def source(self):
        zip_name = "release-%s.zip" % self.version
        url = "https://github.com/google/googletest/archive/%s" % zip_name
        download(url, zip_name)
        unzip(zip_name)
        os.unlink(zip_name)

    def build(self):        
        cmake = CMake(self.settings)
        if self.settings.os == "Windows":
            self.run("IF not exist _build mkdir _build")
        else:
            self.run("mkdir _build")
        cd_build = "cd _build"
        force = "-Dgtest_force_shared_crt=ON"
        build_gtest = "-DBUILD_GTEST=ON" if self.options.build_gtest else ""
        build_gmock = "-DBUILD_GMOCK=ON" if self.options.build_gmock else ""
        shared = "-DBUILD_SHARED_LIBS=1" if self.options.shared else ""
        options = "%s %s %s %s" % (shared, force, build_gtest, build_gmock)
        
        self.run('%s && cmake ../%s %s %s' % (cd_build, self.ZIP_FOLDER_NAME, cmake.command_line, options))
        self.run("%s && cmake --build . %s" % (cd_build, cmake.build_config))

    def package(self):
        # Copying headers
        self.copy(pattern="*.h", dst="include", src="%s/googletest/include" % self.ZIP_FOLDER_NAME, keep_path=True)
        if (self.options.build_gmock):
            self.copy(pattern="*.h", dst="include", src="%s/googlemock/include" % self.ZIP_FOLDER_NAME, keep_path=True)
        # Copying static and dynamic libs
        self.copy(pattern="*.a", dst="lib", src=".", keep_path=False)
        self.copy(pattern="*.lib", dst="lib", src=".", keep_path=False)
        self.copy(pattern="*.dll", dst="bin", src=".", keep_path=False)
        self.copy(pattern="*.so*", dst="lib", src=".", keep_path=False)
        self.copy(pattern="*.dylib*", dst="lib", src=".", keep_path=False)      

    def package_info(self):
        self.cpp_info.libs = ['gtest', 'gtest_main']
        if (self.options.build_gmock):
            self.cpp_info.libs.append("gmock")
        if self.settings.os == "Linux":
            self.cpp_info.libs.append("pthread")
        
        if self.options.shared:
            self.cpp_info.defines.append("GTEST_LINKED_AS_SHARED_LIBRARY=1")