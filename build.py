from conan.packager import ConanMultiPackager
import os, sys, re, subprocess, argparse

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

def build(args):
   reference = extractReference()
   package_name = reference.split("/")[0] 
   version = reference.split("/")[1]
   package = os.getenv("CONAN_PACKAGE", package_name)
   os.environ["GOOGLETEST_VERSION"] = version   
    
   if args.local:
      # This is only for local package testing, not Jenkins this environment vars are allready set on Jenkins
      os.environ["CONAN_USERNAME"] = args.user
      os.environ["CONAN_CHANNEL"] = args.channel

   build_args = " "
   builder = ConanMultiPackager(reference=reference, args=build_args)    
   builder.add({"arch": "x86", "build_type": "Release", "compiler": "Visual Studio", "compiler.runtime":"MD" } )
   builder.add({"arch": "x86", "build_type": "Debug"  , "compiler": "Visual Studio", "compiler.runtime":"MDd"} )
   builder.add({"arch": "x86_64", "build_type": "Release", "compiler": "Visual Studio", "compiler.runtime":"MD" } )
   builder.add({"arch": "x86_64", "build_type": "Debug"  , "compiler": "Visual Studio", "compiler.runtime":"MDd"} )
   builder.run()

if __name__ == "__main__":
   parser = argparse.ArgumentParser(description="This script build the corresponding package.",
                                    prog="build.py",
                                    formatter_class=argparse.RawTextHelpFormatter)
   parser.add_argument("-l,", "--local", action='store_true', help='run local build')
   parser.add_argument("-u", "--user", default="rndev", help='choose the user, \"cdev\" by default')
   parser.add_argument("-c", "--channel", default="testing", help='choose the channel, \"testing\" by default')
   #parser.add_argument("-x86", "--build_x86", action='store_true', help='build x86 binaries')
   #parser.add_argument("-t", "--build_test", action='store_true', help='build tests')

   args = parser.parse_args(args=sys.argv[1:])

   build(args);