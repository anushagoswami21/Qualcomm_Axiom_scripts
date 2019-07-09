#==============================================================================
#
#           Safe File system SFS (APT Test Client) test script
# DESCRIPTION:
#  Automates SFS API test cases for Trustzone.
#
# Copyright 2016 by QUALCOMM Technologies, Incorporated.  All Rights Reserved.
#==============================================================================

#!/usr/bin/perl
use strict;
use warnings;
no  warnings qw(once);

use Data::Dumper;
# Import PerlShell module
use PerlShell;

# Create an instance for PerlShell
my $perl_shell = new PerlShell();

#==============================================================================
   # Use APT Modules  [ RESOURCES ]
#==============================================================================
use APT;
use Logging;
use XMLTestCaseManager;

#==============================================================================
   # Use Perl Modules 
#==============================================================================
use Getopt::Long;
use Time::HiRes qw(time);
use IPC::Open2;
use utf8; 
require 'unicore/Heavy.pl'; 
use overloading; 

#===========================================================================
#  Global Script Variables
#===========================================================================
my $useFolder;
my $Cmd = "0";
my $tzRoot;
my $loadBinaries = 0;
my $aptClientName= "apttestapp";
my $skipsetup = 0; 
my $ATE_RESULTS_LOCATION;
my $ATE_LOCALSTORAGE = ".\\";
my $test_plan_name;
my $help = 0;
my $qcase_test_area;
my $testName = "";
my $STDOUT_logName = "TestOutput.txt";
my $QSEE_logName = "QSEE_Log.log";
my $testStartTime = time;
my $logSTDoutput = 0;
my $createSFSDir;
my $runSecondTime = 0;
my $res_failure = "failed";
my $res_success = "passed";
my $metrics = 1;
my $device_dest  = "/vendor/firmware_mnt/image/";
my $tzRoot = 'tz';

my $binLoc = "";
my $bintest = "trustzone_images/ssg/securemsm/trustzone/qsapps/bintestapp/compiledBinaries/mbnv6/";   

#===========================================================================
#  Command Line Variable assignment in Perl.
#          'var'              => \$var,
#          'Cmd=s'            => \$string,
#===========================================================================
#Example information needed by test script to use for test execution.
print("\n\n\n\n ######     STARTING AXIOM JOB    ####");
print("Serial No :".$perl_shell->{serial_no}."\n");
print("Script Params : ".Dumper($perl_shell->{script_params})."\n");
print("Log Dir : ".$perl_shell->{log_dir}."\n");
print("Software Product :".$perl_shell->{software_product}."\n");

$useFolder = $perl_shell->{script_params}{'useFolder'};
$testName = $perl_shell->{script_params}{'testName'};
$logSTDoutput = $perl_shell->{script_params}{'logSTDoutput'};
$Cmd = $perl_shell->{script_params}{'Cmd'};
$scmd = $perl_shell->{script_params}{'scmd'};
$aptClientName = $perl_shell->{script_params}{'aptClientName'};
$binLoc = $perl_shell->{script_params}{'tzpath'};

# GetOptions( 'skipsetup'         => \$skipsetup,  
            # 'ATE_RESULTS=s'      => \$ATE_RESULTS_LOCATION,
            # 'ATE_LOCALSTORAGE=s' => \$ATE_LOCALSTORAGE,
            # 'useFolder'          => \$useFolder,
            # 'Cmd=s'              => \$Cmd,
            # 'tzRoot=s'           => \$tzRoot,
            # 'LoadBinaries'       => \$loadBinaries,
            # 'help'               => \$help,
            # 'aptClientName=s'    => \$aptClientName,
            # 'stdout-logname=s'   => \$STDOUT_logName,
            # 'qsee_logname=s'     => \$QSEE_logName,
            # 'testName=s'         => \$testName,
            # 'logSTDoutput'       => \$logSTDoutput,
            # 'createSFSDir'       => \$createSFSDir,
          # ) or ExitTest("Error processing arguments.");

#===========================================================================
#   Required variables - Check if they've been defined.
#   Example:
#     if (not defined($var)){
#        printHelp();
#        ExitTest("Var was not defined.");
#     }
#===========================================================================
if (!defined($Cmd)) {
   printHelp();
   ExitTest("cmd variable not specified.");
}

