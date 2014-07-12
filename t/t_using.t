use warnings;
use strict;
use InlineX::C2XS qw(c2xs);

print "1..8\n";

c2xs('parsertest', 'parsertest', '.',
     {
     _TESTING => 1,
     CODE => 'void greet() { printf("Hello World\n"); }',
     }
    );

c2xs('parsertest', 'parsertest', '.',
     {
     _TESTING => 1,
     USING => 'ParseRegExp',
     CODE => 'void greet() { printf("Hello World\n"); }',
     }
    );

c2xs('parsertest', 'parsertest', '.',
     {
     _TESTING => 1,
     #USING => 'ParseRegExp', # Still uses ParseRegExp
     CODE => 'void greet() { printf("Hello World\n"); }',
     }
    );

c2xs('parsertest', 'parsertest', '.',
     {
     _TESTING => 1,
     USING => 'ParseRecDescent',
     CODE => 'void greet() { printf("Hello World\n"); }',
     }
    );

c2xs('parsertest', 'parsertest', '.',
     {
     _TESTING => 1,
     CODE => 'void greet() { printf("Hello World\n"); }',
     }
    );

c2xs('parsertest', 'parsertest', '.',
     {
     _TESTING => 1,
     USING => 'ParseRegExp',
     CODE => 'void greet() { printf("Hello World\n"); }',
     }
    );

open RD, '<', '_Inline_test/parser_id' or warn "Unable to locate _Inline_test/parser_id: $!";

my @s = <RD>;

close RD or warn "Unable to close _Inline_test/parser_id: $!";

Inline::C::_testing_cleanup();
if(!unlink('parsertest.xs')) {warn "Unable to unlink parsertest"}

my $size = scalar(@s);
my $expected_size = 7;

if($size == $expected_size) {print "ok 1\n"}
else {
  warn "Expected $expected_size lines\nGot $size lines\n";
  print "not ok 1\n";
}


if($s[0] eq "Inline::C::get_parser called\n") {print "ok 2\n"}
else {
  warn "\$s[0]: $s[0]\n";
  print "not ok 2\n";
}

if($s[1] eq "Inline::C::ParseRecDescent::get_parser called\n") {print "ok 3\n"}
else {
  warn "\$s[1]: $s[1]\n";
  print "not ok 3\n";
}

if($s[2] eq "Inline::C::ParseRegExp::get_parser called\n") {print "ok 4\n"}
else {
  warn "\$s[2]: $s[2]\n";
  print "not ok 4\n";
}


if($s[3] eq "Inline::C::ParseRegExp::get_parser called\n") {print "ok 5\n"}
else {
  warn "\$s[3]: $s[3]\n";
  print "not ok 5\n";
}

if($s[4] eq "Inline::C::ParseRecDescent::get_parser called\n") {print "ok 6\n"}
else {
  warn "\$s[4]: $s[4]\n";
  print "not ok 6\n";
}

if($s[5] eq "Inline::C::ParseRecDescent::get_parser called\n") {print "ok 7\n"}
else {
  warn "\$s[5]: $s[5]\n";
  print "not ok 7\n";
}

if($s[6] eq "Inline::C::ParseRegExp::get_parser called\n") {print "ok 8\n"}
else {
  warn "\$s[6]: $s[6]\n";
  print "not ok 8\n";
}

