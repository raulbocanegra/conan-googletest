from conan.packager import ConanMultiPackager
import os, re, subprocess

############### CONFIGURE THESE VALUES ##################
default_user = "demo"
default_channel = "testing"
#########################################################

def extractReference():
   ref_pattern= r"(.+)@{1}PROJECT"
   ref_regex = re.compile(ref_pattern)
   conan_info_output = subprocess.check_output("conan info")   
   for line in conan_info_output.split("\n"):      
      result_match = re.match(ref_regex, line)
      if result_match:
         reference = result_match.group(1)         
         return reference
         break

if __name__ == "__main__":

    # This is only for local package testing, not Jenkins
    username = os.getenv("CONAN_USERNAME", default_user)
    channel = os.getenv("CONAN_CHANNEL", default_channel)

    reference = extractReference()
    package_name = reference.split("/")[0] 
    version = reference.split("/")[1]
    package = os.getenv("CONAN_PACKAGE", package_name)
    os.environ["GOOGLETEST_VERSION"] = version   
    
    builder = ConanMultiPackager(reference=reference, username=username, channel=channel)    
    builder.add({"arch": "x86_64", "build_type": "Release", "compiler": "Visual Studio", "compiler.runtime":"MD" } )
    builder.add({"arch": "x86_64", "build_type": "Debug"  , "compiler": "Visual Studio", "compiler.runtime":"MDd"} )
    builder.run()