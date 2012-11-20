#!/opt/local/bin/perl 

eval 'exec /opt/local/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
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
my ($format, $prefix);
GetOptions(
	   "prefix=s" => \$prefix,
	   "format=s" => \$format,
	   "help|?" => \&usage # Help
	   );

### Input error check
$format = "fastq" if ! $format;
$prefix = "unshuf" if ! $prefix;

### Routing main subroutines
unshuffleSequences($format, $prefix);

#----------------------Subroutines----------------------#
sub unshuffleSequences{
	### shuffling 2 sequence files together ###
	my ($format, $prefix) = @_;
	
	if($format =~ /fastq|fq|fnq/i){		#fastq
		open OUT1, ">$prefix\_1.fq" or die $!;
		open OUT2, ">$prefix\_2.fq" or die $!;
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
		open OUT1, ">$prefix\_1.fa" or die $!;
		open OUT2, ">$prefix\_2.fa" or die $!;
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
 shuffleSequences.pl [-p] [-f] < input > output
Options:
 -f 	Format of files (fastq or fasta).
    	 [fastq]
 -p 	Output file prefix.
    	 [unshuf]
Description:
 The script unshuffles Illumina paired-end read
 files. 
 Reads are assumed to be in order with all pairs
 intact.
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
