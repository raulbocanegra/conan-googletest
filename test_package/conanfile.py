from conans.model.conan_file import ConanFile
from conans import CMake
import os

############### CONFIGURE THESE VALUES ##################
default_user = "demo"
default_channel = "testing"
#########################################################

# This easily allows to copy the package in other user or channel
username = os.getenv("CONAN_USERNAME", default_user)
channel = os.getenv("CONAN_CHANNEL", default_channel)
version = os.getenv("GOOGLETEST_VERSION","1.8.0")

class TestPackageConan(ConanFile):
    name = "test_package_googletest"
    settings = "os", "compiler", "arch", "build_type"
    requires = "googletest/%s@%s/%s" % (version, username, channel)
    generators = "cmake"    
            
    def build(self):
        cmake = CMake(self.settings)
        self.run('cmake %s %s' % (self.conanfile_directory, cmake.command_line))
        self.run("cmake --build . %s" % cmake.build_config)

    def imports(self):
        self.copy(pattern="*.dll", dst="bin", src="bin")
        self.copy(pattern="*.dylib", dst="bin", src="lib")
        
    def test(self):
        self.run(os.sep.join([".","bin", self.name]))         