if ($loadBinaries and not defined($tzRoot)) {
   printHelp();
   ExitTest("TZ Root not defined.  Define with --tzRoot flag");
}
#===========================================================================
#   Help Section - This should print out all possible variables
#   and what they do.
#===========================================================================

sub printHelp {
   print "
Arguments          type  description
--skip-setup        f   Skips the defined \"setup\" section.
--ATE_LOCALSTORAGE  s   Value of #-LOCALSTORAGE#
--help              f   prints this list.
--useFolder         f   If flagged, store logs in a timestamped folder
--loadBinaries      f   Indicates binaries should be loaded (Default: no)
                        Requires that --tzRoot be specified.
--tzRoot            s   Location to load binaries from.
--stdout-logname    s   File to write stdout log name to
--qsee-logname      s   File to write qsee log to
--testName          s   Name of test. Will be appended to log folder if 
                        --useFolder is used
--logSTDoutput      f   Log standard output to text folder
";
}
 
#==============================================================================
# Print help. There should be no need to edit this.
#==============================================================================
if ($help) {
   printHelp();
   ExitTest("");
}
#==============================================================================
#  Initialize XML Results module for ATE output
#==============================================================================
my $results;
# if (defined($ATE_RESULTS_LOCATION)) {
   # $results = new CaseResult($ATE_RESULTS_LOCATION);
# }

#==============================================================================
# Log folder
#==============================================================================

#Setup logs folder if flagged
my $logFolder = "";
my $local_log_dir = $perl_shell->{log_dir};
if ($useFolder) {
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime();
   #$logFolder = sprintf("${ATE_LOCALSTORAGE}\\TestLogs\\%04d-%02d-%02d-%02d-%02d-%02d-${testName}\\", 1900 + $year, $mon, $mday, $hour, $min, $sec);
   $logFolder = sprintf("${local_log_dir}\\TestLogs\\%04d-%02d-%02d-%02d-%02d-%02d-${testName}\\", 1900 + $year, $mon, $mday, $hour, $min, $sec);
   StatusMsg("Storing logs in $logFolder");
   mkdir "${local_log_dir}\\TestLogs";
   #mkdir "${ATE_LOCALSTORAGE}\\TestLogs"; #Assume it doesn't already exist
   mkdir $logFolder;
   
   if ($logSTDoutput) {
      open STDOUT, ">", $logFolder."STDoutput.txt" or die "$0: open: $!";
      open STDERR, ">&STDOUT"        or die "$0: dup: $!";
   }
}

#==============================================================================
# Main Test Case
#==============================================================================
$STDOUT_logName = $logFolder.$STDOUT_logName;
$QSEE_logName = $logFolder.$QSEE_logName;
my $parseResult;
my $android_flavor;

StatusMsg("Test Output : $STDOUT_logName");
unless (-e $STDOUT_logName) {
        open(TESTFH, "> $STDOUT_logName");
        close(TESTFH);
}

