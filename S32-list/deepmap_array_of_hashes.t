use v6;

use Test;

plan 11;

=begin description

This test tests C<deepmap> on an array of hash structure.

It looks at the case where the given code block doesn't explicitly handle each element.

See: 
  https://github.com/rakudo/rakudo/issues/4435


=end description

my $test_case = "Add 10 if Numeric";

my @initial_data = ( { quant => 1, name => 'alpha', },
                     { quant => 2, name => 'beta',  },
                     { quant => 3, name => 'gamma', },
                     { quant => 4, name => 'delta', }, );

## Keeping the non-numeric elements unchanged 
my @expected1 = ( { quant => 11, name => 'alpha', },
                  { quant => 12, name => 'beta',  },
                  { quant => 13, name => 'gamma', },
                  { quant => 14, name => 'delta', }, );

## Dropping the non-numeric elements
my @expected2 = ( { quant => 11, },
                  { quant => 12, },
                  { quant => 13, },
                  { quant => 14, }, );

{
  my @data = @initial_data;

  ## Adds 10 to each Numeric and explicitly passes through everything else
  my @new_data = @data.deepmap({$_ ~~ Numeric ?? $_+10 !! $_ });

  is-deeply @new_data, @expected1, "Testing $test_case with explicit handling of all values" ;
}

{
  my @data = @initial_data;

  ## Adds 10 to each Numeric, does not specify what to do otherwise
  my @new_data = @data.deepmap({ $_+10 if $_ ~~ Numeric });

  ## my reading of docs is that it should *drop* elements untouched by &block:
  ##   https://docs.raku.org/routine/deepmap
  ##   "deepmap will apply &block to each element and return a new List with the return values of &block ..."

  is-deeply @new_data, @expected2, "Testing $test_case without explicit handling of all values" ;

  ## Should never see a result like this, where "name" key is used with Numeric:
  ##   [{quant => 11} {name => 12} {name => 13} {quant => 14}]

  my @quant = @new_data.map({ $_<quant> });
  my @name  = @new_data.map({ $_<name> });

  is all( @quant>>.Numeric ) ~~ Numeric, True,   "Testing $test_case, numeric fields still numeric";

  for @name -> $name {
                      is $name ~~ Str, True,   "Testing $test_case, this string field is still string."
                      }

#  is all( @name>>.Numeric  ) ~~ Numeric, False,  "Testing $test_case, string  fields are not numeric";

}
