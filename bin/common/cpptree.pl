#!/usr/bin/perl
#
# Copyright (c) 2020 Ran Panfeng.  All rights reserved.
# Author: satanson
# Email: ranpanf@gmail.com
# Github repository: https://github.com/satanson/cpp_etudes.git

# Usage:  show class hierarchy of cpp project in the style of Linux utility tree.
#
# Format: 
#   ./cpptree.pl <keyword|regex> <filter> <verbose(0|1)> <depth(num)>
#   
#   - keyword for exact match, regex for fuzzy match;
#    - subtrees whose leaf nodes does not match filter are pruned, default value is '' means match all;
#    - verbose=0, no file locations output; otherwise succinctly output;
#    - depth=num, print max derivation depth.
#
# Examples: 
#
# # show all classes
# ./cpptree.pl '\w+'
#
# # show all classes with file locations.
# ./cpptree.pl '\w+' '' 1
#
# # show all classes exact-match ExecNode if ExecNode class exists
# ./cpptree.pl 'ExecNode' '' 1
#
# # show all classes fuzzy-match regex '.*Node$' if the literal class name not exists.
# ./cpptree.pl '.*Node$' '' 1
#
# # show all classes and depth of derivation relationship is less than 3
# ./cpptree.pl '\w+' '' 1 3
#
# # show all classes whose ancestor class matches 'Node' and itself or its offsprings matches 'Scan'
# /cpptree.pl 'Node' 'Scan'
#

use warnings;
use strict;
use Data::Dumper;
use Storable qw/freeze thaw nstore retrieve/;

sub red_color($) {
  my ($msg) = @_;
  "\e[95;31;1m$msg\e[m"
}

sub ensure_ag_installed() {
  my ($ag_path) = map {chomp;
    $_} qx(which ag 2>/dev/null);
  if (!defined($ag_path) || (!-e $ag_path)) {
    printf STDERR "ag is missing, please install ag at first, refer to https://github.com/ggreer/the_silver_searcher\n";
    exit 1;
  }
}

ensure_ag_installed;

