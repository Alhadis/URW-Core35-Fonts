#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use v5.14;
use utf8;
$| = 1;

use warnings  qw< FATAL utf8 >;
use open      qw< :std :utf8 >;
use charnames qw< :full >;
use feature   qw< say unicode_strings >;
use Carp      qw< confess >;

use File::Basename qw< basename >;
use File::Spec::Functions;
use HTML::Entities;
use Getopt::Long;

END { close STDOUT }
local $SIG{__DIE__} = sub {
	confess "Uncaught exception: @_" unless $^S;
};


my $defaultWeight = 400;

# Resolve a CSS font-weight keyword to its numeric value
sub getWeight {
	my %weights = (
		100 => ["thin", "hairline"],
		200 => ["extralight", "ultralight"],
		300 => ["light"],
		400 => ["normal"],
		500 => ["medium"],
		600 => ["semi", "semibold", "demi", "demibold"],
		700 => ["bold"],
		800 => ["extrabold", "ultrabold"],
		900 => ["black", "heavy"]
	);
	(my $input = lc shift) =~ s/[-\s]+//g;
	for (keys %weights){
		return $_ if grep { $input eq $_ } @{$weights{$_}};
	}
	return $defaultWeight;
}

# Load a font's metadata and supported character set from its corresponding AFM file
sub loadFontInfo {
	my $ttfFile = shift;
	my @charset = ();
	my %fontInfo = (family => "", fullName => "", charset => \@charset, styleAttr => "");
	(my $afmFile = $ttfFile) =~ s/\.ttf$/\.afm/i;
	open(my $fh, "< :encoding(UTF-8)", $afmFile) or die "Can't open AFM file: $!";
	
	while(<$fh>){
		last if m/^EndCharMetrics$/;
		$fontInfo{fullName} = $1 if m/^FullName\s+(\S.*)$/;
		$fontInfo{family}   = $1 if m/^FamilyName\s+(\S.*)$/;
		$fontInfo{family}   =~ s/^Nimbus\K(?=Sans$)/ /;
		if(m/^Weight\s+(\S+)/){
			my $weight = getWeight($1);
			$fontInfo{weight} = $weight unless $weight == $defaultWeight;
			$fontInfo{styleAttr} .= "font-weight: $weight; ";
		}
		if(m/^ItalicAngle\s+(-?\d+(?:\.\d+)?)\s*$/ and $1 != 0){
			my $oblique = $fontInfo{fullName} =~ m/(?:^|\s)Oblique(?:\s|$)/i;
			$fontInfo{style} = $oblique ? "oblique" : "italic";
			$fontInfo{styleAttr} .= "font-style: $fontInfo{style}; ";
		}
		push @charset, $1 if m/^C\h+([0-9]+)\h+;.*?;\h+N\h+\w+\h+;/;
	}
	close $fh;
	$fontInfo{styleAttr} =~ s/; $//;
	$fontInfo{styleAttr} =~ s/font-weight:\s*\K700/bold/;
	return %fontInfo;
}

# Encode "unsafe" HTML characters as named entities
sub esc {
	return encode_entities shift || "", '<>"&';
}

# Reorder a string depicting a font's character-set to list alphanumerics first
sub sortPreview {
	my $chars = shift;
	my $class = join "", map { quotemeta chr } @$chars;
	my $missing = qr/[^$class]/;
	my $output = join "", "A".."Z", " ", "a".."z", " ", "0".."9";
	$output =~ s/$missing//g;
	($chars = join "", map { chr } @$chars) =~ s/[A-Za-z0-9]|\P{Graph}|\xAD//g;
	return "$output $chars";
}


# Open each file we'll be writing to
my $cssFile  = "";
my $htmlFile = "";
GetOptions("h|html-file=s" => \$htmlFile, "c|css-file=s" => \$cssFile);

open(CSS,   "> :encoding(UTF-8)", $cssFile)  or die "Can't open CSS file: $!";
open(HTML, "+< :encoding(UTF-8)", $htmlFile) or die "Can't open HTML file: $!";
while(<HTML>){ last if m/^<body[^>]*>\s*$/; }
truncate *HTML, tell;

my $prev = "";
for (@ARGV) {
	my $file = canonpath $_;
	my %font = loadFontInfo $file;
	my $name = esc $font{fullName};
	my $family = $font{family};
	my $quotedFamily = ($family =~ m/[^-\w]/) ? qq("$family") : $family;
	
	# Begin new font-family
	if($prev ne $family){
		if($prev){
			print CSS "\n\n";
			print HTML "\t</article>\n\n";
		}
		print CSS "/* $family */\n";
		$prev = $family;
		(my $idAttr = $family) =~ s/\W//g;
		my $styleAttr = esc $quotedFamily;
		print HTML join "\n\t\t", (
			qq(\t<article style="font-family: $styleAttr" id="$idAttr">),
			"<h2>".esc($family)."</h2>\n",
		);
	}
	
	# Append new @font-face to stylesheet
	(my $woff2File  = $file) =~ s!source/(.+)\.ttf$!fonts/$1.woff2!i;
	(my $ruleWeight = $font{weight} || "normal") =~ s/700$/bold/;
	(my $ruleStyle  = $font{style}  || "normal");
	print CSS (join "\n\t", "\@font-face {",
		"font-family: $quotedFamily;",
		"font-weight: $ruleWeight;",
		"font-style: $ruleStyle;",
		qq<src: url("$woff2File") format("woff2");>,
	)."\n}\n";

	# Append to current HTML section
	(my $style = esc $font{styleAttr}) =~ s/font-weight:\s+400;?\s*//;
	print HTML join "", (
		"\n\t\t<h3>$name</h3>\n\t\t",
		($style ? qq(<p style="$style">) : "<p>"),
		esc(sortPreview $font{charset}),
		"</p>\n"
	);
}

# Finish up by adding closing tags to HTML preview
print HTML "\t</article>\n</body>\n</html>\n";
close HTML;
close CSS;
