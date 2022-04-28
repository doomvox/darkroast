use v6;

use Test;

## TODO rename
##   method_object_gists.t

=begin pod

Additional tests for .^methods to verify this issue has been fixed:

  https://github.com/rakudo/rakudo/issues/4207

The method objects returned by a .^methods used to sometimes have LTA
.gist that deviated from the expected name (which could still be found
via .name), returning strings such as "Method+{is-nodal}.new"

=end pod

# classes and methods that have had problems in the past
my @classes = < Supply Grammar Set Array >; 
my %check_names =  (
               'Supply'   => < unique   squish  repeated >,
               'Array'    => < reverse  splice  pick  pop  sum >,
               'Grammar'  => < values   keys    kv >,
               'Set'      => < values   keys    kv >,
              );

plan 2 * @classes.elems + %check_names.values>>.elems.sum;  # 2*4 + 14 = 22

for @classes -> $class {
    my @methods = ::($class).^methods; 
    my @gist = @methods>>.gist;
    my @name = @methods>>.name;

    subtest "Checking that $class methods have .gist identical to .name", {
        my $count = @gist.elems;
        plan $count;
        for (0 .. $count - 1) -> $i {
            my $g = @gist[ $i ];
            my $n = @name[ $i ];
            is $g, $n, "Testing that $class method '$n' has correct .gist";
        }
   };

    my @look_bad = @gist.grep( { m/'thod+{is'/ }, :k ); ## e.g. "Method+{is-nodal}.new"
    my $msg = "Checking for reversion to bad gists among any $class methods";
    $msg ~= "\nProblems with: " ~ @name[ @look_bad ].sort if @look_bad;
    ok( not @look_bad, $msg );

    my @check_names = | %check_names{$class};
    my $gist_set = @gist.Set;
    for @check_names -> $check_name {
        cmp-ok $check_name, '(elem)', $gist_set,
          "Checking that there's a '$check_name' among the $class methods";
    }
}

# done-testing();