my $ignore_pattern = join "", map {" --ignore '$_' "} qw(*test* *benchmark* *CMakeFiles* *contrib/* *thirdparty/* *3rd-[pP]arty/* *3rd[pP]arty/*);
my $cpp_filename_pattern = qq/'\\.(c|cc|cpp|cu|C|h|hh|hpp|cuh|H)\$'/;

sub multiline_break_enabled() {
  my ($enabled) = map {chomp;
    $_} qx(echo enabled|ag --multiline-break enabled 2>/dev/null);
  return defined($enabled) && $enabled eq "enabled";
}

sub merge_lines_multiline_break_enabled(\@) {
  my @lines = @{+shift};
  my @three_parts = map {
    if (/^([^:]+):(\d+):(.*)$/) {
      [ $1, $2, $3 ]
    }
    else {
      undef
    }
  } @lines;

  my ($prev_file, $prev_lineno, $prev_line) = (undef, undef, undef);
  my @result = ();
  for (my $i = 0; $i < scalar(@three_parts); ++$i) {
    if (!defined($three_parts[$i])) {
      if (defined($prev_file)) {
        # $i-1 is last line of a match block
        push @result, [ $prev_file, $prev_lineno, $prev_line ];
        ($prev_file, $prev_lineno, $prev_line) = (undef, undef, undef);
      }
      else {
        # deplicate multiline-break.
      }
    }
    else {
      if (defined($prev_file)) {
        # non-first lines of a match block
        if ($prev_line =~ /\w$/ && $three_parts[$i][2] =~ /^\w/) {
          $prev_line = $prev_line . " " . $three_parts[$i][2];
        } else {
          $prev_line = $prev_line . $three_parts[$i][2];
        }
      }
      else {
        # first line of a match block
        ($prev_file, $prev_lineno, $prev_line) = @{$three_parts[$i]};
      }
    }
  }

  if (defined($prev_file)) {
    push @result, [ $prev_file, $prev_lineno, $prev_line ];
  }
  return @result;
}

sub merge_lines_multiline_break_disabled(\@) {
  my @lines = @{+shift};
  my @three_parts = map {/^([^:]+):(\d+):(.*)$/;
    [ $1, $2, $3 ]} @lines;

  my ($prev_file, $prev_lineno, $prev_line) = @{$three_parts[0]};
  my $prev_lineno_adjacent = $prev_lineno;
  my @result = ();

  for (my $i = 1; $i < scalar(@three_parts); ++$i) {
    my ($file, $lineno, $line) = @{$three_parts[$i]};

    if (($file eq $prev_file) && ($prev_lineno_adjacent + 1 == $lineno)) {
      $prev_line = $prev_line . $line;
      $prev_lineno_adjacent += 1;
    }
    else {
      push @result, [ $prev_file, $prev_lineno, $prev_line ];
      ($prev_file, $prev_lineno, $prev_line) = ($file, $lineno, $line);
      $prev_lineno_adjacent = $prev_lineno;
    }
  }
  push @result, [ $prev_file, $prev_lineno, $prev_line ];
  return @result;
}

sub merge_lines(\@) {
  my @lines = @{+shift};
  if (multiline_break_enabled()) {
    print "multiline-break is enabled in ag\n";
    return merge_lines_multiline_break_enabled(@lines);
  }
  else {
    return merge_lines_multiline_break_disabled(@lines);
  }
}

use Cwd qw/abs_path/;
sub get_path_of_script() {
  if ($0 !~ qr'/') {
    my ($path) = map {chomp;
      $_} qx(which $0 2>/dev/null);
    return $path;
  }
  else {
    return abs_path($0);
  }
}

sub file_newer_than_script($) {
  my ($file) = @_;
  my $script_path = get_path_of_script();
  return 0 unless ((-f $file) && (-f $script_path));
  return (-M $file) < (-M $script_path);
}

my $RE_IDENTIFIER = "\\b[A-Za-z_]\\w*\\b";
my $RE_WS = "(?:\\s)";
my $RE_TWO_COLON = "(?::{2})";
my $RE_SCOPED_IDENTIFIER = "(?:$RE_TWO_COLON $RE_WS*)? (?: $RE_IDENTIFIER $RE_WS* $RE_TWO_COLON $RE_WS*)* $RE_IDENTIFIER" =~ s/ //gr;
my $RE_CLASS = "(?:$RE_SCOPED_IDENTIFIER)";

sub read_content($) {
  my $file_name = shift;
  if (-f $file_name) {
    open my $handle, "<", $file_name or die "Fail to open '$file_name' for reading: $!";
    local $/;
    my $content = <$handle>;
    close $handle;
    return $content;
  }
  return undef;
}

sub write_content($@) {
  my ($file_name, @lines) = @_;
  open my $handle, "+>", $file_name or die "Fail to open '$file_name' for writing: $!";
  print $handle join("\n", @lines);
  close $handle;
}

sub read_lines($) {
  my $file_name = shift;
  if (-f $file_name) {
    open my $handle, "<", $file_name or die "Fail to open '$file_name' for reading: $!";
    my @lines = <$handle>;
    close $handle;
    return \@lines;
  }
  return undef;
}

sub gen_re_list($$$) {
  my ($re_delimiter, $re_item, $optional) = @_;
  my $re = "(?: $re_item (?: $RE_WS* $re_delimiter $RE_WS* $re_item)*? ) $optional";
  return $re =~ s/ //gr;
}

## preprocess source file

my $RE_QUOTED_STRING = qr/("([^"]*\\")*[^"]*")/;
my $RE_SINGLE_CHAR = qr/'[\\]?.'/;
my $RE_SLASH_STAR_COMMENT = qr"(/[*]([^/*]*(([*]+|[/]+)[^/*]+)*([*]+|[/]+)?)[*]/)";
my $RE_NESTED_CHARS_IN_SINGLE_QUOTES = qr/'[{}<>()]'/;
my $RE_SINGLE_LINE_COMMENT = qr'/[/\\].*';
my $RE_LEFT_ANGLES = qr'<[<=]+';
my $RE_TEMPLATE_ARGS_1LAYER = qr'(<\s*(((::)?(\w+::)*\w+\s*,\s*)*(::)?(\w+::)*\w+\s*)>)';
my $RE_CSV_TOKEN = gen_re_list(",", $RE_SCOPED_IDENTIFIER, "??");
my $RE_NOEXCEPT_THROW = qr"(\\b(noexcept|throw)\\b)(\\s*\\(\\s*$RE_CSV_TOKEN\\s*\\))?";
my $RE_MACRO_DEF = qr/(#define([^\n\r]*\\(\n\r?|\r\n?))*([^\n\r]*[^\n\r\\])?((\n\r?)|(\r\n?)|$))/;
my $MACRO_MODIFIER = qr/\b(class|struct)\b\s+(?:[_A-Z]+\s+)+\b(\w+)\b/;

sub empty_string_with_blank_lines($) {
  q/""/ . (join "\n", map {""} split "\n", $_[0]);
}

sub blank_lines($) {
  $_[0] =~ tr/\n\r//cdr;
}

sub replace_single_char($) {
  $_[0] =~ s/$RE_SINGLE_CHAR/'x'/gr;
}

sub replace_quoted_string($) {
  return $_[0] =~ s/$RE_QUOTED_STRING/&empty_string_with_blank_lines($1)/gemr;
}

sub replace_slash_star_comment($) {
  $_[0] =~ s/$RE_SLASH_STAR_COMMENT/&blank_lines($1)/gemr;
}

sub replace_nested_char($) {
  $_[0] =~ s/$RE_NESTED_CHARS_IN_SINGLE_QUOTES/'x'/gr;
}

sub remove_macro_modifier($) {
  $_[0] =~ s/$MACRO_MODIFIER/$1 $2/gr;
}

sub replace_single_line_comment($) {
  $_[0] =~ s/$RE_SINGLE_LINE_COMMENT//gr;
}

sub replace_left_angles($) {
  $_[0] =~ s/$RE_LEFT_ANGLES/++/gr;
}

sub replace_lt($) {
  $_[0] =~ s/\s+<\s+/ + /gr;
}

sub replace_template_args_1layer($) {
  ($_[0] =~ s/$RE_TEMPLATE_ARGS_1LAYER/&blank_lines($1)/gemr, $1);
}

sub repeat_apply($\&$) {
  my ($times, $fun, $arg) = @_;
  my ($result, $continue) = $fun->($arg);
  if (defined($continue) && $times > 1) {
    return &repeat_apply($times - 1, $fun, $result);
  }
  return $result;
}

sub remove_keywords_and_attributes($) {
  $_[0] =~ s/(\b(volatile|const|final|override)\b)|\[\[\w+\]\]//gr;
}

sub remove_v8_modifiers($) {
  ($_[0] =~ s/(class|struct)\s+(?:V8_EXPORT|V8_EXPORT_PRIVATE)\b/$1/gr) =~ s/NON_EXPORTED_BASE\s*\((\s*($RE_SCOPED_IDENTIFIER)\s*)\)/$1/gr;
}

sub remove_noexcept_and_throw($) {
  $_[0] =~ s/$RE_NOEXCEPT_THROW//gr;
}

sub replace_template_args_4layers($) {
  repeat_apply(4, &replace_template_args_1layer, $_[0]);
}

sub gen_re_gcc_attribute() {
  my $attr = "(?: $RE_IDENTIFIER (?: $RE_WS* \\([^()]+\\) )? )";
  my $attr_list = "(?: $attr (?: $RE_WS* , $RE_WS* $attr $RE_WS*)*)";
  my $gcc_attribute = "__attribute__ $RE_WS* \\( \\(? $RE_WS*  $attr_list $RE_WS* \\)? \\)";
  return $gcc_attribute =~ s/ //gr;
}

my $RE_GCC_ATTRIBUTE = gen_re_gcc_attribute();

sub remove_gcc_attributes($) {
  $_[0] =~ s/$RE_GCC_ATTRIBUTE//gr;
}

sub replace_macro_defs($) {
  $_[0] =~ s/$RE_MACRO_DEF/&blank_lines($1)/gemr;
}

sub preprocess_one_cpp_file($) {
  my $file = shift;
  return unless -f $file;
  my $content = read_content($file);
  return unless defined($content) && length($content) > 0;
  $content = replace_quoted_string(replace_single_char(replace_slash_star_comment($content)));

  $content = join qq/\n/, map {
    replace_lt(replace_left_angles(replace_nested_char(replace_single_line_comment($_))))
  } split qq/\n/, $content;

  $content = remove_keywords_and_attributes($content);
  $content = remove_gcc_attributes($content);
  $content = replace_template_args_4layers($content);
  $content = remove_noexcept_and_throw($content);
  $content = replace_macro_defs($content);
  $content = remove_v8_modifiers($content);
  $content = remove_macro_modifier($content);

  my $tmp_file = "$file.tmp.created_by_call_tree";
  write_content($tmp_file, $content);
  rename $tmp_file => $file;
}

sub get_all_cpp_files() {
  return grep {
    defined($_) && length($_) > 0 && (-f $_)
  } map {
    chomp;
    $_
  } qx(ag -U -G $cpp_filename_pattern $ignore_pattern -l);
}

sub group_files($@) {
  my ($num_groups, @files) = @_;
  my $num_files = scalar(@files);
  die "Illegal num_groups($num_groups)" if $num_groups < 1;
  if ($num_files == 0) {
    return;
  }
  $num_groups = $num_files if $num_files < $num_groups;
  my @groups = map {[]} (1 .. $num_groups);
  foreach my $i (0 .. ($num_files - 1)) {
    push @{$groups[$i % $num_groups]}, $files[$i];
  }
  return @groups;
}

sub preprocess_cpp_files(\@) {
  my @files = grep {defined($_) && length($_) > 0 && (-f $_) && (-T $_)} @{$_[0]};
  foreach my $f (@files) {
    my $saved_f = "$f.saved_by_calltree";
    rename $f => $saved_f;
    write_content($f, read_content($saved_f));
    preprocess_one_cpp_file($f);
  }
}

sub preprocess_all_cpp_files() {
  my @files = get_all_cpp_files();

  my @groups = group_files(10, @files);
  my $num_groups = scalar(@groups);
  return if $num_groups < 1;
  my @pids = (undef) x $num_groups;
  for (my $i = 0; $i < $num_groups; ++$i) {
    my @group = @{$groups[$i]};
    my $pid = fork();
    if ($pid == 0) {
      preprocess_cpp_files(@group);
      exit 0;
    }
    elsif ($pid > 0) {
      $pids[$i] = $pid;
    }
    else {
      die "Fail to fork a process: $!";
    }
  }

  for (my $i = 0; $i < $num_groups; ++$i) {
    wait;
  }
}

sub restore_saved_files() {
  my @saved_files = grep {
    defined($_) && length($_) > 0 && (-f $_)
  } map {
    chomp;
    $_
  } qx(ag -U -G '.+\\.saved_by_calltree\$' $ignore_pattern -l);

  foreach my $f (@saved_files) {
    my $original_f = substr($f, 0, length($f) - length(".saved_by_calltree"));
    rename $f => $original_f;
  }

  my @tmp_files = grep {
    defined($_) && length($_) > 0 && (-f $_)
  } map {
    chomp;
    $_
  } qx(ag -U -G '\\.tmp\\.created_by_calltree\$' $ignore_pattern -l);

  foreach my $f (@tmp_files) {
    unlink $f;
  }
}

sub register_abnormal_shutdown_hook() {
  my $abnormal_handler = sub {
    my $cause = shift;
    $cause = red_color($cause);
    print qq/Abnormal exit caused by $cause\n/;
    @SIG{keys %SIG} = qw/DEFAULT/ x (keys %SIG);
    restore_saved_files();
    exit 0;
  };
  my @sig = qw/__DIE__ QUIT INT TERM ABRT/;
  @SIG{@sig} = ($abnormal_handler) x scalar(@sig);
}

sub all_sub_classes() {
  my $attr_re = "\\[\\[[^\\[\\]]+\\]\\]";
  my $access_specifier_re = "\\b(?:final|virtual|private|public|protected)\\b";
  my $template_arguments_re = "<([^<>]*(?:<(?1)>|[^<>])[^<>]*)?>";
  my $cls_re = "^[ \\t]*(\\btemplate\\b\\s*$template_arguments_re)?(?:\\s*\\btypedef\\b)?[ \\t]*\\b(class|struct)\\b\\s*([a-zA-Z_]\\w*)\\s*[^{};*()=]*?{";
  print "cls_re=$cls_re\n";
  my $cls_filter_re = "^(\\S+)\\s*:\\s*\\b(?:class|struct)\\b\\s+\\w+(\\s+:\\s+(\\s*[:\\w]+\\s*,\\s*)*[:\\w]+)?s*";

  my $class0_re = "\\b(?:class|struct)\\b\\s+($RE_CLASS)";
  my $class1_re = "\\b(?:class|struct)\\b\\s+($RE_CLASS)\\s*:\\s*($RE_CLASS)";
  my $class2_re = "\\b(?:class|struct)\\b\\s+($RE_CLASS)\\s*:(?:\\s*$RE_CLASS\\s*,){1}\\s*($RE_CLASS)";
  my $class3_re = "\\b(?:class|struct)\\b\\s+($RE_CLASS)\\s*:(?:\\s*$RE_CLASS\\s*,){2}\\s*($RE_CLASS)";
  my $class4_re = "\\b(?:class|struct)\\b\\s+($RE_CLASS)\\s*:(?:\\s*$RE_CLASS\\s*,){3}\\s*($RE_CLASS)";
  my $class5_re = "\\b(?:class|struct)\\b\\s+($RE_CLASS)\\s*:(?:\\s*$RE_CLASS\\s*,){4}\\s*($RE_CLASS)";
  my $class6_re = "\\b(?:class|struct)\\b\\s+($RE_CLASS)\\s*:(?:\\s*$RE_CLASS\\s*,){5}\\s*($RE_CLASS)";

  my $cache_file = ".cpptree.list";
  my @matches = ();

  my $multiline_break = "";
  if (multiline_break_enabled()) {
    $multiline_break = "--multiline-break";
  }

  if ((-f $cache_file) && file_newer_than_script($cache_file)) {
    @matches = map {chomp;
      $_} qx(cat $cache_file);
    qx(touch $cache_file);
  }
  else {

    print qq(ag $multiline_break -U -G $cpp_filename_pattern $ignore_pattern '$cls_re'), "\n";
    @matches = map {
      chomp;
      $_
    } qx(ag $multiline_break -U -G $cpp_filename_pattern $ignore_pattern '$cls_re');

    die "Current directory seems not a C/C++ project" if scalar(@matches) == 0;
    printf "Extract lines: %s\n", scalar(@matches);

    @matches = map {join ":", @$_} merge_lines @matches;
    @matches = map {s/\btypedef\b//gr} @matches;
    printf "Merged into lines: %s\n", scalar(@matches);

    my @file_info_and_line = grep {
      defined($_)
    } map {
      if (/^(\S+)\s*:\s*(.*)/) {[ $1, $2 ]}
      else {undef}
    } @matches;
    my @file_info = map {$_->[0]} @file_info_and_line;
    my @line = map {$_->[1]} @file_info_and_line;

    my @transform_re = ($attr_re, $access_specifier_re, ($template_arguments_re) x 4, "\\btemplate\\b", "\\s*{\$", "(?<=\\s)\\s+");
    for my $re (@transform_re) {
      @line = map {s/$re//g;
        $_} @line;
    }
    printf "Transformed lines:%s\n", scalar(@line);

    @matches = map {$file_info[$_] . ":" . $line[$_]} (0 .. $#line);

    @matches = grep {/$cls_filter_re/} @matches;

    printf "Matches after filtering: %s\n", scalar(@matches);
    open my $cache_file_handle, "+>", $cache_file or die "$!";
    print $cache_file_handle join("\n", @matches);
    close($cache_file_handle);
  }


  my @table = grep {defined($_)} map {if (/^(\S+)\s*:\s*$class0_re/) {[ $1, $2 ]}
  else {
    undef
  }} @matches;

  my %table = ();

  for my $e (@table) {
    my ($file_info, $name) = @$e;
    if (!exists $table{$name}) {
      $table{$name} = [];
    }
    push @{$table{$name}}, $file_info;
  }

  #print Dumper(\%table);

  my $tree = {};
  my @class_re_list = ($class1_re, $class2_re, $class3_re, $class4_re, $class5_re, $class6_re);

  @matches = map {$_->[1]} sort {$a->[0] cmp $b->[0]} map {/^(\S+)\s*:\s*$class0_re/;
    [ $2, $_ ]} @matches;
  for my $re (@class_re_list) {
    my @parent_matches = grep {defined($_)} map {if (/^(\S+)\s*:\s*$re\s*/) {[ $1, $2, $3 ]}
    else {undef}} @matches;
    
    #print Dumper(\@matches, \@parent_matches);
    if (scalar(@parent_matches) == 0) {
      last;
    }
    for my $e (@parent_matches) {
      my ($fileline, $child, $parent0) = @$e;
      my $parent1 = [ split /\s*::\s*/, $parent0 ]->[-1];
      my @parents = keys %{+{$parent0 => 1, $parent1 => 2}};
      for my $parent (@parents) {
        if (!defined($tree->{$parent})) {
          $tree->{$parent} = [];
        }

        if (!exists $table{$parent}) {
          $table{$parent} = [ "out-of-tree" ];
        } 

        if ($child ne $parent) {
          push @{$tree->{$parent}}, $e;
        }
      }
    }
  }
  return $tree, \%table;
}

