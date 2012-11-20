#!/opt/local/bin/perl 

eval 'exec /opt/local/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
my $mod = "8/27/12 2:35 PM";
my $version = "0.3.2";
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
if ($#ARGV < 0){
	&usage;
	}
my ($f1, $f2 ,$num, $rep, $verbose, $outfile, @num);
GetOptions(
	   "f1=s" => \$f1,	#folder 1
	   "f2=s" => \$f2,	#folder 2
	   "number=s" => \$num,	#number of files to combine
	   "rep=i" => \$rep,	#repitition of combinations
	   "verbose" => \$verbose,
	   "help|?" => \&usage # Help
	   );
if($num && $num =~ /-/){ @num = make_num_list($num);}
elsif($num){ @num = split(/,/, $num);}

### Input error check
if(! $f1){
	$error = "Provide the name of a folder of files to concatenate.";
	error_routine($error, 1);
	}
if(! $num){
	$error = "Provide number of files # or #,#,#... (list) or #-# (range).";
	error_routine($error, 1);
	}
if(! $rep){ $rep = 1; }
foreach(@num){ 
	if($_ !~/^[0-9]+$/){ 
		$error = "Provide number of files # or #,#,#... (list) or #-# (range).";
		error_routine($error, 1);
		}
	}
	
### Routing main subroutines
$f1 =~ s/\/$|$/\//;
$f2 =~ s/\/$|$/\//;
$f1 = File::Spec->rel2abs($f1);
$f2 = File::Spec->rel2abs($f2);
my ($file_list1, $file_list2);
$file_list1 = make_file_list($f1, \@num);
if($f2){ 
	$file_list2 = make_file_list($f2, \@num); 
	if($#$file_list1 != $#$file_list2){ die "Folders of files should have same number of files in the same order\n"; }
	}
my $cat_list = make_random_cat_list($f1, $f2, $file_list1, $file_list2, \@num, $rep);
write_cat_files($cat_list, $f1, $f2);

#----------------------Subroutines----------------------#
sub make_num_list{
	my @num = split(/-/, $_[0]);
	if(scalar(@num) != 2){ die "Range must be #-# format!\n"; }
	my @num2 = ($num[0]..$num[1]);
	return @num2;
	}
	
sub make_file_list{
	my ($folder, $num) = @_;
	
	opendir(DIR, $folder) or die $!;
	my @files = readdir(DIR);
	my @files2;
	foreach(@files){
		if($_ !~ /^\.+.*$/){ push(@files2, $_); }
		}

	@files2 = sort(@files2);
	return \@files2;
	}
	
sub make_random_cat_list{
	my($f1, $f2, $file_list1, $file_list2, $num, $rep) = @_;
	
	# checking to make sure none of the numbers in $num are greater than the $file_list size #
	@$num = sort {$a <=> $b} @$num;
	die " ERROR: '-n' value of $$num[$#$num] is > number of files to concatenate (", scalar @$file_list1, ")!\n" 
		if $$num[$#$num] > scalar @$file_list1;
	
	# making the random concat list #
	print STDERR "...making random concatentation list\n" if $verbose;
	
	if(scalar(@num)==1 && $num[0]==1){ die "Number of files to concatenate must be > 1\n."; }
	my %cat_list;	# list of name and files
	for my $i (1..$rep){	#replicates of number files combined
		foreach my $ii (@$num){	#list of number of files to combine
			my (@rand_files1, @rand_files2, %rand_check);
			for (my $iii=0; $iii<$ii; $iii++){	# making rand file list
				my $rand = int(rand(scalar(@$file_list1)));
				if(exists($rand_check{$rand})){ redo; }
				#if($rand == $last_rand){ redo; }
				else{
					$rand_check{$rand} = $rand;
					push(@rand_files1, $f1 . "\/$$file_list1[$rand]");
					if($f2){ push(@rand_files2, $f2 . "\/$$file_list2[$rand]"); }
					}
				}
 			my %tmp;
 			$tmp{$f1} = \@rand_files1;
			if($f2){ $tmp{$f2} = \@rand_files2; }
			$cat_list{"n$ii\_r$i"} = \%tmp;
			}
		}
	print STDERR "...done making random concatentation list\n" if $verbose;
		#print Dumper(%cat_list); exit;
	return \%cat_list;
	}

sub write_cat_files{
	my ($cat_list, $f1, $f2) = @_;
	mkdir("$f1\_cat/");
	if($f2){ mkdir("$f2\_cat/"); }
	# concatenating #
	foreach my $i (keys %$cat_list){
		for my $ii (keys %{$$cat_list{$i}}){
		
			my $ext;
			if(${$$cat_list{$i}{$ii}}[0] =~ /\.[^\.]{1,10}$/){ ($ext = ${$$cat_list{$i}{$ii}}[0]) =~ s/.+\././; }
			else{ $ext = ""; }
			
			my @path = File::Spec->splitpath($ii);
			open(OUT, "> $ii\_cat\/$path[2]\_$i$ext") or die $!;
			foreach (@{$$cat_list{$i}{$ii}}){
				#print Dumper($_); exit;
				open(IN, $_) or die $!;
				while(<IN>){ print OUT $_; }
				close IN;
				}
			close OUT;
			}
		}
	print "  Concatenated files written.\n  Have a swell day.\n";
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
 rand_cat.pl -f1 -f2 -n [-r]
Options:
 -f1	Folder 1
 -f2	Folder 2
 -n 	Number of files to randomly concatenate
 		 #   or   #,#,#... (list)   or   #-# (range)
 -r		Number of repetitions of random concatenations
Description:
  Program randomly concatenates files in a folder.
  The number of files used is specified by the user.
Notes:
	Version: $version
	Last Modified: $mod
	Author: $author
	# If providing 2 folders of paired end reads, file 
	  order in folders must be the same!
Categories:
	Genome assembly
	Utility
		
HERE
	print $usage;
    exit(1);
}