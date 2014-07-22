package InlineX::C2XS::Context;

use strict;
use warnings;

our $VERSION = '0.23';

sub apply_context_args_blindly {

  # $_[0]: The XS file to which we want to apply the context args (aTHX, aTHX_, pTHX, pTHX_).
  # $_[1]: A reference to a list/array of the functions to which we *don't* want to apply
  #        the context args.
  # $_[2]: A reference to a list/array of the C functions that get called by other C functions
  #        in the XS file.

  die "Usage: InlineX::C2XS::Context::apply_context_args(\$xs_file, \\\@exclusions, \\\@called)"
    unless @_ == 3;

  open RD, '<', $_[0] or die $!;
  my @xs = <RD>;
  open WR, '>', $_[0] or die $!;

  my($aTHX_warn, $pTHX_warn) = (0, 0);

  for(@xs) {
    $pTHX_warn = 1 if $_ =~ /pTHX/;
    $aTHX_warn = 1 if $_ =~ /aTHX/;
  }

  warn "Potential problem: the string 'aTHX' was found in $_[0]"
    if $aTHX_warn;

  warn "Potential problem: the string 'pTHX' was found in $_[0]"
    if $pTHX_warn;

  for(my $i = 1; $i < @xs; $i++) {

    if($xs[$i] =~ /^(\s+)?void/) {
      unless(exclude($xs[$i], $_[1])) {
        if($xs[$i] =~ /\((\s+)?void(\s+)?\)/) { $xs[$i] =~ s/\((\s+)?void(\s+)?\)/(pTHX)/ }
        elsif($xs[$i] =~ /\((\s+)?\)/) { $xs[$i] =~ s/\((\s+)?\)/(pTHX)/ }
        else { $xs[$i] =~ s/\(/\(pTHX_ / }
      }
    }

    if($xs[$i] =~ /temp = PL_markstack_ptr\+\+;/) {
      unless(exclude($xs[$i + 1], $_[1])) {
        $xs[$i + 1] =~ /\(\)/ ? $xs[$i + 1] =~ s/\(/\(aTHX/
                              : $xs[$i + 1] =~ s/\(/\(aTHX_ /
      }
    }
  }

  for(my $i = 1; $i < @xs; $i++) {

    if($xs[$i] =~ /^(\s+)?SV \* /) {
       $xs[$i] !~ /\(void\)/ ? $xs[$i] =~ s/\(/\(pTHX_ /
                             : $xs[$i] =~ s/\(void\)/\(pTHX\)/;
    }


    if(
       $xs[$i] =~ /^(A|H|S)V \*\n/
       ) {
      my $function = $xs[$i + 1];
      chomp $function;
      my $jump = scalar(split /,/, $xs[$i + 1]);
      if($xs[$i + 1] !~ /\(\)/) {$function =~ s/\(/\(aTHX_ /}
      else {
        $function =~ s/\(\)/\(aTHX\)/;
        $jump--;
      }
      $function .= ';';
      unless($xs[$i + 2 + $jump] =~ /\S/) {
        $xs[$i + 2 + $jump] = "CODE:\n  RETVAL = $function\nOUTPUT:  RETVAL\n\n";
      }
      else { warn "$i: $xs[$i + 2 + $jump]\n"}
    }
  }

  # The following can break if $f appears in comments.
  for my $f (@{$_[2]}) {
    my $seen_pthx = 0;
    for(my $i = 1; $i < @xs; $i++) {
      if($seen_pthx) {
        $xs[$i] =~ s/\b$f(\s+)?\((\s+)?\)/$f(aTHX)/
          unless $xs[$i] =~ /^$f\b/;   # XS section - we don't want aTHX/aTHX_ here.
        $xs[$i] =~ s/\b$f(\s+)?\(/$f(aTHX_ /
          unless ($xs[$i] =~ /aTHX|pTHX/
                  ||
                  $xs[$i] =~ /^$f\b/); # XS section - we don't want aTHX/aTHX_ here.
      }
      else {
        if($xs[$i] =~ /\b$f\b/ && $xs[$i] =~ /\bpTHX\b|\bpTHX_\b/) {
          $seen_pthx = 1;
          next;
        }
        $seen_pthx = 1 if $xs[$i] =~ /\b$f(\s+)?\(/;
        $xs[$i] =~ s/\b$f(\s+)?\((\s+)?(void)(\s+)?\)/$f(pTHX)/;
        $xs[$i] =~ s/\b$f(\s+)?\(/$f(pTHX_ /;
      }
    }
  }

  for(@xs) {print WR $_}

  close WR or die $!;

  print "$_[0] has been rewritten for PERL_NO_GET_CONTEXT\n";

}

###################################
###################################

sub apply_context_args {

  # $_[0]: The XS file to which we want to apply the context args (aTHX, aTHX_, pTHX, pTHX_).
  # $_[1]: A reference to a list/array of the C functions to which we wish to apply the
  #        context args.

  die "Usage: InlineX::C2XS::Context::apply_context_args(\$xs_file, \\\@functions)"
    unless @_ == 2;

  open RD, '<', $_[0] or die $!;
  my @xs = <RD>;
  open WR, '>', $_[0] or die $!;

  my($aTHX_warn, $pTHX_warn) = (0, 0);

  for(@xs) {
    $pTHX_warn = 1 if $_ =~ /pTHX/;
    $aTHX_warn = 1 if $_ =~ /aTHX/;
  }

  warn "Potential problem: the string 'aTHX' was found in $_[0]"
    if $aTHX_warn;

  warn "Potential problem: the string 'pTHX' was found in $_[0]"
    if $pTHX_warn;

  for my $f(@{$_[1]}) {
    my $seen_pthx = 0;
    for(my $i = 1; $i < @xs; $i++) {

      if($xs[$i] =~ /.+\b$f\b(\s+)?\(/ && !$seen_pthx) {
         $xs[$i] !~ /\((\s+)?(void)?(\s+)?\)/
                    ? $xs[$i] =~ /(a|p)THX/ ? $xs[$i] = $xs[$i]
                                            : $xs[$i] =~ s/\(/\(pTHX_ /
                    : $xs[$i] =~ s/\((\s+)?(void)?(\s+)?\)/\(pTHX\)/;
         $seen_pthx = 1 if $xs[$i] =~ /pTHX/;
      }


      if(
         (
         $xs[$i] =~ /^(S|H|A)V \*\n/ ||
         $xs[$i] =~ /^(signed |unsigned )?(long)?\s?int(\s\*)?\n/ ||
         $xs[$i] =~ /^(long)?\s?double(\s\*)?\n/ ||
         $xs[$i] =~ /^(signed |unsigned )?long(\s\*)?\n/
         )
         && $xs[$i + 1] =~ /^$f\b/
        ) {
        my $function = $xs[$i + 1];
        chomp $function;
        my $jump = scalar(split /,/, $xs[$i + 1]);
        if($xs[$i + 1] !~ /\(\)/) {$function =~ s/\(/\(aTHX_ /}
        else {
          $function =~ s/\(\)/\(aTHX\)/;
          $jump--;
        }
        $function .= ';';
        unless($xs[$i + 2 + $jump] =~ /\S/) {
          $xs[$i + 2 + $jump] = "CODE:\n  RETVAL = $function\nOUTPUT:  RETVAL\n\n";
        }
        else { warn "$i: $xs[$i + 2 + $jump]\n"}
      }
    }
  }

  # The following can break if $f appears in comments.
  for my $f (@{$_[1]}) {
    my $seen_pthx = 0;
    for(my $i = 1; $i < @xs; $i++) {
      if($seen_pthx) {
        $xs[$i] =~ s/\b$f(\s+)?\((\s+)?\)/$f(aTHX)/
          unless $xs[$i] =~ /^$f\b/;   # XS section - we don't want aTHX/aTHX_ here.
        $xs[$i] =~ s/\b$f(\s+)?\(/$f(aTHX_ /
          unless ($xs[$i] =~ /aTHX|pTHX/
                  ||
                  $xs[$i] =~ /^$f\b/); # XS section - we don't want aTHX/aTHX_ here.
      }
      else {
        if($xs[$i] =~ /\b$f\b/ && $xs[$i] =~ /\bpTHX\b|\bpTHX_\b/) {
          $seen_pthx = 1;
          next;
        }
        $seen_pthx = 1 if $xs[$i] =~ /\b$f(\s+)?\(/;
        $xs[$i] =~ s/\b$f(\s+)?\((\s+)?(void)(\s+)?\)/$f(pTHX)/;
        $xs[$i] =~ s/\b$f(\s+)?\(/$f(pTHX_ /
          unless $xs[$i] =~ /(p|a)THX/;
      }
    }
  }

  for(@xs) {print WR $_}

  close WR or die $!;

  print "$_[0] has been rewritten for PERL_NO_GET_CONTEXT\n";

}

###################################
###################################

sub exclude {
  my @exclusions = @{$_[1]};

  for(@exclusions) {
    return 1 if $_[0] =~ /$_/;
  }
  return 0;
}

1;