sub get_cached_or_run(&$$;@) {
  my ($func, $validate_func, $cached_file, @args) = @_;
  if (file_newer_than_script($cached_file)) {
    my $result = retrieve($cached_file);
    if (defined($result) && ref($result) eq ref([]) && $validate_func->(@$result)) {
      return @$result;
    }
  }
  my @result = $func->(@args);
  nstore [@result], $cached_file;
  return @result;
}

sub get_cache_or_run_keyed(\@$$;@) {
  my ($key, $file, $func, @args) = @_;

  die "Invalid data" unless defined($key) && ref($key) eq ref([]);
  die "Invalid func" unless defined($func);

  my @key = @$key;
  my $expect_key = join "\0", @key;

  my $check_key = sub(\%) {
    my $data = shift;
    return exists $data->{cached_key} && $data->{cached_key} eq $expect_key;
  };
  my ($data) = get_cached_or_run {
    +{ cached_key => $expect_key, cached_data => [ $func->(@args) ] }
  } $check_key, $file;
  return @{$data->{cached_data}};
}

sub script_basename() {
  get_path_of_script() =~ m{/([^/]+?)(?:\.\w+)?$};
  $1
}

sub get_cached_or_all_sub_classes() {
  restore_saved_files();
  my $script_basename = script_basename();
  my $file = ".$script_basename.dat";
  my @key = ("key");
  my $do_summary = sub() {
    print "preprocess_all_cpp_files\n";
    preprocess_all_cpp_files();
    print "register_abnormal_shutdown_hook\n";
    register_abnormal_shutdown_hook();
    print "extract_all_sub_classes: begin\n";
    my @result = all_sub_classes();
    print "extract_all_sub_classes: end\n";
    @SIG{keys %SIG} = qw/DEFAULT/ x (keys %SIG);
    restore_saved_files();
    return @result;
  };
  my @result = get_cache_or_run_keyed(@key, $file, $do_summary);
  return @result;
}

