use v6;

use Test;

plan 6;

=begin pod

Additional tests for .^methods to verify this issue has been fixed:

  https://github.com/rakudo/rakudo/issues/4207


=end pod


my $n1 = Set.^methods>>.name.grep(/values/).[0];
my $g1 = Set.^methods>>.gist.grep(/values/).[0];

is $g1, $n1,      '.name and .gist return same name (values) on object from ^methods';
is $g1, 'values', '.gist shows method name of "values" that object';
