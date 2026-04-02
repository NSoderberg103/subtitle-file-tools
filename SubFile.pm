# SubFile.pm
# This module is used to get or set certain data from or in subtitle files.

# Define the package name.
package SubFile;

# Import standard modules.
use autodie;
use strict;
use warnings;



# timingListToScalar(\@timingList)
# Convert a list of timing values to a single scalar value in milliseconds.
#
# Arguments
# \@timingList:      Reference to list of timing values
#    $timingList[0]: Milliseconds value
#    $timingList[1]: Seconds value
#    $timingList[2]: Minutes value
#    $timingList[3]: Hours value
#
# Returns
# timingScalar: Timing of the list converted to a single scalar value in milliseconds.
sub timingListToScalar {
   my ($timingList) = @_;
   my @timingList = @{$timingList};
   
   # Calculate the timing in milliseconds.
   my $timingScalar = int(     $timingList[3] +     # Milliseconds
                      1000 * ( $timingList[2] +     # Seconds
                      60 *   ( $timingList[1] +     # Minutes
                      60*    ( $timingList[0] )))); # Hours
   
   # Return the millisecond value.
   return($timingScalar);
}



# timingListToScalar(\@timingList)
# Converts a single scalar value in milliseconds to a list of timing values.
#
# Arguments
# timingScalar: Timing of the list converted to a single scalar value in milliseconds.
#
# Returns
# \@timingList:      Reference to list of timing values
#    $timingList[0]: Milliseconds value
#    $timingList[1]: Seconds value
#    $timingList[2]: Minutes value
#    $timingList[3]: Hours value
sub timingScalarToList {
   my ($timingScalar)     = @_;
   my $timingHours        = 0;
   my $timingMinutes      = 0;
   my $timingSeconds      = 0;
   my $timingMilliseconds = 0;
   
   $timingHours = int($timingScalar/(60*60*1000)); # Get hours value
   $timingScalar -= $timingHours * 60 * 60 * 1000; # Subtract hours amount
   $timingMinutes = int($timingScalar/(60*1000));  # Get minutes value
   $timingScalar -= $timingMinutes * 60 * 1000;    # Subtract minutes amount
   $timingSeconds = int($timingScalar/1000);       # Get seconds value
   $timingScalar -= $timingSeconds * 1000;         # Subtract seconds amount
   $timingMilliseconds = int($timingScalar);       # Get milliseconds value
   
   return($timingHours, $timingMinutes, $timingSeconds, $timingMilliseconds);
}



