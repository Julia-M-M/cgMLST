#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Getopt::Long;

my ( $dir, $DEBUG, $filename );

GetOptions(
    'd|dir|directory=s'  => \$dir,
    'db|debug'   => \$DEBUG
);
if (!defined $dir){
	$dir = '.';
	
}
#Shorter way to write this is:
#$dir //= '.';
#my $DEBUG = 1;
#my $dir = 'ABA_targets';

#Get a list of filenames from directory
my @locus = glob("$dir/*") or die "ERROR $!";

# Output this tab-delimited text in format: locus	allele_id	sequence
# Open each file in turn and read first sequence (it is the one after ">1")
say "locus\tallele_id\tsequence\tstatus";

my @targets = glob("$dir/*") or die "ERROR $!";
foreach my $targets (@targets) {
	my $flag = 0;
	open( my $fh, '<', $targets ) or die "ERROR $!";

	while ( my $sequence = <$fh> ) {
		chomp($sequence);

		if ( $sequence eq "" ) {
			next;
		}

		if ( $sequence =~ /^>1/ ) {
			$flag = 1;
			next;
		}

		if ( $flag == 1 ) {
			my $locus_name = rename_locus($targets);

			if ( !is_cds($sequence) ) {

				if ($DEBUG) {
					say
"Testing: $locus_name needs reverse_complementing: $sequence";
					exit;
				}
				$sequence = reverse_complement($sequence);

				if ( !is_cds($sequence) ) {
					die "Locus $locus_name is still not CDS!\n";
				}
			}
			say "$locus_name\t1\t$sequence\tunchecked";
			last;
		}
	}
}

# Rename locus files from ACICU_RSxxxxx to ACINxxxxx
sub rename_locus {
	my ($path) = @_;
	$path =~ s/.fasta//;
	$path =~ s/ABA_targets\/ACICU_RS/ACIN/;
	return $path;
}

#Return 1 if a complete coding sequence
sub is_cds {
	my ($seq) = @_;

	#Check and return null if no start codon
	if ( uc($seq) !~ /^(GTG|TTG|CTG|ATT|ATC|ATA|ATG|GTA)/ ) {
		return;
	}

	#Check and return null for no stop codon
	if ( uc($seq) !~ /(TAA|TGA|TAG)$/ ) {
		return;
	}

	return 1;
}

sub reverse_complement {
	my ($seq) = @_;

	#Reverse-complement sequence
	$seq = reverse($seq);
	$seq =~ tr/ATGCatgc/TACGtacg/;

	return $seq;
}
