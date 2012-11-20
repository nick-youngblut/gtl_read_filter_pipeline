#!/opt/local/bin/perl 

eval 'exec /opt/local/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
my $mod = "9/18/12 10:11 PM";
my $version = "0.5";
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
use Tie::File;
use File::Spec;
use File::Path qw/remove_tree/;

### global variables
my ($error);

### I/O
if ($#ARGV < 0){
	&usage;
	}	
	
my ($f1, $f2, $format, $num, $verbose, $outdir);
GetOptions(
	   "f1=s" => \$f1,
	   "f2=s" => \$f2,
	   "format=s" => \$format,
	   "numsplit=i" => \$num,
	   "verbose" => \$verbose,
	   "outfile=s" => \$outdir,
	   "help|?" => \&usage # Help
	   );

### Input error check
if(!@ARGV && ! $f1 && ! $f2){
	$error = "Provide at least 1 fastq file.";
	error_routine($error, 1);
	}
if(!$num || $num < 2){
	$error = "-n should be > 1.";
	error_routine($error, 1);
	}
if(! $format){ 
	$error = "What is the format of the input file(s)?";
	error_routine($error, 1);
	}
elsif($format !~ /fast[aq]/i){
	$error = "Specified format not recognized.";
	error_routine($error, 1);
	}

### Routing main subroutines
if($f1 && $f2){
	my $tmp = check_files($f1, $f2);
	($f1, $f2) = @$tmp;
	check_pair_order([$f1, $f2]);
	fastaq_split_fast([$f1, $f2], $format, $num);
	}
if(@ARGV){ 
	my $tmp = check_files(@ARGV);
	@ARGV = @$tmp;
	check_pair_order(\@ARGV);
	fastaq_split_fast(\@ARGV, $format, $num);
	}

