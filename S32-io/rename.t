# darkroast/S32-io/rename.t

## Testing additional cases not covered by roast/S32-io/rename.t
## which uses relative paths and the current directory.
## Most tests here use full paths and newly created tmp dirs.

use v6;
use Test;
use File::Directory::Tree;

# plan 29; # TODO

my $non-existent-file = "non-existent-rename";

sub create_files ($loc) {
  my @base = <tempfile-rename1 tempfile-rename2>;

  my @files = gather 
    for @base -> $base {
                        my $full_file = "$loc/$base";
                        take $full_file;
                        my $fh = open($full_file, :w);
                        $fh.print: "0123456789AB";
                        $fh.close();
                       }
    return @files;
  }

# make sure it looks like a tmpdir before you do a rmtree
sub safe_rmtree ( $loc, $tmp_marker = '_tmp_' ) {
  rmtree( $loc ) if $loc ~~ m/ $tmp_marker /;
}

sub cleanup ( @dirs ) {
  for @dirs -> $d {
     safe_rmtree( $d );
  }
}


my $HOME = %*ENV{'HOME'};   # Q: is there a "use Env" that imports these?
my $tmp = "$HOME/tmp";      
$tmp.IO.mkdir;          # a no-op if it exists already

{
  my $tmpdir = "$tmp/raku_rename_tmp_1";
  cleanup( ($tmpdir).list );
  subtest "Testing basic file rename with .rename",
    {
     # create a temporary location for test files
     my $d = $tmpdir.IO.mkdir;
     ok $tmpdir.IO.d, "Checking that dir was created: $tmpdir";

     # create files in the subdir 
     my @files = create_files( $tmpdir );
     my $f = @files[0];

     ok $f.IO.e, "Checking that file was initially created: $f"; 

     # rename file
     my $dest1 = "$tmpdir/tempfile-after-rename-1a";
     my $ret_obj = $f.IO.rename( $dest1 );
     ok $ret_obj, '.IO.rename normal file';

     # check whether renamed file exists under new name.
     ok $dest1.IO.e, 'renamed file exists';  

     # check whether the older file is gone
     nok $f.IO.e, "Testing that source file is gone (it was renamed not copied)";
     ok @files[1].IO.e, "Checking that unrelated file is untouched: @files[1]";
 
    };
    ## && cleanup( ($tmpdir).list );
  cleanup( ($tmpdir).list );
  }

## use rename to move a file from one dir to another
{
  # the temporary directories
  my $loc1 = "$tmp/raku_rename_tmp_A";
  my $loc2 = "$tmp/raku_rename_tmp_B";
  cleanup( ($loc1, $loc2).list );                
  subtest "Testing using .rename to move a file",
    {
     # create temporary subdirs 
     my $d1 = $loc1.IO.mkdir;
     my $d2 = $loc2.IO.mkdir;

     ok $loc1.IO.d, "Checking that dir was created: $loc1";
     ok $loc2.IO.d, "Checking that dir was created: $loc2";

     # create files in the first subdir 
     my @files = create_files( $loc1 );
     my $source = @files[0];

     # make sure the file exists
     ok $source.IO.e, "Checking that file was initially created: $source"; 
     my $dest1 = "$loc2/tempfile-moved-by-rename-1a";
     nok $dest1.IO.e, "Checking that there's no such file in destination already.";

     ## use rename to move the file
     my $ret_obj = $source.IO.rename( $dest1 );
     ok $ret_obj, '.IO.rename normal file';

     # check whether renamed file exists under new name.
     ok $dest1.IO.e, 'renamed file exists';  

     # check whether the older file is gone
     nok $source.IO.e, 'source file no longer exists';
     ok @files[1].IO.e, "Checking that unrelated file is untouched: @files[1]";
    };
    ## && cleanup( ($loc1, $loc2).list );
  cleanup( ($loc1, $loc2).list );
  }

