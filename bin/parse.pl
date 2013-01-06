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
  if (my $details = get_details($data)) {
    $data->{details} = $details;
  }
  print Dumper($data);
}

# make sure we reached the end of the file
unless ( $csv->eof() ) {
  die sprintf "Parse Error: input=%s, error_diag=%s\n",
    $csv->error_input(), $csv->error_diag();
}

exit 0;


sub get_details {
  my $p = shift;

  # run play
  $p->{description} =~ m{
    ^
    \((?<clock>\d{0,2}:\d{2})\)\s+
    (?<carrier>\w\.[\w-]+)\s+
    (?:
      (?<side>left|right)\s+
      (?<direction>guard|tackle|end)|(?:up the (?<side>middle))
    )\s+
    to\s+(?<team>\w{3})\s+
    (?<yardline>\d+)\s+
    for\s+(?<yards>-?\d+)\s+yards?\s+
    \((?<tacklers>(\s?\w\.[\w-]+)+)\)\.
    \s*(?<extra>.*)
    $
  }x;

  if (scalar (keys %+)) {
    my %details = (
                   type => 'run',
                   clock => $+{clock},
                   carrier => $+{carrier},
                   side => $+{side},
                   direction => $+{direction},
                   team => $+{team},
                   yardline => $+{yardline},
                   yards => $+{yards},
                   tacklers => [ split(/\s+/, $+{tacklers}) ],
                   extra => $+{extra},
                  );

    return \%details;

    my $extra = $+{extra};
    # parse the extra info here
    # 'extra' => 'FUMBLES (S.Lee) RECOVERED by DAL-B.Church at DAL 28. B.Church to DAL 34 for 6 yards (C.Snee). Officially a rush for 1 yard.',
    # 'extra' => 'PENALTY on DAL-D.Bryant Illegal Motion 5 yards enforced at NYG 24 - No Play.',
  }
  return undef;
}


sub usage {
  my $error = shift;
  my $message;
  if (defined $error) {
    $message = "ERROR: $error\n";
  }
  $message .= " Usage: $0 --file DATAFILE\n";
  return $message;
}