#----------------------Subroutines----------------------#	
sub unique_file{
	# making unique log file
		# requires File::Spec
		# IN: directory, file_name
	my ($dir, $end) = @_;
	if(! $dir){ $dir = File::Spec->rel2abs(File::Spec->curdir()); }
	else{ $dir = File::Spec->rel2abs($dir); }
	my $ufile;
	my $cnt = 1;
	my @ends = split(/\./, $end);
	while(1){
		my $loopend;
		if(scalar(@ends) > 1){ $loopend = join("", @ends[0..$#ends-1], $cnt, ".", $ends[$#ends]); }
		else{ $loopend = $end . "$cnt"; }
		$ufile = join("", $dir, "/", $loopend);
		if(-e $ufile || -d $ufile){ $cnt++; next;}
		else{ last;}
		}
		#print Dumper($ufile); exit;
	return $ufile;
	}

sub check_files{
	foreach(@_){
		$_ = File::Spec->rel2abs($_);
		if(! -e $_ && ! -d $_){ die "ERROR: $_ not found\n", $!; }
		}
	return \@_;
	}
	
sub fastaq_split_fast{
	# splitting 
	print STDERR "..splitting files.\n";
	my $num = pop; my $format = pop;
	my $argv_len = scalar(@{$_[0]}); my $cnt=1;

	foreach my $i (@{$_[0]}){
		# making output directory #
		(my $outdir = $i) =~ s/\.[^\.]+$|$/_split/;
		if( -d $outdir){ remove_tree($outdir) or die $!; }
		mkdir $outdir or die $!;
		
		
		# setting outfile #
		my $outfile = $i;
		my @outparts = File::Spec->splitpath($outfile);
		$outfile = join("/", $outdir, $outparts[2]);	
		
		# checking file format #
		check_format($i, $format);
		
		# file size #	
		(my $tmp = `wc -l $i`) =~ s/^\s+//;
		my @file_size = split(/\s+/, $tmp); 
		if($file_size[0]%2!=0){ die "ERROR: file length is not even.\n"; }
		
		# openning file #
		open(IN, $i) or die $!;
		
		# writting file # 
		my $offset = 0;
		for(1 .. $num){
			if($_ == 1){ $outfile =~ s/(\.[^\.]+)$/_s$_$1/; }
			else{ $outfile =~ s/_s\d+(\.[^\.]+)$/_s$_$1/; }
			open(OUT, "> $outfile") or die $!;
			my $cnt = 1; my $mod = 0;
			if($format =~ /fasta/i){ $mod = 2; }
			elsif($format =~ /fastq/i){ $mod = 4; }
			while(<IN>){ 
				print OUT $_; 
				if(eof){ close OUT; last; }
				elsif($cnt >= $file_size[0]/$num && $cnt % $mod == 0 ){
					close OUT; last;}
				$cnt++;
				}
			}
		# making sure file is not written twice #
		if($cnt == $argv_len){ 
			print STDERR "...Files split.\n";
			exit; 
			}
		else{ $cnt++;}
		close IN; 
		}
	print STDERR "...Files split.\n";
	}

sub check_pair_order{
	### checking the order of paired reads; should be same order ###
	my $files = shift;
	print STDERR "...checking for same pairs in each file (1st and last pairs)\n";
	# loading comp table #
	my %comp;
	for (my $i=0; $i<=$#$files; $i++){
		my @head = split(/\n|\r/, `head -n 4 $$files[$i]`);	
		my @tail = split(/\n|\r/, `tail -n 4 $$files[$i]`);	
		die " ERROR: file not formatted correctly.\n The 1st line doesn't have read names!\n" if $head[0] !~ /^[@>]/;
		die " ERROR: file not formatted correctly.\n The last read(s) don't have names!\n" if $tail[0] !~ /^[@>]/;
		$head[0] =~ s/( |#).+//;
		$tail[0] =~ s/( |#)+.+//;
		push(@{$comp{"head"}}, $head[0]);
		push(@{$comp{"tail"}}, $tail[0]);
		}
	
	# comparing #
	foreach(keys %comp){
		if(${comp{$_}}[0] ne ${comp{$_}}[1]){
			die " ERROR: pair 1 -> ${comp{$_}}[0]\n not equal to\n pair 2 -> ${comp{$_}}[1] in $_ of file\n";
			}
		}
	print STDERR "...pairs appear in order\n";	
	}

sub check_format{
	# checking the format of the 1st and last reads in each files #
	# just checking first 2 reads #
	my ($file, $format) = @_;
	my @parts = File::Spec->splitpath($file);
	my @head = split(/\n|\r/, `head -n 4 $_[0]`);
	my @tail = split(/\n|\r/, `tail -n 4 $_[0]`);
	
	# checking fasta/q format #
	if($format =~ /fastq/i){
		my $errormsg = "ERROR: $file not in $format format.\n";
		if($head[0] !~ /^@/){ die $errormsg;}
		if($head[1] !~ /^[A-Z-]+$/){ die $errormsg; }
		if($head[2] !~ /^\+/){ die $errormsg; }
		if($head[3] =~ /^\s*$/){ die $errormsg; }
		#checking last read #
		if($tail[0] !~ /^@/){ die $errormsg;}
		if($tail[1] !~ /^[A-Z-]+$/){ die $errormsg; }
		if($tail[2] !~ /^\+/){ die $errormsg; }
		if($tail[3] =~ /^\s*$/){ die $errormsg; }
		}
	elsif($format =~ /fasta/i){
		my $errormsg = "ERROR: $file not in $format format.\n";
		if($head[0] !~ /^@/){ die $errormsg;}
		if($head[1] !~ /^[A-Z-]+$/){ die $errormsg; }
		if($head[2] !~ /^@/){ die $errormsg;}
		if($head[3] !~ /^[A-Z-]+$/){ die $errormsg; }
		
		# checking last read #
		if($tail[0] !~ /^@/){ die $errormsg;}
		if($tail[1] !~ /^[A-Z-]+$/){ die $errormsg; }
		if($tail[2] !~ /^@/){ die $errormsg;}
		if($tail[3] !~ /^[A-Z-]+$/){ die $errormsg; }
		}
	else{
		$error = "File format not recognized.";
		error_routine($error, 1);
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
 fastaqsplit_fast.pl -n -format [-f1] [-f2] [-m] [...]
Options:
 -format	'fasta' or 'fastq'
 -n 		Number of splits.
 -f1		1st fasta/fastq file name.
 -f2		2nd fasta/fastq file name.
 ...		For input of multiple fasta/fastq files
 			using wildcards (instead of -f1 & -f2).
Example usage:
 fastaqsplit_fast.pl -n 10 -f1 f_pair.fna -f2 r_pair.fna
 		-format fasta
 fastaqsplit_fast.pl -n 5 *fq -format fastq
Description:
 Program splits fasta or fastq files 'quickly'.
 Split does not shuffle reads.
 Mate-pair order checked:
   	# Checks for same 1st and last reads in
   	  the 2 input files.
 Splits ~4 million fastq reads in ~3 sec 
 	# fastaqsplit takes ~49 sec
 Warning: will overwrite old ouput directories!
 	
Notes:
	Version: $version
	Last Modified: $mod
	Author: $author
	# unix/linux only!
Categories:
	Sequence analysis
		
HERE
	print $usage;
    exit(1);
}