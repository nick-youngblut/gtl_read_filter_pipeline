#!/usr/bin/env perl
my $mod = "9/18/12 9:33 AM";
my $version = "0.2.1";
my $author = "Nick Youngblut";
#--------------------- version log ---------------------#
#
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
my ($format, $prefix, $gzip_bool);
GetOptions(
	   "prefix=s" => \$prefix,
	   "format=s" => \$format,
	   "gzip" => \$gzip_bool,
	   "help|?" => \&usage # Help
	   );

### Input error check
$format = "fastq" if ! $format;
$prefix = "unshuf" if ! $prefix;

### Routing main subroutines
unshuffleSequences($format, $prefix, $gzip_bool);

#----------------------Subroutines----------------------#
sub unshuffleSequences{
	### shuffling 2 sequence files together ###
	my ($format, $prefix, $gzip_bool) = @_;
	
	if($format =~ /fastq|fq|fnq/i){		#fastq
		if($gzip_bool){
			open OUT1, "| gzip > $prefix\_1.fq.gz" or die $!;
			open OUT2, "| gzip > $prefix\_2.fq.gz" or die $!;
			}
		else{
			open OUT1, ">$prefix\_1.fq" or die $!;
			open OUT2, ">$prefix\_2.fq" or die $!;
			}
		my $line;
		while(<>){
			print OUT1 $_;
			for (0..2){
				$line = <>;
				print OUT1 $line;	
				}
			for (0..3){ 
				$line = <>;
				print OUT2 $line; 
				}
			}	
		
		}
	elsif($format =~ /fasta|fa|fna/i){		# fasta
		if($gzip_bool){
			open OUT1, "| gzip > $prefix\_1.fa.gz" or die $!;
			open OUT2, "| gzip > $prefix\_2.fa.gz" or die $!;		
			}
		else{
			open OUT1, ">$prefix\_1.fa" or die $!;
			open OUT2, ">$prefix\_2.fa" or die $!;
			}
		my $line;
		while(<>){
			print OUT1 $_;
			$line = <>;
			print OUT1 $line;
			for (0..1){ 
				$line = <>;
				print OUT2 $line; 
				}
			}
		}
	else{ die " ERROR: format ($format) not recognized\n"; }

	close OUT1;
	close OUT2;
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
 shuffleSequences.pl [-p] [-f] < input
Options:
 -f 	Format of files (fastq or fasta). [fastq]
 -g 	Gzip output? [FALSE]
 -p 	Output file prefix. [unshuf]
Description:
 The script unshuffles Illumina paired-end read
 files. 
 Reads are assumed to be in order with all pairs
 intact (check this with illuminaPairChecker.pl).
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
