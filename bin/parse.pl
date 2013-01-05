#!/usr/bin/env perl

use strict;
use warnings;

use Text::CSV;
use Data::Dumper;
use Getopt::Long;

my($help, $file);
GetOptions(
           'help'   => \$help,
           'file=s' => \$file,
          ) or die "invalid param(s)\n";

if ($help) {
  print usage();
  exit 0;
}

unless (defined $file) {
  die usage("file not specified");
}

my $csv = Text::CSV->new({
                          binary => 1, 
                          allow_loose_quotes => 1,
                         });

open my $fh, '<', $file or die "can't open file $file for reading: $!\n";

# the first line of the CSV data file is a header containing the field names
$csv->column_names($csv->getline($fh));

# header fields: 2002-2011
# gameid,qtr,min,sec,off,def,down,togo,ydline,description,offscore,defscore,season

# header fields: 2012
# gameid,qtr,min,sec,off,def,down,togo,ydline,scorediff,series1stdn,description,scorechange,nextscore,teamwin,offscore,defscore,season

while (my $data = $csv->getline_hr($fh)) {
  print Dumper($data);
}

# make sure we reached the end of the file
unless ( $csv->eof() ) {
  die sprintf "Parse Error: input=%s, error_diag=%s\n",
    $csv->error_input(), $csv->error_diag();
}

exit 0;


sub usage {
  my $error = shift;
  my $message;
  if (defined $error) {
    $message = "ERROR: $error\n";
  }
  $message .= " Usage: $0 --file DATAFILE\n";
  return $message;
}