my $cls = shift || die "missing class name";
my $filter = shift;
my $verbose = shift;
my $depth = shift;
my $pathFilter = shift;
my $pathFilter_gen = sub($) {
  my $re = shift;
  if ($re =~ /^-/) {
    $re = substr $re, 1;
    sub($) {
      my $a = shift;
      $a !~ /$re/;
    }
  }
  else {
    sub($) {
      my $a = shift;
      $a =~ /$re/;
    }
  }
};
$pathFilter = ".*" unless (defined($pathFilter) && $pathFilter ne "");
$pathFilter = $pathFilter_gen->($pathFilter);

$filter = ".*" unless (defined($filter) && $filter ne "");
$verbose = undef if (defined($verbose) && $verbose == 0);
$depth = 0 unless defined($depth);

my ($tree, $table) = get_cached_or_all_sub_classes();

sub remove_loop($$$) {
  my ($tree, $name, $path) = @_;
  if (!exists $tree->{$name}) {
    return;
  }
  my @child = @{$tree->{$name}};
  @child = grep {!exists $path->{$_->[1]}} @child;
  $tree->{$name} = [ @child ];
  foreach my $chd (@child) {
    my $chd_name = $chd->[1];
    $path->{$chd_name} = 1;
    #my $csv_path = join ", ", keys %$path;
    #print "name=$name, chd_name=$chd_name, path=[$csv_path]\n";
    &remove_loop($tree, $chd_name, $path);
    delete $path->{$chd_name};
  }
}

