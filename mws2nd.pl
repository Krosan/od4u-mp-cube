#!/usr/bin/perl -w

#Author: Rutilio

use strict;
use Getopt::Long;
use File::Basename;

my $USAGE =
qq{mws2nd.pl -i <input_file> [-o <output file>] [-m <mythic_symbol>] [-n <number>]

Where:
input_file:    MWS spoiler file name (MTGSalvation format).
ouput_file:    Netdraft output file name (Optional). Default <input_file>.nd
mythic_symbol: Spoiler mythic identifier (Optional). If it contains mythic cards, rares will be duplicated. Default M.
number:        How many times rares will be duplicated (Optional). Default 2.

Example: perl mws2nd.pl -i Conflux.txt -m M -n 2  
};

my $MWS_SPOILER;
my $ND_FILE;
my $index = -1;
my $input;
my $output;
my $m_symbol = 'M';
my $number   = '2';

GetOptions(
	"i=s" => \$input,
	"o=s" => \$output,
	"m=s" => \$m_symbol,
	"n=i" => \$number
) or die $USAGE;

if (!defined $input) {
	print $USAGE;
	exit(1);
}

if (!defined $output) {
	$output = (fileparse($input,'\..*'))[0] . '.nd';
}

open $MWS_SPOILER, '<', $input  or die "Unable to open file: $input";
open $ND_FILE,     '>', $output or die "Unable to create file: $output";

write_nd_file($ND_FILE, read_mws_spoiler($MWS_SPOILER), $m_symbol, 'R',
	$number);

close $MWS_SPOILER;
close $ND_FILE;

exit(0);

#MWS Format example:
# Card Name:	Aerie Mystics
# Card Color:	W
# Mana Cost:	4W
# Type & Class:	Creature - Bird Cleric
# Pow/Tou:	3/3
# Card Text:	Flying  %1%G%U, %T: Creatures you control gain shroud until end of turn.
# Flavor Text:
# Artist:
# Rarity:		U
# Card #:		1/145
sub read_mws_spoiler {
	my ($MWS_FH) = @_;
	my @card_list;

	while (my $line = <$MWS_FH>) {
		chop $line;
		if ($line =~ /^Card Name:\s+(.+)$/) {
			$index++;
			$card_list[$index]{name} = $1;
		}
		elsif ($line =~ /^Card Color:\s+(.+)$/) {
			$card_list[$index]{color} = $1;
		}
		elsif ($line =~ /^Mana Cost:\s+(.+)$/) {
			$card_list[$index]{cost} = $1;
		}
		elsif ($line =~ /^Type & Class:\s+(.+)$/) {
			$card_list[$index]{type} = $1;
		}
		elsif ($line =~ /^Pow\/Tou:\s+(.+)$/) {
			$card_list[$index]{pow_tou} = $1;
		}
		elsif ($line =~ /^Card Text:\s+(.+)$/) {
			$card_list[$index]{text} = $1;
		}
		elsif ($line =~ /^Rarity:\s+(.+)$/) {
			$card_list[$index]{rarity} = $1;
		}
	}
	return \@card_list;
}

sub write_nd_file {
	my ($ND_FH, $card_list, $mythic_symbol, $duplicate_symbol, $times) = @_;

	my $has_mythics = has_mythics($card_list, $mythic_symbol);

	binmode $ND_FH;
	write_nd_header($ND_FH);

	foreach my $card (@{$card_list}) {
		my $counter = 0;
		do {
			write_nd_field($ND_FH, $card->{name}, 1);
			write_nd_field(
				$ND_FH,
				get_nd_rarity(
					$card->{rarity}, $mythic_symbol, $duplicate_symbol
				),
				0
			);
			write_nd_field($ND_FH, get_nd_color($card->{color}), 0);
			write_nd_field($ND_FH, $card->{cost},                1);
			write_nd_field($ND_FH, $card->{type},                1);
			write_nd_field($ND_FH, get_nd_text($card->{text}),   1);
			write_nd_field($ND_FH, $card->{pow_tou},             1);
		  } while ($has_mythics == 1
			and $card->{rarity} eq $duplicate_symbol
			and ++$counter < $times);
	}
	write_nd_tail($ND_FILE);
}

sub has_mythics {
	my ($list, $symbol) = @_;

	foreach my $card (@{$list}) {
		return 1 if ($card->{rarity} eq $symbol);
	}
	return 0;
}

sub write_nd_header {
	my ($ND_FH) = @_;
	print {$ND_FH} "\1\0\3\0\12\0";
	return;
}

sub write_nd_field {
	my ($ND_FH, $field_value, $is_string) = @_;
	$field_value = (defined $field_value ? $field_value : '');
	my $length = $is_string ? length($field_value) + 1 : length($field_value);
	print {$ND_FH} chr($length & 0xFF), chr($length >> 8);
	print {$ND_FH} "$field_value";
	if ($is_string == 1) {
		print {$ND_FH} "\0";
	}
	return;
}

sub write_nd_tail {
	my ($ND_FH) = @_;
	print {$ND_FH} "\3\0END\1\0.\1\0.\0\0\0\0\0\0\0\0";
	return;
}

sub get_nd_rarity {
	my ($rarity, $mythic, $duplicate) = @_;
	$rarity =~ s/R/+/;
	$rarity =~ s/U/=/;
	$rarity =~ s/C/-/;
	if ($duplicate eq 'R') {
		$rarity =~ s/$mythic/+/;
	}
	elsif ($duplicate eq 'U') {
		$rarity =~ s/$mythic/=/;
	}
	else {
		$rarity =~ s/$mythic/-/;
	}
	return $rarity;
}

sub get_nd_text {
	my ($text) = @_;
	return $text unless (defined $text);
	$text =~ s/\%//g;
	$text =~ s/\s{2}/\n/g;
	return $text;
}

sub get_nd_color {
	my ($color) = @_;
	$color =~ s/Gld/M/;
	$color =~ s/Art/A/;
	$color =~ s/Lnd/L/;
	return $color;
}
