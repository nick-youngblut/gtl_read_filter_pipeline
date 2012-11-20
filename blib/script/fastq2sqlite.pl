#!/usr/bin/env perl

my $mod = "11/10/12 8:38 AM";
my $version = "0.7";
my $author = "Nick Youngblut";
#--------------------- version log ---------------------#
# v0.7 -> making temporary files for sqlite db creation
#
#-------------------------------------------------------#

### packages/perl_flags
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Spec;
use DBI;

### global variables
my ($error);

### I/O
my ($verbose, $db_out);
GetOptions(
	   "database=s" => \$db_out,		# name of database to make
	   "verbose" => \$verbose,
	   "help|?" => \&usage # Help
	   );

### Input error check
die " ERROR: provide a output database file name ('-d')\n" if ! $db_out;

### Routing main subroutines
make_sqlite_table($db_out);
my $dbh = make_connection($db_out);
#set_pragma($dbh);
load_reads_in_db($dbh, $db_out);
$dbh->disconnect();

#----------------------Subroutines----------------------#
sub load_reads_in_db{
=item
description:
  loading database with read files (shuffled reads)
=cut
	my ($dbh, $db_out) = @_;

	my $sql = $dbh->prepare("INSERT INTO reads values (?, ?, ?, ?, ?, ?)");
	while ( my $i = <> ){
		chomp $i;

		### loading reads to an array ###
		my @mate;
		push(@mate, $i);
		for my $ii (1..7){ 
			chomp( my $line = <> );
			next if $ii==2 || $ii==6;		# skipping plus
			push(@mate, $line); 
			}
		### loading entry ###
		$sql->execute( @mate );
		
		if ($DBI::err){		# error check
			print STDERR " # ERROR! $DBI::errstr\n" unless $verbose;
			}
		}
	$dbh->commit();
	}

sub set_pragma{
=item
description:
  optimizing table by altering pragma
=cut
	my $dbh = shift;
	my @pragma = (
		"PRAGMA foreign_keys=OFF;",
		"PRAGMA journal_mode = OFF;",
		"PRAGMA locking_mode = EXCLUSIVE;",
		"PRAGMA temp_store = MEMORY;"
		);
	foreach (@pragma){
		#my $sql = $dbh->quote($_);
		#print Dumper $sql; exit;
		$dbh->do($_);
	
		if ($DBI::err){		# error check
			print STDERR " # ERROR! $DBI::errstr\n" unless $verbose;
			}
		}	
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

sub make_sqlite_table{
=item
description:
  making sqlite table for loading
=cut
	my $db_out = shift;
	
	open OUT, "| sqlite3 $db_out" or die $!;
	while(<DATA>){ print OUT $_; }
	close OUT;
	}

sub usage {
 my $usage = <<HERE;
Usage:
  fastq2sqlite.pl [-v] -d < shuffled.fq
Options:
  -v 	Show database loading errors? [TRUE]
  -d 	Name of database to make.
Description:
  The script makes an sqlite3 database from
  a fastq of shuffled paired-end reads.

  Any number of random reads can then be written
  from the database using 'sqlite2fastq.pl'
  
Notes:
  Version: $version
  Last Modified: $mod
  Author: $author
Categories:
	
HERE
	print $usage;
    exit(1);
}


__DATA__
BEGIN TRANSACTION;

DROP TABLE IF EXISTS reads;

CREATE TABLE reads (
name1 TEXT NOT NULL,
seq1 TEXT NOT NULL,
qual1 TEXT NOT NULL,
name2 TEXT NOT NULL,
seq2 TEXT NOT NULL,
qual2 TEXT NOT NULL
);

COMMIT;


