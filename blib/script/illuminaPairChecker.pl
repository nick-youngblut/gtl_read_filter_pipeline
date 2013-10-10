#!/usr/bin/env perl
my $mod = "10/30/12 9:58 PM";
my $version = "0.3";
my $author = "Nick Youngblut";
#--------------------- version log ---------------------#
# v0.3 -> bug fix: if 1st read is from 2nd pair
#
#-------------------------------------------------------#

### packages/perl_flags
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Spec;

### global variables
my ($error);

### I/O
my ($verbose, $single_bool);
GetOptions(
	   "single" => \$single_bool,
	   "verbose" => \$verbose,
	   "help|?" => \&usage # Help
	   );

### Input error check


### Routing main subroutines
illuminaPairChecker($single_bool);

#----------------------Subroutines----------------------#
sub illuminaPairChecker{
	### Clean up broken pairs ###
	my $single_bool = shift;

	my %check;
	while(<>){
		my @tmp;
		if($_ =~ /^\s*@/){@tmp = split(/\s+|#/)};
		
		if(exists($check{$tmp[0]})){	# writing pairs
			my @lines;
			for(1..3){
				my $line = <>;
				push(@lines, $line);
				}
			my $pair_num = splice( @{$check{$tmp[0]}},0,1);
			print join("", $tmp[0], " ", $pair_num, "\n", @{$check{$tmp[0]}});
			print $_, @lines;			
			delete $check{$tmp[0]};
			}
		else{			# if single
			my @lines;
			for(1..3){
				my $line = <>;
				push(@lines, $line);
				}
			$check{$tmp[0]} = [$tmp[1], @lines];
			}
		}
		
	if($single_bool){
		foreach (keys %check){	#writing singles
			print STDERR join("", $_, " ", ${$check{$_}}[0], "\n", @{$check{$_}}[1..3]);
			}
		}
	}

sub error_routine{
	my $error = $_[0];
	my $exitcode = $_[1];
	print STDERR "ERROR: $error\nSee help: [-h]\n";
	exit($exitcode);
	}

sub usage {
 my $usage = <<HERE;
Usage:
 normal use:
   illuminaPairChecker.pl < file.fq > file.fq
 writing out singletons:
   illuminaPairChecker.pl -s < file.fq > file.fq 2> single.fq

Options:
 -s 	Write singletons to STDERR.

Description:
 Check to see if both mates are in the same fastq file. 
 Reads are loaded into a hash until the mate is found,
 so having the reads pairs shuffled will cut down on memory
 usage and computation time.
 
 Paired reads written to STDOUT.
 Singleton read written to STDERR (if '-s').
 
Notes:
 Version: $version
 Last Modified: $mod
 Author: $author
Categories:
 Genome assembly
 
HERE
	print $usage;
    exit(1);
}
