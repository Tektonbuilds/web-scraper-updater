#!/usr/bin/perl -w
 
use WWW::Mechanize;
use strict;
use warnings;
use Mojo::DOM;
use feature ':5.12';
use autodie;

use lib qw(..);
use JSON qw( );


# STDOUT isn't expecting UTF-8, encode to remove "Wide character in print at..."
binmode(STDOUT, "encoding(UTF-8)");

# ==========================START SAVE HTML============================
my $mech = WWW::Mechanize->new( autocheck => 1 );

my $live_link = "https://manganato.com/genre-all/";

# link to the updated manga list to store for test
$mech->get( $live_link );

my $file_name = "manganelo-live.html";

unless(-e $file_name) {
    #Create the file if it doesn't exist
    open my $fc, ">", $file_name
        or die "Can't open file $!";
    close $fc;
}

open(FH, '>', $file_name) or die $!;

# write content into html
print FH $mech->content;

close(FH);

# ==========================END SAVE HTML==============================


# ==========================START READ JSON============================

my $json_file = 'data.json';

my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $json_file)
      or die("Can't open \$json_file\": $!\n");
   local $/;
   <$json_fh>
};

my $json = JSON->new;
my $json_data = $json->decode($json_text);

sub isMangaInJson {
  my ($json_data, $manga_name) = @_;
  for ( @{$json_data->{manga}} ) {
    if ($_->{name} eq $manga_name) { return 1;}
    #print $_->{name}, " ", $_->{chapter};
  }
  return 0;
}

sub getMangaChapterInJson {
  my ($json_data, $manga_name) = @_;
  for ( @{$json_data->{manga}} ) {
    if ($_->{name} eq $manga_name) { return $_->{chapter};}
    #print $_->{name}, " ", $_->{chapter};
  }
  return -1;
}

# ==========================END READ JSON==============================

# switch between test and live html 
# test = 0 live = 1
my $dom;
my $fc;
if (0) {
  # get the content fresh
  $dom = Mojo::DOM->new($mech->content);
} else {
  # get from test content

  my $file_name1 = "manganelo-babysteps.html";
  
  open $fc, "<", $file_name1 
    or die "Can't open file $!";

  read $fc, my $file_content, -s $fc;
  $dom = Mojo::DOM->new($file_content);
  close $fc;
}



# Loop through everything that is a div with "content-genres-item" as the main class and another tag
# declare variables for scope
# TODO: MAKE SURE MANGA NAME, CHAPTER AND TIME ALL ARE DECLARED BEFORE CALLING isMangaInJson()
my ($title, $chapter, $time);
for my $e ($dom->find('div.content-genres-item *')->each) {
  if (length $e->tag) {
    if (length $e->text) {
      if($e->{class} =~ 'genres-item-name text-nowrap a-h') {
        my $title = $e->text;
        #say ("Manga Title:",$title);
        my $chapter = isMangaInJson($json_data, $title);
        if ($chapter gt -1) {
          print "Found manga ", $title, "\n";
        }
      }
      if($e->{class} =~ 'genres-item-chap text-nowrap a-h') {
        $chapter = $e->text;
        #say ("Manga chapter:",$chapter);
      }
      if($e->{class} =~ 'genres-item-time') {
        $time = $e->text;
        #say ("time:",$time);
      }
    }
  }
}