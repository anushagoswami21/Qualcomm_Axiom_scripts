import logging
import time
from axiom_framework.tests.base import Test as Base
from axiom_framework.results.base import TestResults
import time

logger = logging.getLogger(__name__)
import glob
import subprocess
import sys
import os
"""
Test Case Result Options

class TestResults(enum.IntEnum):
    undefined = 0,
    passed = 1,
    failed = 2,
    scheduled = 3,
    in_progress = 4,
    unsupported = 5,
    aborted = 6,
    not_run = 7,
    error = 8,
    manual_pending = 9,
    blocked = 10,
    analysis_pending = 11,
    analysis_error = 12
"""


class Test(Base):
    """
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        logger.info('Playlist Name = {}'.format(self.playlist_name))

        # Parameters to the script
        logger.info('Script params = {}'.format(self.args))

        # Log folder where logs are generated
        logger.info('Log Folder = {}'.format(self.log_folder))

        # Test Case Name\Sequence\Attempt
        logger.info('Test Case Name = {}'.format(self.case_name))
        logger.info('Test Case Sequence = {}'.format(self.sequence))
        logger.info('Test Case Attempt = {}'.format(self.attempt))

        # Thrift connection object
        logger.info('Thrift Connection object = {}'.format(self.connection))

    def setup(self):
      logger.info("entering in to customized setup function")
       

    def execute(self):
        result = TestResults.passed
        logger.info('Test Case Attempt = {}'.format(result))
        self.result.set_result(result)

    def cleanup(self):
        # Please reset the device after a test case that boots into UEFI
        logger.info("Reset the device")
        self.connection.reset_device()
         
    def all_clients(self):
        logger.info("Inside all_clients")
        os.system("adb wait-for-device devices")
        time.sleep(1)
        os.system("adb root")
        time.sleep(1)
        cmd1=subprocess.Popen('adb disable-verity')
        cmd2=subprocess.Popen('adb reboot')
        cmd2.wait()
        os.system("adb wait-for-device devices")
        os.system("adb root")
        os.system("adb remount")
        os.system("adb shell mount -o rw,remount /")
        os.system("adb shell mount -o rw,remount /firmware")
        os.system("adb shell mount -o rw,remount /")
        os.system("adb shell chmod 777 /usr/bin/qsee*")
        os.system("adb shell chmod 777 /firmware/image/*")
        logger.info('Entered in image push block')
        #os.system("adb push \\\\aptcorebsp-24\\Dropbox\\IOT_APT\\apttest_client /usr/bin/")
        # tzRoot = '\\\\crmhyd\\nsid-hyd-05\\TZ.XF.5.1.2-00001-Q405AAAAANAZT-1' 
        # binLoc = '\\trustzone_images\\build\\ms\\bin\\PIL_IMAGES\\SPLITBINS_OAPAANAA\\' 
        # device_dest = '/firmware/image/'
        tzRoot=self.args['tzroot']
        binLoc=self.args['tzpath']
        adb_push("\\\\aptcorebsp-24\\Dropbox\\IOT_APT\\apttest_client","/usr/bin/")
        path=tzRoot+binLoc
        print(path)
        os.chdir(path)
        dir=os.getcwd()
        for file in glob.glob("apt*"):
            x=path+file
            adb_push(x,"/firmware/image")
            # os.system("adb push "+x+" /firmware/image")
        os.system("adb shell chmod 777 /firmware/image/*")
        os.system("adb shell chmod 777 /usr/bin/apt*")
		    
        

if __name__ == '__main__':
    test = Test()
    test.run()
    test.all_clients()
