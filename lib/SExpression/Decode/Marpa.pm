package SExpression::Decode::Marpa;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use MarpaX::Simple qw(gen_parser);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(from_sexp);

my $parser = gen_parser(
    grammar => <<'EOF',
:default     ::= action => do_array

:start       ::= value

value        ::= string action => do_first
               | number action => do_first
               | pair action => do_first
               | list action => do_first
               | vector action => do_first
               | 't' action => do_true
               | 'f' action => do_false
               | 'nil' action => do_undef
               | atom action => do_first

atom          ~ [^\\\[\]\(\)\s".]+

pair          ::= ('(') value ('.') value (')')

vector        ::= ('[' ']')
               | ('[') list_elems_dot   (']') action => do_first
               | ('[') list_elems_nodot (']') action => do_first

list          ::= ('(' ')')
               | ('(') list_elems_dot   (')') action => do_first
               | ('(') list_elems_nodot (')') action => do_first

list_elems_nodot ::= value+
list_elems_dot   ::= list_elems_nodot ('.') value action => do_list_elems_dot

number         ~ int
               | int frac
               | int exp
               | int frac exp

int            ~ digits
               | '-' digits

digits         ~ [\d]+

frac           ~ '.' digits

exp            ~ e digits

e              ~ 'e'
               | 'e+'
               | 'e-'
               | 'E'
               | 'E+'
               | 'E-'

string ::= <string lexeme> action => do_string

<string lexeme> ~ quote <string contents> quote
# This cheats -- it recognizers a superset of legal JSON strings.
# The bad ones can sorted out later, as desired
quote ~ ["]
<string contents> ~ <string char>*
<string char> ~ [^"\\] | '\' <any char>
<any char> ~ [\d\D]

whitespace     ~ [\s]+
:discard       ~ whitespace

EOF
    actions => {
        do_array  => sub { shift; [@_] },
        do_hash   => sub { shift; +{map {@$_} @{ $_[0] } } },
        do_first  => sub { $_[1] },
        do_list_elems_dot  => sub { [@{ $_[1] }, $_[2]] },
        do_undef  => sub { undef },
        do_string => sub {
            shift;

            my($s) = $_[0];

            $s =~ s/^"//;
            $s =~ s/"$//;

            $s =~ s/\\u([0-9A-Fa-f]{4})/chr(hex($1))/eg;

            $s =~ s/\\n/\n/g;
            $s =~ s/\\r/\r/g;
            $s =~ s/\\b/\b/g;
            $s =~ s/\\f/\f/g;
            $s =~ s/\\t/\t/g;
            $s =~ s/\\\\/\\/g;
            $s =~ s{\\/}{/}g;
            $s =~ s{\\"}{"}g;

            return $s;
        },
        do_true   => sub { 1 },
        do_false  => sub { 0 },
    },
);

sub from_sexp {
    $parser->(shift);
}

1;
# ABSTRACT: S-expression parser using Marpa

=head1 SYNOPSIS

 use SExpression::Decode::Marpa qw(from_sexp);
 my $data = from_sexp(q|((foo . 1) (bar . 2))|); # => [[foo=>1], [bar=>2]]


=head1 DESCRIPTION


=head1 FUNCTIONS

=head2 from_sexp

Usage:

 my $data = from_sexp($str);

Decode S-expresion in C<$str>. Dies on error.


=head1 FAQ


=head1 SEE ALSO

L<Data::SExpression>, another S-expression parser based on L<Parse::Yapp>.

=cut
