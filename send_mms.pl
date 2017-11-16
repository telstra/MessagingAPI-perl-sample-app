#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use Getopt::Std;
use Storable;
use lib dirname($0);
use functions;
use MIME::Base64 qw(encode_base64);

my %config;

if ( -f dirname($0) . "/tokenstore.bin" ) {
	%config = %{ retrieve(dirname($0) . "/tokenstore.bin") };
}

## Check if we have any command line options, if not, prompt for input.
my %options;
getopts('n:m:', \%options);

## If a number isn't provided with -n, prompt for destination number.
if ( ! $options{n} ) {
	print "Enter destination number in format +61......: ";
	$options{n} = <STDIN>;
	chomp($options{n});
}
if ( $options{n} eq "" ) { exit 1; }

# If a message isn't provided with -m, prompt for a message.
if ( ! $options{m} ) {
	print "Enter message to send: ";
	$options{m} = <STDIN>;
	chomp($options{m});
}
if ( $options{m} eq "" ) { exit 1; }

open (my $image, 'test.jpg') or die "$!";
binmode $image;
my $raw_string = do{ local $/ = undef; <$image>; };
my $encoded = encode_base64( $raw_string );

my $body = {
	'to'	=> $options{n},
	'subject'	=> $options{m},
    'MMSContent' => [
        {
			'type'	=> 'image/jpeg', 
			'filename'	=> 'test.jpg',
			'payload'	=> $encoded,
        }
    ]
};

## Get an OAuth token if required.
get_token(%config);

my $req = HTTP::Request->new( 'POST', 'https://tapi.telstra.com/v2/messages/mms' );
$req->header( 'Content-Type' => 'application/json' );
$req->header( 'Authorization' => 'Bearer ' . $config{token} );
$req->content( to_json($body) );

my $ua = LWP::UserAgent->new;
my $res = $ua->request($req);
print "Result: " . $res->content . "\n";