sub remove_all_loops($) {
  my $tree = shift;
  foreach my $name (keys %$tree) {
    &remove_loop($tree, $name, { $name => 1 });
  }
  return $tree;
}

use List::Util qw/max/;
my $level = 0;
sub sub_class($$;$) {
  my ($file_info, $cls, $filter) = @_;
  $filter = ".*" unless defined($filter);
  return undef if $file_info && !$pathFilter->($file_info);
  $level++;
  #print "level=$level, file_info=$file_info, cls=$cls\n";
  my $root = { file_info => $file_info, name => $cls, child => [], tall => 1 };
  if (!exists $tree->{$cls} || ($depth && $level >= $depth)) {
    $level--;
    #print "level=$level, file_info=$file_info, cls=$cls; no children\n";
    return $cls =~ /$filter/ ? $root : undef;
  }

  my $child = $tree->{$cls};
  my @child_nodes = ();

  foreach my $chd (@$child) {
    push @child_nodes, &sub_class($chd->[0], $chd->[1], $filter);
  }

  @child_nodes = grep {defined($_)} @child_nodes;
  $level--;

  if (@child_nodes) {
    $root->{child} = [ @child_nodes ];
    $root->{tall} = 1 + max(map{$_->{tall}} @child_nodes);
    return $root;
  }
  elsif($cls =~ /$filter/ ){
    $root->{child}=[];
    $root->{tall} = 1;
    return $root;
  }
  else {
    return undef;
  }
}