{
  ## imitating my tagger.raku script, what could've messed up the .rename?
  # the temporary directories
  my $loc1 = "$tmp/raku_rename_tmp_A";
  my $loc2 = "$tmp/raku_rename_tmp_B";
  cleanup( ($loc1, $loc2).list );                

  subtest "Testing using .rename after file stats",
    {
     # create temporary subdirs 
     my $d1 = $loc1.IO.mkdir;
     my $d2 = $loc2.IO.mkdir;

     ok $loc1.IO.d, "Checking that dir was created: $loc1";
     ok $loc2.IO.d, "Checking that dir was created: $loc2";

     # create files in the first subdir 
     my @files = create_files( $loc1 );
     my $source = @files[0];

     my $dest = "$loc2/tempfile-moved-by-rename-1a";
     nok $dest.IO.e, "Checking that there's no such file in destination already.";

     ## use rename to move the file, but first some file stats (also done in my tagger.raku script)
     my $file_io = $source.IO;
     my ($loc, $base, $ext) = ( $file_io.dirname, $file_io.basename, $file_io.extension );
     my $ret_obj = $file_io.rename( $dest ); # does a copy not a rename?  weird.  BUG.
     ok $ret_obj, '.IO.rename normal file';

     # unlink( $source ); ## TODO why did I need to do this?

     # check whether renamed file exists under new name.
     ok $dest.IO.e, 'renamed file exists';  
     # check whether the older file is gone
     nok $source.IO.e, 'source file no longer exists';
     ok @files[1].IO.e, "Checking that unrelated file is untouched: @files[1]";
    }
    cleanup( ($loc1, $loc2).list );                
  }

###  when using full paths, should be no dependency on the current directory.  check.


###  the roast test code for reference, TODO delete
# # sanity check
# ok $existing-file1.IO.e, 'sanity check 1';
# ok $existing-file2.IO.e, 'sanity check 2';
# nok $non-existent-file.IO.e, "sanity check 2";

# # method .IO.rename
# {
#     my $dest1a = "tempfile-rename-dest1a";
#     my $dest1b = "tempfile-rename-dest1b";
    
#     my $existing-size1 = $existing-file1.IO.s;
#     ok $existing-file1.IO.rename( $dest1a ), '.IO.rename normal file';
#     nok $existing-file1.IO.e, 'source file no longer exists';
#     ok $dest1a.IO.e, 'dest file exists';
#     is $dest1a.IO.s, $existing-size1, 'dest file has same size as source file';
    
#     throws-like { $non-existent-file.IO.rename( $dest1b ) }, X::IO::Rename, '.IO.rename non-existent file';
#     nok $dest1b.IO.e, "dest file doesn't exist";

#     throws-like { $dest1b.IO.rename( $dest1a, :createonly ) },
#       X::IO::Rename, '.IO.rename createonly fail';
#     nok $dest1b.IO.e, "dest file doesn't exist";

#     ok $dest1a.IO.rename( $dest1b, :createonly ), '.IO.rename createonly';
#     ok $dest1b.IO.e, "dest file does exist";

#     ok unlink($dest1a), 'clean-up 1a';
#     ok unlink($dest1b), 'clean-up 1b';
# }

# # sub rename()
# {
#     my $dest2a = "tempfile-rename-dest2a";
#     my $dest2b = "tempfile-rename-dest2b";
    
#     my $existing-size3 = $existing-file2.IO.s;
#     ok rename( $existing-file2, $dest2a ), 'rename() normal file';
#     nok $existing-file2.IO.e, 'source file no longer exists';
#     ok $dest2a.IO.e, 'dest file exists';
#     is $dest2a.IO.s, $existing-size3, 'dest file has same size as source file';

#     throws-like { rename( $non-existent-file, $dest2b ) }, X::IO::Rename; '.IO.rename missing file';
#     nok $dest2b.IO.e, "It doesn't";

#     throws-like { rename( $dest2b, $dest2a, :createonly ) },
#       X::IO::Rename, 'rename createonly fail';
#     nok $dest2b.IO.e, "dest file doesn't exist";

#     ok rename( $dest2a, $dest2b, :createonly ), 'rename createonly';
#     ok $dest2b.IO.e, "dest file does exist";

#     ok unlink($dest2a), 'clean-up 2a';
#     ok unlink($dest2b), 'clean-up 2b';
# }

# # clean up
# ok unlink($existing-file1), 'clean-up 3';
# ok unlink($existing-file2), 'clean-up 4';

# # vim: expandtab shiftwidth=4

done-testing();
