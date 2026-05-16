#!C:\Strawberry\perl\bin\perl.exe

# GetSubStart.pl
# This script finds all subtitle files and prints out the start time in ms of the first subtitle for each file.

# Import standard modules.
use autodie;
use strict;
use warnings;

# Import additional modules.
use FindBin;
use lib "${FindBin::Bin}";
use Sort::Key::Natural;
use SubFile;

main();



sub main {
   # Open the directory and get all of the files in natural order.
   opendir(my $directoryHandle, ".");
   my @files = Sort::Key::Natural::natsort(readdir($directoryHandle));
   closedir($directoryHandle);
   foreach my $subFile (@files) {
      
      # Pass the file to the appropriate subroutine if it is a subtitle file.
      my $firstSubStartTime = -1;
      if    ( $subFile =~ m/^.+\.srt$/ ) {
         $firstSubStartTime = SubFile::srtGetStart($subFile);
      }
      elsif ( $subFile =~ m/^.+\.vtt$/ ) {
         $firstSubStartTime = SubFile::vttGetStart($subFile);
      }
      
      # Print out timing info for the subtitle file if it was valid.
      if ( $firstSubStartTime >= 0 ) {
         print("Timing of first found subtitles in \"${subFile}\": ${firstSubStartTime} ms" . "\n");
      }
   }
   
   # Wait for input to exit.
   print("\n" .
         "Press ENTER to exit.");
   <STDIN>;
   exit;
}
