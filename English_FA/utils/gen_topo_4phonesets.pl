#!/usr/bin/env perl

# Copyright 2012  Johns Hopkins University (author: Daniel Povey)

# Generate a topology file.  This allows control of the number of states in the
# non-silence HMMs, and in the silence HMMs.

if (@ARGV != 8) {
  print STDERR "Usage: utils/gen_topo.pl <num-nonsilence-states> <num-silence-states> <colon-separated-nonsilence-phones> <colon-separated-silence-phones>\n";
  print STDERR "e.g.:  utils/gen_topo.pl 3 5 4:5:6:7:8:9:10 1:2:3\n";
  exit (1);
}

($num_sil_states, $num_one_states, $num_three_states, $num_five_states, $sil_phones, $one_phones, $three_phones, $five_phones) = @ARGV;

#( $num_nonsil_states >= 1 && $num_nonsil_states <= 100 ) ||
#  die "Unexpected number of nonsilence-model states $num_nonsil_states\n";
#(( $num_sil_states == 1 || $num_sil_states >= 3) && $num_sil_states <= 100 ) ||
#  die "Unexpected number of silence-model states $num_sil_states\n";

$one_phones =~ s/:/ /g;
$three_phones =~ s/:/ /g;
$five_phones =~ s/:/ /g;
$sil_phones =~ s/:/ /g;
$one_phones =~ m/^\d[ \d]+$/ || die "$0: bad arguments @ARGV\n";
$three_phones =~ m/^\d[ \d]*$/ || die "$0: bad arguments @ARGV\n";
$five_phones =~ m/^\d[ \d]*$/ || die "$0: bad arguments @ARGV\n";
$sil_phones =~ m/^\d[ \d]*$/ || die "$0: bad arguments @ARGV\n";

# one-state phones
print "<Topology>\n";
print "<TopologyEntry>\n";
print "<ForPhones>\n";
print "$one_phones\n";
print "</ForPhones>\n";
for ($state = 0; $state < $num_one_states; $state++) {
  $statep1 = $state+1;
  print "<State> $state <PdfClass> $state <Transition> $state 0.75 <Transition> $statep1 0.25 </State>\n";
}
print "<State> $num_one_states </State>\n"; # non-emitting final state.
print "</TopologyEntry>\n";

# three-state phones
print "<Topology>\n";
print "<TopologyEntry>\n";
print "<ForPhones>\n";
print "$three_phones\n";
print "</ForPhones>\n";
for ($state = 0; $state < $num_three_states; $state++) {
    $statep1 = $state+1;
    print "<State> $state <PdfClass> $state <Transition> $state 0.75 <Transition> $statep1 0.25 </State>\n";
}
print "<State> $num_three_states </State>\n"; # non-emitting final state.
print "</TopologyEntry>\n";

# five-state phones
print "<Topology>\n";
print "<TopologyEntry>\n";
print "<ForPhones>\n";
print "$five_phones\n";
print "</ForPhones>\n";
for ($state = 0; $state < $num_five_states; $state++) {
    $statep1 = $state+1;
    print "<State> $state <PdfClass> $state <Transition> $state 0.75 <Transition> $statep1 0.25 </State>\n";
}
print "<State> $num_five_states </State>\n"; # non-emitting final state.
print "</TopologyEntry>\n";

# Now silence phones.  They have a different topology-- apart from the first and
# last states, it's fully connected, as long as you have >= 3 states.

if ($num_sil_states > 1) {
  $transp = 1.0 / ($num_sil_states-1);
  print "<TopologyEntry>\n";
  print "<ForPhones>\n";
  print "$sil_phones\n";
  print "</ForPhones>\n";
  print "<State> 0 <PdfClass> 0 ";
  for ($nextstate = 0; $nextstate < $num_sil_states-1; $nextstate++) { # Transitions to all but last
    # emitting state.
    print "<Transition> $nextstate $transp ";
  }
  print "</State>\n";
  for ($state = 1; $state < $num_sil_states-1; $state++) { # the central states all have transitions to
    # themselves and to the last emitting state.
    print "<State> $state <PdfClass> $state ";
    for ($nextstate = 1; $nextstate < $num_sil_states; $nextstate++) {
      print "<Transition> $nextstate $transp ";
    }
    print "</State>\n";
  }
  # Final emitting state (non-skippable).
  $state = $num_sil_states-1;
  print "<State> $state <PdfClass> $state <Transition> $state 0.75 <Transition> $num_sil_states 0.25 </State>\n";
  # Final nonemitting state:
  print "<State> $num_sil_states </State>\n";
  print "</TopologyEntry>\n";
} else {
  print "<TopologyEntry>\n";
  print "<ForPhones>\n";
  print "$sil_phones\n";
  print "</ForPhones>\n";
  print "<State> 0 <PdfClass> 0 ";
  print "<Transition> 0 0.75 ";
  print "<Transition> 1 0.25 ";
  print "</State>\n";
  print "<State> $num_nonsil_states </State>\n"; # non-emitting final state.
  print "</TopologyEntry>\n";
}

print "</Topology>\n";
