#!/usr/bin/env perl

my $mod = "10/30/12 8:46 PM";
my $version = "0.7";
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
use List::Util qw/max/;
use DBI;

### global variables
my ($error);

### I/O
my ($verbose, $db_in, @nums, $unshuf, $prefix, $count, $random, $count_bool);
GetOptions(
	   "database=s" => \$db_in,			# name of database to pull reads from
	   "number=i{,}" => \@nums,			# list of number of pairs of reads to write
	   "unshuffle" => \$unshuf, 		# unshuff reads 
	   "prefix=s" => \$prefix,			# prefix for files to write
	   "random" => \$random,
	   "count" => \$count_bool,
	   "verbose" => \$verbose,
	   "help|?" => \&usage # Help
	   );

### Input error check
die " ERROR: provide the name of the database file ('-d')\n" if ! $db_in;
die " ERROR: provide an output file prefix ('-p')\n" if ! $prefix && ! $count_bool;

### Routing main subroutines
my $dbh = make_connection($db_in);
my $cnt = count_pairs($dbh, \@nums, $count_bool);
my $rand_nums_ref = rand_num_gen(1, $cnt);
if(! $unshuf) { write_reads_unshuf($dbh, \@nums, $prefix, $random, $rand_nums_ref); }		# if output to seperate read files
else{ write_reads_shuf($dbh, \@nums, $prefix, $random, $rand_nums_ref); }					# if keeping reads shuffled
$dbh->disconnect();

#----------------------Subroutines----------------------#
sub rand_num_gen{
	### making an array of random numbers (fisher_yates_shuffle) ###
	my ($start, $end) = @_;
    my $array = [$start..$end];
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    		}
	return $array;
	}
	
sub count_pairs{
	### getting a count of number of reads the in db ###
	my ($dbh, $nums_ref, $count_bool) = @_;
	my $sth = $dbh->prepare("SELECT count(*) FROM reads"); 
	if(! $sth){ die " ERROR: the database file seems empty or not formatted correctly!\n"; }
	$sth->execute();
	my $cnt;
	while (my $row = $sth->fetchrow_arrayref()){
		$cnt = $$row[0];
		}

	# writing count #
	if($count_bool){
		print " Number of read pairs in DB = $cnt\n";
		$dbh->disconnect();
		exit;
		}
	
	# checking to see if number requested is > than number in DB #
	my $max_num = max(@$nums_ref);
	if($max_num > $cnt){
		$dbh->disconnect();
		die " ERROR: Cannot select $max_num read pairs. $max_num is > number of reads in DB ($cnt).\n";
		}
	return $cnt;
	}

sub write_reads_unshuf{
=item
description:
  Getting random number of reads from db and writing to a file.
  This will be done for each number in list.
  Unshuffling reads
=cut
	my ($dbh, $nums_ref, $prefix, $random, $rand_nums_ref) = @_;
	foreach my $num (@$nums_ref){		# foreach number of reads to extract
		
		# opening file #
		my $name_num = get_name_num($num);
		open OUTF, ">$prefix\_$name_num\_F.fq" or die $!;
		open OUTR, ">$prefix\_$name_num\_R.fq" or die $!;
		
		my $sth;
		if($random){ $sth = $dbh->prepare("SELECT * FROM reads LIMIT $num"); }			# if not random
		else{ 
			my $tmp = "SELECT * FROM reads where rowid in (" . join(",", @$rand_nums_ref[0..($num - 1)]) . ")"; 
			$sth = $dbh->prepare($tmp); 
			}
		$sth->execute();
		while (my $row = $sth->fetchrow_arrayref()){
			#my @nrow = split /\t/, $$row[0];
				#print Dumper @nrow; exit;
			print OUTF join("\n", @$row[0..1]), "\n+\n$$row[2]\n";
			print OUTR join("\n", @$row[3..4]), "\n+\n$$row[5]\n";
			}
		close OUTF;
		close OUTR;
		}
	}

sub write_reads_shuf{
=item
description:
  Getting random number of reads from db and writing to a file.
  This will be done for each number in list.
=cut
	my ($dbh, $nums_ref, $prefix, $random) = @_;
	
	foreach my $num (@$nums_ref){		# foreach number of reads to extract
		# opening file #
		my $name_num = get_name_num($num);
		open OUT, ">$prefix\_$name_num\_FR.fq" or die $!;
		
		# querying #
		my $sth;
		if($random){ $sth = $dbh->prepare("SELECT * FROM reads LIMIT $num"); }			# if not random
		else{ 
			my $tmp = "SELECT * FROM reads where rowid in (" . join(",", @$rand_nums_ref[0..($num - 1)]) . ")"; 
			$sth = $dbh->prepare($tmp); 
			}
			
		$sth->execute();
		while (my $row = $sth->fetchrow_arrayref()){
			my @nrow = split /\t/, $$row[0];
				#print Dumper @nrow; exit;
			print OUT join("\n", @nrow), "\n";
			}
		close OUT;
		}
	}

sub get_name_num{
	### making part of output name ###
	my $num = shift;
	my %sym = ( 1 => "", 2 => "t", 3 => "m", 4 => "b");
	my %div = ( 1 => 1, 2 => 1000, 3 => 1000000, 4 => 1000000000);
	my $val = int((length($num)-1)/3) + 1; 
	my $name_num = join("", $num/$div{$val}, $sym{$val});
		#print Dumper $name_num; exit;
	return $name_num;
	}

sub make_connection{
=item
description:
  making a connection to the created db
=cut
	my $db_out = shift;
	my %attr = (RaiseError => 0, PrintError=>0, AutoCommit=>0);
	my $dbh = DBI->connect("dbi:SQLite:dbname=$db_out", '','', \%attr) 
		or die " Can't connect to $db_out: $DBI::errstr";
	return $dbh;
	}

sub usage {
 my $usage = <<HERE;
Usage:
  sqlite2fastq.pl [-c] [-u] [-r] -n -p -d
Options:
  -c 	Just count number of reads in DB & exit.
  -u 	Unshuffle reads?  [TRUE]
  -r  	Randomly draw pairs from DB?  [TRUE]
  -n 	Number of pairs of reads to write. 
     	Multiple values accepted.
  -p 	Output file prefix.
  -d 	Database file name.
Description:
  Get specified numbers of pairs of randomly drawn
  reads from a sqlite3 database created with 'fastq2sqlite.pl'
  
  Number of reads added output file names. 
  Using fisher-yates shuffle for randomizing.
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


__DATA__
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS reads;

CREATE TABLE reads (
name1 TEXT NOT NULL,
read1 TEXT NOT NULL,
qual1 TEXT,
name2 TEXT NOT NULL,
read2 TEXT NOT NULL,
qual2 TEXT
);
COMMIT;

