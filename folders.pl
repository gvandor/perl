#!/usr/bin/perl -w

#
# This perl script creates a bunch of directories listed in a file.
# Written by Zsolt N Perry on June 5, 2024. (zsolt500n@gmail.com)
#
####################################################################

use strict;
use warnings;

my $START = '/home/gvandor/Temp/';
my $INPUT_FILE = '/home/gvandor/Documents/Github/gvandor/perl/foldersList.txt';

####################################################################

$| = 1;
print "\n\n", '-' x 70;
print "\nINPUT FILE ................... $INPUT_FILE";
print "\nSTART POINT .................. $START\n";
print '-' x 70, "\n";

-d $START or die "\nERROR: START DIRECTORY DOES NOT EXIST!\n\n";
-f $INPUT_FILE or die "\nERROR: INPUT FILE DOES NOT EXIST!\n\n";

@ARGV = ($INPUT_FILE);

my $ERRORS = 0;
while (<>)
{
  my $F = $_;
  $F =~ tr|\r\n\0||d;
  length($F) or next;
  $F = FixPath("$START/$F");
  CreatePath($F) < 0 and $ERRORS++;
}
print "\n\n$ERRORS errors occurred.\n\n";
exit;

##################################################
#                                 File | v2024.6.5
# Creates a directory path (any depth)
#
# This function creates a bunch of subdirectories
# if they don't exist yet. If everything goes well,
# it returns the number of subdirectories created.
# If the path already exists, then returns 0.
# If there is an error, returns -1.
#
# CAUTION: Do not mistype the path name!!!
# Also, if a file name exists that matches the
# directory name you want to create, an error
# will occur and the directory cannot be created.
#
# Usage: INTEGER = CreatePath(PATH)
#
sub CreatePath
{
  defined $_[0] or return 0;
  my $PATH = FixPath($_[0] . '/.');   # Resolve . and .. references
  $PATH =~ tr`\\`/`;   # Change all backslash to forward slash for now.

  my $S = ($^O =~ m/MSWIN|DOS/i) ? "\\" : '/';
  my @FF = split(/[\/]+/, $PATH);
  my $DIR = '';
  my $CREATED = 0;
  foreach (@FF)
  {
    $DIR .= "$S$_";
    $DIR =~ tr|\\\/||s;  # Remove duplicate \\ //
    if (-e $DIR)
    {
      -d $DIR and next;
      print "\nCannot create dir: $DIR\n";
      return -1;
    }
    else
    {
      print "\nCreating dir: $DIR  ";
      mkdir($DIR, 0770);
      if (-d $DIR) { print "OK"; $CREATED++; } else { print "ERROR"; return -1; }
    }
  }
  $CREATED or print "\nAlready exists: $DIR";
  return $CREATED;
}
##################################################
#                                File | v2022.9.24
# Simplifies a path string by resolving . and ..
#
# This function changes the file name separator to
# forward slash or backslash depending on the
# current OS. It also resolves . and .. in path
# strings. It eliminates duplicate slashes.
#
# Examples:
#     ../..               => ../..
#     a/b/././../../..    => ..
#     /a/b/c/./../x.txt   => /a/b/x.txt
#     a/../../../x.txt    => ../../x.txt
#     /a/b/../../../x.txt => /x.txt
#
# Paths can contain too many .. which point to nowhere.
# In that, case the function ignores the error and
# tries to resolve it as much as possible:
#
#     /../                => /
#     /../../a/b/c        => /a/b/c
#
# Usage: STRING = FixPath(PATH)
#
sub FixPath
{
  my $P = defined $_[0] ? $_[0] : '';

  $P =~ tr`\x00-\x1F\"\|<>``d;  # Remove illegal characters: < > | " \t \r \n \0
  $P =~ tr`\\`/`;   # Change all backslash to forward slash.
  $P =~ tr`\/``s;   # Remove duplicate slashes.

  my $DRV = '';
  if (vec($P, 1, 8) == 58) { $DRV = substr($P, 0, 2); $P = substr($P, 2); }

  my $ABS = 0;
  if (vec($P, 0, 8) == 47) { $ABS = 1; $P = substr($P, 1); }

  # Split the path string along '/' characters
  my @D = split(/\//, $P);
  my $i = @D;

  # First, let's eliminate '.' from the path string.
  while ($i--)
  {
    $D[$i] =~ s/^[\0- ]+|[\0- ]+$//g;   # Trim whitespace...
    if (length($D[$i]) == 0 || $D[$i] eq '.') { splice(@D, $i, 1); }
  }

  # Next, we resolve '..' in the path string.
  for ($i = 0; $i < @D; $i++)
  {
    if ($D[$i] eq '..')
    {
      if ($i == 0)
      {
        # If the path string begins with ..
        # then we can do one of two things: either eliminate
        # it or leave it. We eliminate it if the path is an absolute path,
        # because you can't go one level higher than /
        # If the path looks like ../a.txt then it's a relative path,
        # and we have to leave it like it is. But if it looks like
        # /../a.txt then we eliminate those, because /../a.txt
        # makes no sense. This is an invalid path.
        if ($ABS) { splice(@D, $i--, 1); }
        next;
      }

      # If we encounter a '..' but the previous string was also '..'
      # then we can't resolve it. Two '..' separated by '/' don't
      # cancel each other out. We skip this and move on...
      if ($D[$i - 1] eq '..') { next; }

      # Okay, if we can cancel out the previous string, then we use
      # the splice() function to erase the current '..' and the string before it.
      splice(@D, $i - 1, 2);
      $i -= 2;
    }
  }

  # Here we rebuild the original path string.
  $P = $DRV . ($ABS ? '/' : '') . join('/', @D);

  $P =~ tr`/``s;   # Remove duplicate slashes just in case. -- THIS LINE MAY BE UNNECESSARY. WILL HAVE TO REVIEW...

  # Change all forward slashes to backslash on DOS/Windows.
  if ($^O =~ m/DOS|MSWIN/i) { $P =~ tr`/`\\`; }
  # And we're done!

  return $P;
}