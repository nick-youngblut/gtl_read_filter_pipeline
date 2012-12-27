#!/usr/bin/env perl

### modules
use strict;
use warnings;
use Pod::Usage;
use Data::Dumper;
use Getopt::Long;
use File::Spec;

### args/flags
pod2usage("$0: No files given.") if ((@ARGV == 0) && (-t STDIN));

my ($verbose, $min_len, $format);
GetOptions(
	   "format=s" => \$format, 			# read format
	   "minimum=i" => \$min_len,			# homopolymer min length
	   "verbose" => \$verbose,
	   "help|?" => \&pod2usage # Help
	   );

### I/O error & defaults
$format = "fastq" if ! $format;
die " ERROR: format must be fasta or fastq\n" if $format !~ /fasta|fastq/i;
$min_len = 4 if ! $min_len;

### MAIN
my ($pos_cnt_ref, $max_read_len, $read_cnt) = find_homopolymers($min_len, $format);
write_homopolymer_dist($pos_cnt_ref, $max_read_len, $read_cnt);

### Subroutines
sub write_homopolymer_dist{
	my ($pos_cnt_ref, $max_read_len, $read_cnt) = @_;

	print join("\t", qw/Position Count Count_norm/), "\n";
	for my $i (0..$max_read_len - 1){
		$$pos_cnt_ref[$i] = 0 if ! $$pos_cnt_ref[$i];
		print join("\t", $i, $$pos_cnt_ref[$i], $$pos_cnt_ref[$i] / $read_cnt), "\n";
		}
	
	}
	
sub find_homopolymers{
	my ($min_len, $format) = @_;

	# format-specific #
	my @line_skip;	
	if($format =~ /fastq/i){ @line_skip = (2, 3, "@"); }
	elsif($format =~ /fasta/i){ @line_skip = (0, 1, ">"); }
	else{ die " ERROR: wrong format\n"; }
	
	# file processing #
	my @pos_cnt;		# position count of homopolymers
	my $max_read_len = 0;
	my $read_cnt = 0;
	while(<>){
		chomp;
		die " ERROR: read file not formated in $format format!\n"
			if ($.+ $line_skip[1]) % 4 == 0 && $_ !~ /^$line_skip[2]/;
		next if ($.+ $line_skip[0]) % 4 != 0;				# just sequence
		while ($_ =~ /A{$min_len,}|C{$min_len,}|G{$min_len,}|T{$min_len,}/gi){
			for my $i ($-[0]..$+[0] -1){
				$pos_cnt[$i]++;
				}
			my $read_len = length($_);
			$max_read_len = $read_len if $read_len > $max_read_len;
			
			$read_cnt++;
			}
			#$proc_cnt++;
			#print STDERR " $proc_cnt reads processed\n" if $proc_cnt % 1000 == 0 && $verbose;
		}
	
	return (\@pos_cnt, $max_read_len, $read_cnt);
	}

__END__

=pod

=head1 NAME

homopolymer_dist.pl -- get the distribution of homopolymers in a set of reads

=head1 SYNOPSIS

homopolymer_dist.pl [options] < input > output

=head2 options

=over

=item -f 	Format (fasta | fastq). [fastq]

=item -m 	Minimum homopolymer length. [4]

=item -h	This help message

=back

=head2 For more information:

perldoc homopolymer_dist.pl

=head1 DESCRIPTION

Find the distribution of homopolymers at each position in a set of reads (fasta or fastq format).

Only [ACGT] homopolymers are searched for.

The output is 3 column format:

=over

=item column 1)	Read position

=item column 2)	Number of times that position was part of a homopolymer

=item column 3) Same as column 2, but normalized by number of reads.

=head1 EXAMPLES

=head1 AUTHOR

Nick Youngblut <nyoungb2@illinois.edu>

=head1 AVAILABILITY

sharchaea.life.uiuc.edu:/home/git/gtl_read_filter_pipeline

=head1 COPYRIGHT

Copyright 2010, 2011
This software is licensed under the terms of the GPLv3

=cut

