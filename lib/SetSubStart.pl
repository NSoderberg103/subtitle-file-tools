#!C:\Strawberry\perl\bin\perl.exe

# SetSubStart.pl [subFile] [newFirstSubStartTime]
# This script takes a subtitle file and shifts the times to have the given start time for the first subtitle.

# Import standard modules.
use autodie;
use strict;
use warnings;

# Import additional modules.
use FindBin;
use lib "${FindBin::Bin}";
use SubFile;

main();



sub main {
   # Set default values for the arguments.
   my $subFile              = "";
   my $newFirstSubStartTime = -1;
   
   # Check for command line arguments.
   if ( scalar(@ARGV) == 2 ) {
      if ( ( -e "${ARGV[0]}" ) &&
           ( $ARGV[1] =~ m/^[0-9]+$/ ) ) {
         $subFile              = $ARGV[0];
         $newFirstSubStartTime = $ARGV[1];
      }
   }
   
   # Prompt for subtitle file if not given or not valid.
   until ( ( -e $subFile ) &&
           ( $subFile =~ m/\.(srt|vtt)$/ ) ) {
      print("Subtitle file to offset: ");
      $subFile = <STDIN>;
      chomp($subFile);
   }
   
   # Prompt for start time if not given or not valid.
   until ( $newFirstSubStartTime >= 0 ) {
      print("Desired timing in ms for first subtitles: ");
      my $input = <STDIN>;
      chomp($input);
      if ( $input =~ m/^[0-9]+$/ ) {
         $newFirstSubStartTime = $input;
      }
   }
   
   # Pass the file to the appropriate subroutine if it is a subtitle file.
   print("Shifting subtitles in \"${subFile}\" to first occur at ${newFirstSubStartTime} ms..." . "\n");
   if    ( $subFile =~ m/^.+\.srt$/ ) {
      SubFile::srtSetStart($subFile, $newFirstSubStartTime);
   }
   elsif ( $subFile =~ m/^.+\.vtt$/ ) {
      SubFile::vttSetStart($subFile, $newFirstSubStartTime);
   }
   
   # Wait for input to exit.
   print("\n" .
         "Press ENTER to exit.");
   <STDIN>;
   exit;
}
