#!/usr/bin/perl -w
 
use WWW::Mechanize;
use strict;
use warnings;
use Mojo::DOM;
use feature ':5.12';
use autodie;

use lib qw(..);
use JSON qw( );
use utf8;
use JSON;


# STDOUT isn't expecting UTF-8, encode to remove "Wide character in print at..."
binmode(STDOUT, "encoding(UTF-8)");

# ====================START INITIALIZE WEB SCRAPE======================
my $mech = WWW::Mechanize->new( autocheck => 1 );

my $live_link = "https://manganato.com/genre-all/";

# link to the updated manga list to store for test
$mech->get( $live_link );

# ====================END INITIALIZE WEB SCRAPE========================


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

# ==========================END READ JSON==============================

# ==========================START JSON FUNCTIONS============================

sub getMangaChapter {
  my ($json_data, $manga_name) = @_;
  for ( @{$json_data->{manga}} ) {
    if ($_->{name} eq $manga_name) { return $_->{chapter};}
  }
  return -1;
}

# set the found state of the manga 
sub setMangaChapter {
  my ($json_data, $manga_name, $chapter) = @_;
  for ( @{$json_data->{manga}} ) {
    if ($_->{name} eq $manga_name) { $_->{chapter} = $chapter;}
  }
}

# set the found state of the manga 
sub setMangaFound {
  my ($json_data, $manga_name) = @_;
  for ( @{$json_data->{manga}} ) {
    if ($_->{name} eq $manga_name) { $_->{found} = 1;}
  }
}

# reset found manga
sub resetMangaFound {
  my ($json_data) = @_;
  for ( @{$json_data->{manga}} ) {
    $_->{found} = 0;
  }
}

sub mangaUpdateComplete {
  my ($json_data) = @_;
  for ( @{$json_data->{manga}} ) {
    # if the manga name matches and found is false, 
    if ($_->{found} eq 0) { return 0;}
  }
  return 1;
}
# ==========================END JSON FUNCTIONS==============================

# switch between test and live html 
# test = 0 live = 1
my $dom;
my $fc;
if (1) {
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
my ($title, $chapter, $time);
# set to false states 
$title = '' , $chapter = '', $time = '';
# only 2 to 10 will be scraped, 21 will be sacrificial
for (2..201) {
  for my $e ($dom->find('div.content-genres-item *')->each) {
    # check if text is initialized/defined
    if (length $e->text) {
      if($e->{class} =~ 'genres-item-name text-nowrap a-h') {
        if ($e->text) { $title = $e->text; }
      }
      if($e->{class} =~ 'genres-item-chap text-nowrap a-h') {
        if ($e->text) { 
          $chapter = $e->text; 
          # strip the text to just digits for the chapters in case they have characters in them
          ( $chapter ) = $chapter =~ /(\d+)/;
        }
      }
      if($e->{class} =~ 'genres-item-time') {
        if ($e->text) { $time = $e->text; }
      }
      if ($title and $chapter and $time) {
        my $temp_chapter = getMangaChapter($json_data, $title);
        # if chapter is found inside json_data and the chapter is greater than
        if ($temp_chapter != -1) {
          if ($chapter gt $temp_chapter) {
            print "Updating manga ", $title, " chapter to ", $chapter, " from chapter ", $temp_chapter, " chapter updated: " , $time, " found on page: " , $_, "\n";
            setMangaChapter($json_data, $title, $chapter);
            # set the manga is found if we update the chapter
            setMangaFound($json_data, $title);
          } 
          if ($chapter eq $temp_chapter) {
            # set the manga is found if the chapter is hasn't been updated
            print "Keeping manga ", $title, " chapter to ", $chapter, " chapter updated: " , $time, " found on page: " , $_, "\n";
            setMangaFound($json_data, $title);
          }
        }
        # reset variables for next chapter
        $title = '' , $chapter = '', $time = '';
      }

    }
  }
  last if (mangaUpdateComplete($json_data));
  # concatenate the new chapter
  my $temp_link = $live_link.$_;
  # get the new html content
  $mech->get( $temp_link );
  # update dom with new content to parse
  $dom = Mojo::DOM->new($mech->content);
}

resetMangaFound($json_data);

open my $fh, ">", $json_file;
print $fh encode_json($json_data);
close $fh;