# srtGetStart($srtFile)
# For the given srt file, return the timing in ms of the start of the first subtitle.
#
# Arguments
# $srtFile: srt file to scan
#
# Returns
# $firstSubStartTime: Timing in ms of the start of the first subtitle.
sub srtGetStart {
   my ($srtFile) = @_;
   
   # Read the srt file to find the first subtitle line.
   my $firstSubStartTime = -1;
   open(my $srtHandle, "<", $srtFile);
   while ( my $srtLine = readline($srtHandle) ) {
      
      # Ignore non timing lines.
      unless ( $srtLine =~ m/^[0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+/ ) {
         next;
      }
      
      # Extract the sub starting time from the line and convert to milliseconds.
      my $subStartTimeString = (split(" ", $srtLine))[0];    # Timing values string
      my @subStartTime = split(/:|,/, $subStartTimeString);  # List of [hours, minutes, seconds, milliseconds]
      my $subStartTime = timingListToScalar(\@subStartTime); # Millisecond timing value
      
      # Check the sub time against the current first sub time.
      # If it hasn't been set yet or the new value is lower, update the value of the first sub time.
      if ( ( $firstSubStartTime < 0 ) || ( $subStartTime < $firstSubStartTime ) ) {
         $firstSubStartTime = $subStartTime;
      }
   }
   close($srtHandle);
   
   # Return the timing value.
   return($firstSubStartTime);
}



# srtSetStart($srtFile)
# For the given srt file, print out the timing info.
#
# Arguments
# $srtFile:              srt file to modify
# $newFirstSubStartTime: Timing in ms of what to set the first subtitle start timing to.
sub srtSetStart {
   my ($srtFile, $newFirstSubStartTime) = @_;
   
   # Read the srt file to find the timing for the first subtitles.
   my $oldFirstSubStartTime = srtGetStart($srtFile);
   
   # Print out timing info for srt file.
   print("Current timing of first subtitles in \"${srtFile}\": ${oldFirstSubStartTime} ms" . "\n");
   
   # Calculate the offset from the two first sub times.
   my $subOffset = $newFirstSubStartTime - $oldFirstSubStartTime;
   
   # Define a temp srt file to write to.
   my $srtTempFile = $srtFile;
   $srtTempFile =~ s/\.srt/.temp.srt/;
   
   # Write from the srt file to the temp srt file.
   # Offset the subtitles by the offset amount when a timing line is found.
   open(my $srtHandle, "<", $srtFile);
   open(my $srtTempHandle, ">", $srtTempFile);
   while ( my $srtLine = readline($srtHandle) ) {
      
      # Print non timing lines normally.
      unless ( $srtLine =~ m/^[0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+/ ) {
         print $srtTempHandle ($srtLine);
         next;
      }
      
      # Extract the sub start time from the line and convert to milliseconds.
      my $subStartTimeString = (split(" ", $srtLine))[0];    # Timing values string
      my @subStartTime = split(/:|,/, $subStartTimeString);  # List of [hours, minutes, seconds, milliseconds]
      my $subStartTime = timingListToScalar(\@subStartTime); # Millisecond timing value
      $subStartTime += $subOffset;                           # Apply offset
      
      # Extract the sub end time from the line and convert to milliseconds.
      my $subEndTimeString = (split(" ", $srtLine))[2];  # Timing values string
      my @subEndTime = split(/:|,/, $subEndTimeString);  # List of [hours, minutes, seconds, milliseconds]
      my $subEndTime = timingListToScalar(\@subEndTime); # Millisecond timing value
      $subEndTime += $subOffset;                         # Apply offset
      
      # Convert back from milliseconds to the standard format.
      foreach my $subTime ( $subStartTime, $subEndTime ) {
         my @timingList = timingScalarToList($subTime);
         $subTime = sprintf("%02d:%02d:%02d,%03d", @timingList);
      }
      
      # Substitute the old start and end times with the new ones.
      my @srtLine = split(" ", $srtLine);
      $srtLine[0] = $subStartTime;
      $srtLine[2] = $subEndTime;
      $srtLine = join(" ", @srtLine);
      print $srtTempHandle ("${srtLine}" . "\n");
   }
   close($srtHandle);
   close($srtTempHandle);
   
   # If the temp file was created successfuly, overwrite the original.
   if ( -e $srtTempFile ) {
      print("Overwriting \"${srtFile}\"..." . "\n");
      unlink($srtFile);
      rename($srtTempFile, $srtFile);
   }
}



# vttGetStart($vttFile)
# For the given vtt file, return the timing in ms of the start of the first subtitle.
#
# Arguments
# $vttFile: vtt file to scan
#
# Returns
# $firstSubStartTime: Timing in ms of the start of the first subtitle.
sub vttGetStart {
   my ($vttFile) = @_;
   
   # Read the vtt file to find the first subtitle line.
   my $firstSubStartTime = -1;
   open(my $vttHandle, "<", $vttFile);
   while ( my $vttLine = readline($vttHandle) ) {
      
      # Ignore non timing lines.
      unless ( $vttLine =~ m/^[0-9]+:[0-9]+:[0-9]+\.[0-9]+ --> [0-9]+:[0-9]+:[0-9]+\.[0-9]+/ ) {
         next;
      }
      
      # Extract the sub starting time from the line and convert to milliseconds.
      my $subStartTimeString = (split(" ", $vttLine))[0];    # Timing values string
      my @subStartTime = split(/:|\./, $subStartTimeString); # List of [hours, minutes, seconds, milliseconds]
      my $subStartTime = timingListToScalar(\@subStartTime); # Millisecond timing value
      
      # Check the sub time against the current first sub time.
      # If it hasn't been set yet or the new value is lower, update the value of the first sub time.
      if ( ( $firstSubStartTime < 0 ) || ( $subStartTime < $firstSubStartTime ) ) {
         $firstSubStartTime = $subStartTime;
      }
   }
   close($vttHandle);
   
   # Return the timing value.
   return($firstSubStartTime);
}



# vttSetStart($vttFile)
# For the given vtt file, print out the timing info.
#
# Arguments
# $vttFile:              vtt file to modify
# $newFirstSubStartTime: Timing in ms of what to set the first subtitle start timing to.
sub vttSetStart {
   my ($vttFile, $newFirstSubStartTime) = @_;
   
   # Read the vtt file to find the timing for the first subtitles.
   my $oldFirstSubStartTime = vttGetStart($vttFile);
   
   # Print out timing info for vtt file.
   print("Current timing of first subtitles in \"${vttFile}\": ${oldFirstSubStartTime} ms" . "\n");
   
   # Calculate the offset from the two first sub times.
   my $subOffset = $newFirstSubStartTime - $oldFirstSubStartTime;
   
   # Define a temp vtt file to write to.
   my $vttTempFile = $vttFile;
   $vttTempFile =~ s/\.vtt/.temp.vtt/;
   
   # Write from the vtt file to the temp vtt file.
   # Offset the subtitles by the offset amount when a timing line is found.
   open(my $vttHandle, "<", $vttFile);
   open(my $vttTempHandle, ">", $vttTempFile);
   while ( my $vttLine = readline($vttHandle) ) {
      
      # Print non timing lines normally.
      unless ( $vttLine =~ m/^[0-9]+:[0-9]+:[0-9]+\.[0-9]+ --> [0-9]+:[0-9]+:[0-9]+\.[0-9]+/ ) {
         print $vttTempHandle ($vttLine);
         next;
      }
      
      # Extract the sub start time from the line and convert to milliseconds.
      my $subStartTimeString = (split(" ", $vttLine))[0];    # Timing values string
      my @subStartTime = split(/:|\./, $subStartTimeString); # List of [hours, minutes, seconds, milliseconds]
      my $subStartTime = timingListToScalar(\@subStartTime); # Millisecond timing value
      $subStartTime += $subOffset;                           # Apply offset
      
      # Extract the sub end time from the line and convert to milliseconds.
      my $subEndTimeString = (split(" ", $vttLine))[2];  # Timing values string
      my @subEndTime = split(/:|\./, $subEndTimeString); # List of [hours, minutes, seconds, milliseconds]
      my $subEndTime = timingListToScalar(\@subEndTime); # Millisecond timing value
      $subEndTime += $subOffset;                         # Apply offset
      
      # Convert back from milliseconds to the standard format.
      foreach my $subTime ( $subStartTime, $subEndTime ) {
         my @timingList = timingScalarToList($subTime);
         $subTime = sprintf("%02d:%02d:%02d.%03d", @timingList);
      }
      
      # Substitute the old start and end times with the new ones.
      my @vttLine = split(" ", $vttLine);
      $vttLine[0] = $subStartTime;
      $vttLine[2] = $subEndTime;
      $vttLine = join(" ", @vttLine);
      print $vttTempHandle ("${vttLine}" . "\n");
   }
   close($vttHandle);
   close($vttTempHandle);
   
   # If the temp file was created successfuly, overwrite the original.
   if ( -e $vttTempFile ) {
      print("Overwriting \"${vttFile}\"..." . "\n");
      unlink($vttFile);
      rename($vttTempFile, $vttFile);
   }
}



1;