{
   #Setup ADB
   unless ($skipsetup){   
      #if (!APT::initAdb()) {
      #   ExitTest("No ADB device found", $metrics, $res_failure);
      #}
	     $android_flavor = APT::GetBranch();
	     APT::axiomAdbRemount($perl_shell);
	  #}
   }
   
   #$perl_shell->run_adb_shell_command("mount -o rw,remount /vendor/firmware_mnt");
   #Copying TZ TA's to Device
   $perl_shell->run_adb_shell_command("ls /vendor/firmware_mnt/image/ -l");
   StatusMsg("Copying TA split binaries from build to device");

   #my $response = $perl_shell->run_adb_shell_command("getprop ro.build.version.release");
   #my $android_flavor = $response->{message};
   if ($perl_shell->{script_params}{'skipsetup'} eq 'False') {
	   my @aptClientName = split( /\s*,\s*/, $aptClientName);
	   foreach my $fileNamePattern (@aptClientName) {
		 my $pattern = $fileNamePattern . ".*";
		 #StatusMsg("copy_from_build_to_device($tzRoot, $binLoc, $device_dest, $pattern)");
		 if ($pattern =~ /bintest/){
			if ($android_flavor eq 'Q') {
			   my $binpattern = $fileNamePattern.".mbn";
			   $perl_shell->copy_from_build_to_device($tzRoot, $bintest, $device_dest,$binpattern);
			   $perl_shell->adb_push("\\\\cbolis-linux\\workspace\\bintest_client\\bintest_client", "/vendor/bin/bintest_client");
			   $perl_shell->run_adb_shell_command("chmod 777 /vendor/bin/bintest_client");
			}
		 } else {
			if ($android_flavor eq 'Q') {
			   $perl_shell->copy_from_build_to_device($tzRoot, $binLoc, $device_dest, $pattern);
			   $perl_shell->adb_push("\\\\twinkle\\APT_IOT\\SSG_CPT\\SSG\\axiom_test\\apttest_client", "/vendor/bin/apttest_client");
			   $perl_shell->run_adb_shell_command("chmod 777 /vendor/bin/apttest_client");
			}
		 }
	   }
   }

   $perl_shell->run_adb_shell_command("sync");
   StatusMsg("List of files in $device_dest");
   $perl_shell->run_adb_shell_command("ls $device_dest -l");
   
   #Whether or not to load binaries
   # if ($loadBinaries){
        # APT::loadTzBinaries($tzRoot, "cmnlib", "sampleapp");
   # }
   
   if ($createSFSDir) {
      StatusMsg("Running Dummy test before running SFS tests");
      system("adb shell apttest_client -n $aptClientName -c 100 -s 1"); #Dummy command to setup SFS directory
      ExitTest("SFS Directory Created", $metrics, $res_success);
   }
   
   #Execute test
   {
      my ($starttime, $endtime, $runtime);
      $starttime = time;

      # Clear logs
      ClearAllLogs($ASIA_OS_ANDROID, $logFolder);
      sleep(1);
   
      # Start logs
      SpawnLogWindows($aptClientName, $logFolder);
      # sleep (10);

      #Execute test
      {
         StatusMsg("Executing TZ-QSEE test $Cmd");
         if($Cmd eq '100' || $Cmd eq '102' || $Cmd eq '103' || $Cmd eq '104' 
               || $Cmd eq '106' || $Cmd eq '107' || $Cmd eq '108' || $Cmd eq '109' 
               || $Cmd eq '110' || $Cmd eq '112' || $Cmd eq '115' || $Cmd eq '117' 
               || $Cmd eq '118' || $Cmd eq '119' || $Cmd eq '120' || $Cmd eq '121'
               || $Cmd eq '122') {
             #StatusMsg("Running Dummy test before running SFS tests");
             #system("adb shell apttest_client -n $aptClientName -c 100 -s 1"); #Dummy command to setup SFS directory
             #sleep(2);
runAgain:
            StatusMsg("Running SFS tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            my $rc = system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
            StatusMsg("Command: return value is $rc");
         } elsif ($Cmd eq '130' || $Cmd eq '131' || $Cmd eq '132') {
            StatusMsg("Running COMSTR tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '135' || $Cmd eq '136' || $Cmd eq '137') {
            StatusMsg("Running COUNTER tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '140' || $Cmd eq '141' || $Cmd eq '142') {
            StatusMsg("Running MSGPASS tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '145' || $Cmd eq '146' || $Cmd eq '147') {
            StatusMsg("Running SHAREDBUF tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '150' || $Cmd eq '151' || $Cmd eq '152') {
            StatusMsg("Running SAFEFUSE tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '155' || $Cmd eq '156' || $Cmd eq '157') {
            StatusMsg("Running HEAP tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '175') {
            StatusMsg("Running ASLR test");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d >> $STDOUT_logName");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d >> $STDOUT_logName");
         } elsif ($Cmd eq '176') {
            StatusMsg("Running Secure Clock tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '200' || $Cmd eq '201' || $Cmd eq '202') {
            StatusMsg("Running CIPHER tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '205' || $Cmd eq '206' || $Cmd eq '207') {
            StatusMsg("Running CMAC tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '210' || $Cmd eq '211' || $Cmd eq '212') {
            StatusMsg("Running CRYPTO tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '215' || $Cmd eq '216' || $Cmd eq '217') {
            StatusMsg("Running ECC tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '220' || $Cmd eq '221' || $Cmd eq '222') {
            StatusMsg("Running HASH tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '225' || $Cmd eq '226' || $Cmd eq '227') {
            StatusMsg("Running HMAC tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '230' || $Cmd eq '231' || $Cmd eq '232') {
            StatusMsg("Running KDF tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '235' || $Cmd eq '236' || $Cmd eq '237') {
            StatusMsg("Running PRNG tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '240' || $Cmd eq '241' || $Cmd eq '242') {
            StatusMsg("Running RSA tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '245' || $Cmd eq '246' || $Cmd eq '247') {
            StatusMsg("Running SWAES tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '250' || $Cmd eq '251' || $Cmd eq '252') {
            StatusMsg("Running SWDES tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '255' || $Cmd eq '256' || $Cmd eq '257') {
            StatusMsg("Running SWHASH tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '260' || $Cmd eq '261' || $Cmd eq '262') {
            StatusMsg("Running SWHMAC tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '285' || $Cmd eq '286' || $Cmd eq '287') {
            StatusMsg("Running PBKDF2 tests");
            StatusMsg("Command: adb shell apttest_client -n $aptClientName -c $Cmd -d");
            system("adb shell apttest_client -n $aptClientName -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '300') {
            StatusMsg("Running VFP Floating Point Operation tests");
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -d");
            system("adb shell apttest_client -n apttestapp -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '301') {
            StatusMsg("Running VFP 301 tests");
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -d");
            system("adb shell apttest_client -n apttestapp -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '302') {
            StatusMsg("Running VFP 302 tests");
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -d");
            system("adb shell apttest_client -n apttestapp -c $Cmd -d > $STDOUT_logName");
         } elsif ($Cmd eq '500') {
            StatusMsg("Running Single SPI tests");
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -s 3 -d1 12 -d2 11");
            system("adb shell apttest_client -n apttestapp -c $Cmd -s 3 -d1 12 -d2 11 > $STDOUT_logName");
            
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -s 5 -d1 12 -d2 11");
            system("adb shell apttest_client -n apttestapp -c $Cmd -s 5 -d1 12 -d2 11 >> $STDOUT_logName");
         } elsif ($Cmd eq '501') {
            StatusMsg("Running Dual SPI tests");
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -s 1 -d1 12 -d2 4");
            system("adb shell apttest_client -n apttestapp -c $Cmd -s 1 -d1 12 -d2 4 > $STDOUT_logName");
            
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -s 6 -d1 12 -d2 4");
            system("adb shell apttest_client -n apttestapp -c $Cmd -s 6 -d1 12 -d2 11 >> $STDOUT_logName");
         } elsif ( $aptClientName eq "bintestapp32" || $aptClientName eq "bintestapp64" ) {
            StatusMsg("Running QSEE API Binary Compatibility tests");
            StatusMsg("Command: adb shell bintest_client -n $aptClientName -c $Cmd");
            system("adb shell \"bintest_client -n $aptClientName -c $Cmd\" > $STDOUT_logName");

         } elsif ($Cmd eq '0' || $Cmd eq '2' || $Cmd eq '10' 
               || $Cmd eq '11' || $Cmd eq '12' || $Cmd eq '13' || $Cmd eq '14' || $Cmd eq '15'
               || $Cmd eq '16' || $Cmd eq '17' || $Cmd eq '18' || $Cmd eq '20' 
               || $Cmd eq '21' || $Cmd eq '22' || $Cmd eq '23' || $Cmd eq '24'
               || $Cmd eq '25' || $Cmd eq '26' || $Cmd eq '27' || $Cmd eq '28' 
			   || $Cmd eq '30' || $Cmd eq '31' || $Cmd eq '32'
               || $Cmd eq '33' || $Cmd eq '34' || $Cmd eq '35' 
			   || $Cmd eq '36' || $Cmd eq '37' || $Cmd eq '38') {
            StatusMsg("=== Running HLOS QSEECOM tests ===");
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -d");
            system("adb shell apttest_client -n apttestapp -c $Cmd -d > $STDOUT_logName");
         } 
         elsif ($Cmd eq '1') {
            StatusMsg("Running HLOS RPMB Provisioning Test");
            StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -s $scmd ");
			system("adb shell apttest_client -n apttestapp -c $Cmd -s $scmd");
            
            
			#Check RPMB provision status
# 			system("adb shell \"echo 2 > /data/input2.txt\"");
# 			system("adb shell \"echo 1 > /data/input1.txt\"");
# 			StatusMsg("Command: qseecom_sample_client v smplap32 14 1 < /data/input2.txt");
# 			system("adb shell \"apttest_client -n apttestapp -c $Cmd -s 2 < /data/input1.txt\"");
#             StatusMsg("Command: adb shell apttest_client -n apttestapp -c $Cmd -s 2 < /data/input1.txt");
# 			system("adb shell \"qseecom_sample_client v smplap32 14 1 < /data/input2.txt\" > $STDOUT_logName");
            
         } else {
            StatusMsg("Incorrect Command");
            ExitTest("", $metrics, $res_failure);
         }
      }

      #Parse results
      $endtime = time;
      $runtime = $endtime - $starttime;
      StatusMsg(sprintf("Test took %.3f seconds.", $runtime));

      #system("adb kill-server");
      #APT::initAdb(); add option to skip adb device checking
      unless ($skipsetup){
      if (!APT::initAdb()) {
         ExitTest("No ADB device found", $metrics, $res_failure);
         }
      }

      StatusMsg("Parsing results");
      if ($Cmd eq '1' && $aptClientName ne "bintestapp32" && $aptClientName ne "bintestapp64") {
         $parseResult = parseRPMBOutput($results);
      }
      elsif ($Cmd eq '175') {
         $parseResult = parseASLROutput($results);
      } elsif ($aptClientName eq "bintestapp32" || $aptClientName eq "bintestapp64") {
         $parseResult = parseBinTestOutput($results); #Parse results from BinTest (binary compatibility test)
      } elsif (($Cmd eq '0' || $Cmd eq '2' || $Cmd eq '10' 
               || $Cmd eq '11' || $Cmd eq '12' || $Cmd eq '13' || $Cmd eq '14' || $Cmd eq '15'
               || $Cmd eq '16' || $Cmd eq '17' || $Cmd eq '18' || $Cmd eq '20' 
               || $Cmd eq '21' || $Cmd eq '22' || $Cmd eq '23' || $Cmd eq '24'
               || $Cmd eq '25' || $Cmd eq '26' || $Cmd eq '27' || $Cmd eq '28' 
			   || $Cmd eq '30' || $Cmd eq '31' || $Cmd eq '32'
               || $Cmd eq '33' || $Cmd eq '34' || $Cmd eq '35' 
			   || $Cmd eq '36' || $Cmd eq '37' || $Cmd eq '38') ) {
		$parseResult = parseQSEECOMOutput($results);
	  } elsif ($Cmd eq '200' || $Cmd eq '205' || $Cmd eq '210' || $Cmd eq '215' 
	         || $Cmd eq '220' || $Cmd eq '225' || $Cmd eq '230' || $Cmd eq '235' 
			 || $Cmd eq '236' || $Cmd eq '237' || $Cmd eq '245' || $Cmd eq '250' 
             || $Cmd eq '255' || $Cmd eq '260' || $Cmd eq '265' || $Cmd eq '286'
			 || $Cmd eq '270' || $Cmd eq '275' || $Cmd eq '245') {
		StatusMsg("parsing STDOUT output since aptcryptotestapp is not showing required debug logs");
		$parseResult = parseOutput($results);
	  }
	  else {
         $parseResult = parseQSEECOMOutput($results);
         #in case the test is being run for the first time then rerun so that SFS directory gets created
         if ($parseResult == 1 && ($Cmd eq '100' || $Cmd eq '102' || $Cmd eq '103' 
               || $Cmd eq '104' || $Cmd eq '106' || $Cmd eq '107' || $Cmd eq '108' 
               || $Cmd eq '109' || $Cmd eq '110' || $Cmd eq '112' || $Cmd eq '115' 
               || $Cmd eq '117' || $Cmd eq '118' || $Cmd eq '119' || $Cmd eq '120' 
               || $Cmd eq '121' || $Cmd eq '122')) {
            StatusMsg("SFS Test failed for the first time. Will run again to make sure failure is not due to no index file.");
            if ($runSecondTime == 0) {
               $runSecondTime = 1;
               ClearAllLogs($ASIA_OS_ANDROID, $logFolder);
               sleep(1);
   
               # Start logs
               SpawnLogWindows($aptClientName, $logFolder);
               sleep (10);
               goto runAgain;
            }
         }
      }
      if ($parseResult == -1) {
         ExitTest("Parsing failed.", $metrics, $res_failure);
      } elsif ($parseResult == 1) {
         ExitTest("Test failed.", $metrics, $res_failure);
      } else {
      }
   }

   #Check for crash
   StatusMsg("check for device health");
   if (!APT::checkAdbDevice()) {
      ExitTest("The device has crashed druing the test", $metrics, $res_failure);
   }
   
   if (not $parseResult){
       ExitTest("", $metrics, $res_success);
   }
}

#==============================================================================
#  Subroutines
#==============================================================================
sub parseOutput {
   my $results = shift;
   my ($OUTPUTFILE, $line);

   open($OUTPUTFILE, '<', $STDOUT_logName) or return -1; 
   while ($line = <$OUTPUTFILE>) {
      $line =~ s/^\s+//;
      my @words = split(" ", $line);
      if ( $words[1] && (($words[1] eq "aptclient_run_apttestapp_test") 
               || ($words[1] eq "aptclient_run_secureapp_test") 
               || ($words[1] eq "aptclient_run_rpmb_test")) ){
         if ($words[2] && ($words[2] eq "PASSED")) {
            StatusMsg("APT Test Passed.");
            close($OUTPUTFILE);
            return 0;
         } elsif ($words[2] && ($words[2] eq "FAILED")) {
            ErrorMsg("APT Test Failed.");
            close($OUTPUTFILE);
            return 1;
         }
      }
   }
   close($OUTPUTFILE);
   
   return -1;
}

sub parseQSEEOutput {
   my ($OUTPUTFILE, $line);
   my $totCount = 0;
   my $totPass = 0;
   my $totFail = 0;
   my $QSEELogFile = $logFolder.$aptClientName.'_QSEE_LOG.txt';

   open($OUTPUTFILE, '<', $QSEELogFile) or return -1; 
   while ($line = <$OUTPUTFILE>) {
      $line =~ s/^\s+//;
      my @words = split(" ", $line);
      print @words;
      if ( $words[1] && ($words[1] eq "***Total") && $words[2] && ($words[2] eq "Tests")) {
         if ($words[3] && ($words[3] eq "executed")) {
            $totCount = $words[5];
         } elsif ($words[3] && ($words[3] eq "passed")) {
            $totPass = $words[5];
         } elsif ($words[3] && ($words[3] eq "failed")) {
            $totFail = $words[5];
         } else {
            ErrorMsg("Invalid string found in the logs. Parsing failed.");
            close($OUTPUTFILE);
            return -1;
         }
      }
   }
   close($OUTPUTFILE);
   
   if ($totCount == 0 && $totFail == 0) {
      StatusMsg("No tests executed");
      return -1;
   } elsif ($totCount != 0 && $totFail == 0 && $totCount == $totPass){
      StatusMsg("APT Test Passed. ($totPass passed out of total $totCount tests)");
      return 0;
   } else {
      StatusMsg("APT Test Failed. ($totFail failed out of total $totCount tests)");
      return 1;
   }
}
sub parseRPMBOutput {
	
   my $results = shift;
   my ($OUTPUTFILE, $line);
   
   open($OUTPUTFILE, '<', $STDOUT_logName) or return -1; 
   
   foreach $line (<$OUTPUTFILE>) {
      StatusMsg("All line: $line");
      if ($line =~ /RPMB_KEY_PROVISIONED_AND_OK/){
         StatusMsg("RPMB Test PASS.");
         close($OUTPUTFILE);
         return 0;
      }
	}
   StatusMsg("RPMB Test FAIL.");
   close($OUTPUTFILE);
   return -1;
}
sub parseQSEECOMOutput {
	
   my $results = shift;
   my ($OUTPUTFILE, $line);
   
   open($OUTPUTFILE, '<', $STDOUT_logName) or return -1; 
   
   foreach $line (<$OUTPUTFILE>) {
      StatusMsg("All line: $line");
      if ($line =~ /APTTEST_CLIENT Test PASSED/){
         #StatusMsg("aptclient_run_qseecom_test PASSED.");
         close($OUTPUTFILE);
         return 0;
      }
	}
   #StatusMsg("aptclient_run_qseecom_test FAIL.");
   close($OUTPUTFILE);
   return -1;
}

sub parseBinTestOutput {
	
   my $results = shift;
   my ($OUTPUTFILE, $line);
   
   open($OUTPUTFILE, '<', $STDOUT_logName) or return -1; 
   
   foreach $line (<$OUTPUTFILE>) {
      StatusMsg("All line: $line");
      if ($line =~ /failed/){
         StatusMsg("Fail line: $line");
         StatusMsg("Bin Test failed.");
         close($OUTPUTFILE);
         return 1;
      }
      elsif ($line =~ /Shutdown App Succeeded/){
         StatusMsg("Pass line: $line");
         StatusMsg("Bin Test Passed.");
         close($OUTPUTFILE);
         return 0;
      }
	}
   
   close($OUTPUTFILE);
   return -1;
}

sub parseASLROutput {
   my $results = shift;
   my ($OUTPUTFILE, $line);
   my $funcName = "address_Space_Layout_Test";
   my $addr;
   my $count = 0;
   #my $QSEELogFile = $logFolder."apttestapp_QSEE_LOG.txt";
   my $QSEELogFile = $logFolder.$aptClientName.'_QSEE_LOG.txt';

   open($OUTPUTFILE, '<', $QSEELogFile) or return -1; 
   while ($line = <$OUTPUTFILE>) {
      $line =~ s/^\s+//;
      my @words = split(" ", $line);
      if ( $words[1] && ($words[1] eq "ASLR") && $words[2] && ($words[2] eq "address")
               && $words[5] && ($words[5] eq "address_Space_Layout_Test")) {
         if ($words[7]) {
            if ($count == 0) {
               $addr = $words[7];
               $count++;
            } else {
               if ($addr eq $words[7]) {
                  StatusMsg("Consequtive addresses are same. FAILED");
                  return 1;
               } else {
                  $addr = $words[7];
               }
               $count++;
            }
         } elsif ($words[2] && ($words[2] eq "FAILED")) {
            ErrorMsg("APT Test Failed.");
            close($OUTPUTFILE);
            return 1;
         }
      }
   }
   close($OUTPUTFILE);
   
   if ($count > 1) {
      StatusMsg("APT Test Passed.");
      return 0;
   } else {
      return -1;
   }
}

#==============================================================================
   # CleanUp and Exit Test Case 
#==============================================================================\
sub ExitTest {
   my ($exitString, $metrics, $exitparam) = @_;
   if (defined($metrics)) {
#	  $perl_shell->add_result_metric(("name" => "Runtime", "units" => "seconds", "value" => $runtime));
   }
   if(defined($exitString)) {
#       $perl_shell->add_result_note(("level" => "Info", "message" => $exitString));
   }
   if(defined($exitparam)) {
       $perl_shell->set_result($exitparam);
   }
   else{
       $perl_shell->set_result();
   }
}

#==============================================================================
#
# Qualcomm Proprietary
#
# Export of this software and/or technology may be controlled
# by the U.S. Government.  Diversion contrary to U.S. law
# prohibited.
#
# Copyright (c) 2016 by Qualcomm Incorporated. All Rights Reserved.
#
# All data and information contained in or disclosed by this document
# is confidential and proprietary information of Qualcomm Incorporated
# and all rights therein are expressly reserved.  By accepting this
# material the recipient agrees that this material and the information
# contained therein is held in confidence and in trust and will not be
# used, copied, reproduced in whole or in part, nor its contents
# revealed in any manner to others without the express written
# permission of Qualcomm Incorporated.
#
#==============================================================================
