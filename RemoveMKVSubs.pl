#!C:\Strawberry\perl\bin\perl.exe

# RemoveMKVSubs.pl
# This script finds all .mkv files at its location and runs mkvmerge to remove all subtitle tracks.

# Import standard modules.
use autodie;
use strict;
use warnings;

main();



sub main {
   # Iterate across all paths in the run directory.
   opendir(my $directoryHandle, ".");
   while ( my $mkvFile = readdir($directoryHandle) ) {
      
      # Ignore results that aren't an .mkv extension.
      unless( $mkvFile =~ m/^.+\.mkv$/ ) {
         next;
      }
      
      # Run mkvmerge to remux the mkv file to the temp file but without any subtitle tracks.
      my $tempFile = "${mkvFile}";
      $tempFile =~ s/\.mkv/.temp.mkv/;
      my @systemArgs = ( "mkvmerge", "-S", $mkvFile, "-o", $tempFile );
      system(@systemArgs);
      
      # If the temp file was created successfuly, overwrite the original.
      if ( -e $tempFile ) {
         print("Overwriting \"${mkvFile}\"..." . "\n");
         unlink($mkvFile);
         rename($tempFile, $mkvFile);
      }
      
      print("\n");
   }
   closedir($directoryHandle);
   
   # Wait for input to exit.
   print("Press ENTER to exit.");
   <STDIN>;
   exit;
}
