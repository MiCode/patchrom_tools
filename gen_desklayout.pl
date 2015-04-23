#!/usr/bin/perl

use strict;

my ($sedfile, $outdir) = @ARGV;

my %sed;

#double check if the file exists
if ( not -f $sedfile ) {
    print "sedfile does not exist\n";
    exit;
}

open(SED, $sedfile);
while (<SED>) {
    if (/^\s*([^\s]+)\/([^\s]+)\s*=\s*([^\s]+)\/([^\s]+)\s*$/) {
        $sed{$1} = $3;
        $sed{$2} = $4;
    }
}
close(SED);

my @deskfiles=<$outdir/default_workspace*.xml>;

my $sedstr = "sed ";
foreach my $key (keys %sed) {
#print stderr "$key => $sed{$key} \n";
    $sedstr .= "-e s/\\\"$key\\\"/\\\"$sed{$key}\\\"/g ";
}

foreach my $file (@deskfiles) {
    system("$sedstr $file > $file.new");
}
