#!/usr/bin/env perl
my $mod = "11/7/12 7:47 PM";
my $version = "0.3";
my $author = "Nick Youngblut";
#--------------------- version log ---------------------#
# v0.2 -> ability to extract archived files
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
if ($#ARGV < 0){
	&usage;
	}
my ($format);
GetOptions(
	   "format=s" => \$format,
	   "help|?" => \&usage # Help
	   );

### Input error check
die " ERROR: provide paired-end Illumina fastq or fasta files (each file is 1 of the pair). Fastq format does not matter.\n"
	if scalar @ARGV < 2;
$format = "fastq" if ! $format;

### Routing main subroutines
shuffleSequences($format);

#----------------------Subroutines----------------------#
sub shuffleSequences{
	### shuffling 2 sequence files together ###
	my $format = shift;

	if(-B $ARGV[0] and $ARGV[0] =~ /tgz$|tar.gz$/){		# if file is compressed
		open(IN1, "-|", "zcat $ARGV[0] | tar  -O -xf -") or die $!;
		}
	elsif(-B $ARGV[0] and $ARGV[0] =~ /.gz$/){			# if file is gzipped
		open(IN1, "-|", "zcat $ARGV[0]") or die $!;
		}
	else{
		open IN1, $ARGV[0] or die $!;
		}
	
	if(-B $ARGV[1] and $ARGV[1] =~ /tgz$|tar.gz$/){		# if file is tar & gz
		open(IN2, "-|", "zcat $ARGV[1] | tar  -O -xf -") or die $!;
		}
	elsif(-B $ARGV[1] and $ARGV[1] =~ /.gz$/){			# if file is gzipped
		open(IN2, "-|", "zcat $ARGV[1]") or die $!;
		}
	else{ 
		open IN2, $ARGV[1] or die $!;
		}
	
	if($format =~ /fastq|fq|fnq/i){
		while(<IN1>){
			print $_;
			for my $i (0..2){ 
				$_ = <IN1>; print $_;
				}
			for my $i (0..3){
				$_ = <IN2>; print $_;
				}
			}
		}
	elsif($format =~ /fasta|fa|fna/i){
		while(<IN1>){
			print $_;
			$_ = <IN1>;
			print $_;
			for my $i (0..1){
				$_ = <IN2>;
				print $_;
				}
			}
		}
	else{ die " ERROR: format not recognized\n"; }

	close IN1;
	close IN2;
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
 shuffleSequences.pl [-f] file1 file2 > output
Options:
 -f 	Format of files (fastq or fasta).
    	 [fastq]
Description:
 The script shuffles Illumina paired-end read
 files (1 file per end) into 1 file.

 tar.gz, tgz, & gz files can be used.
 
 Fastq format (ASCII offset) doesn't matter.
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
