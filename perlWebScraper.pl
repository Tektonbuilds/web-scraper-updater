#!/usr/bin/perl -w
 
use WWW::Mechanize;
use strict;
use warnings;
use Mojo::DOM;
use feature ':5.12';
use autodie;


# STDOUT isn't expecting UTF-8, encode to remove "Wide character in print at..."
binmode(STDOUT, "encoding(UTF-8)");

my $mech = WWW::Mechanize->new( autocheck => 1 );

# link to the updated manga list
$mech->get( "https://manganato.com/genre-all" );

my $filename = "manganelo-latest.html";

unless(-e $filename) {
    #Create the file if it doesn't exist
    open my $fc, ">", $filename;
    close $fc;
}

open(FH, '>', $filename) or die $!;

print FH $mech->content;

close(FH);

# Parse
#my $dom = Mojo::DOM->new('<div><p id="a">Test</p><p id="b">123</p></div>');

my $filename1 = "parsed-manga.txt";

unless(-e $filename1) {
    #Create the file if it doesn't exist
    open my $fc, ">", $filename1;
    close $fc;
}

open(FH, '>', $filename1) or die $!;

my $dom = Mojo::DOM->new($mech->content);


# Loop through everything that is a div with "content-genres-item" as the main class and another tag
for my $e ($dom->find('div.content-genres-item *')->each) {
  if (length $e->tag) {
    if (length $e->text) {
      if($e->{class} =~ 'genres-item-name text-nowrap a-h') {
        my $title = $e->text;
        say ("Manga Title:",$title);
      }
      if($e->{class} =~ 'genres-item-chap text-nowrap a-h') {
        my $chapter = $e->text;
        say ("Manga chapter:",$chapter);
      }
      if($e->{class} =~ 'genres-item-time') {
        my $time = $e->text;
        say ("time:",$time);
      }
    }
  }
}


close(FH);