sub fuzzy_sub_class($;$) {
  my ($cls_pattern, $filter) = @_;
  $filter = ".*" unless defined($filter);
  my $root = { file_info => undef, name => $cls_pattern };
  #print Dumper($table);
  my @names = map {my $name = $_;
    map {[ $_, $name ]} @{$table->{$name}}} grep {/$cls_pattern/} (keys %$table);
  #print Dumper([keys %$table ]);
  #print Dumper(\@names);
  my @child = grep {defined($_)} map {&sub_class(@$_, $filter)} @names;

  if ($depth > 0) {
    my $tallest = max(map{$_->{tall}} @child); 
    @child = grep {$_->{tall} == $tallest } @child;
  }

  $root->{child} = [@child];
  return $root;
}

sub unified_sub_class($;$) {
  my ($cls, $filter) = @_;
  $filter = ".*" unless defined($filter);
  if (!exists $tree->{$cls}) {
    return &fuzzy_sub_class($cls, $filter);
  }
  else {
    return &fuzzy_sub_class("^$cls\$", $filter);
  }
}

$tree = remove_all_loops $tree;
#print Dumper($tree);
my $hierarchy = unified_sub_class $cls, $filter;
#print Dumper($hierarchy);
#
sub format_tree($;$) {
  my ($root, $verbose) = @_;
  unless (%$root) {
    return ();
  }
  my $file_info = $root->{file_info};
  my $name = $root->{name};
  my @child = sort{
    my $r = ($a->{tall} <=> $b->{tall});
    if($r == 0){$a->{name} cmp $b->{name}}else{$r}
  } @{$root->{child}};

  if ($file_info) {
    $file_info =~ s/:/ +/g;
    $file_info = "vim $file_info";
  }

  my @result = ();
  $name = "\e[33;32;1m$name\e[m";
  if (defined($verbose) && defined($file_info)) {
    my $full_name = $name . "\t[" . $file_info . "]";
    push @result, $full_name;
  }
  else {
    push @result, $name;
  }

  if (scalar(@child) == 0) {
    return @result;
  }

  my $last_child = pop @child;
  foreach my $chd (@child) {
    my ($first, @rest) = &format_tree($chd, $verbose);
    push @result, "├── $first";
    push @result, map {"│   $_"} @rest;
  }
  my ($first, @rest) = &format_tree($last_child, $verbose);
  push @result, "└── $first";
  push @result, map {"    $_"} @rest;
  return @result;
}

my @lines = format_tree $hierarchy, $verbose;
@lines = map {"  $_"} ("", @lines, "");
print join qq//, map {"$_\n"} @lines;

