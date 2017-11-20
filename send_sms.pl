#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use Getopt::Std;
use Storable;
use lib dirname($0);
use functions;

my %config;

sub HELP_MESSAGE {
	print $0 . ' - Perl implementation of the Telstra Messaging API v2
Options:
	-n	The number to send an SMS to formatted as: +61400000000
		If not specified, prompted for input.

	-m	If specified, the message to send - otherwise prompted for input.

	-f	If specified, will change the From text on your message. Requires
		account support within the API.
';
	exit 0;
}

if ( -f dirname($0) . "/tokenstore.bin" ) {
	%config = %{ retrieve(dirname($0) . "/tokenstore.bin") };
}

## Check if we have any command line options, if not, prompt for input.
my %options;
getopts('f:n:m:', \%options);

## If a number isn't provided with -n, prompt for destination number.
if ( ! $options{n} ) {
	print "Enter destination number in format +61......: ";
	$options{n} = <STDIN>;
	chomp($options{n});
}
if ( $options{n} eq "" ) { exit 1; }

## If a message isn't provided with -m, prompt for a message.
if ( ! $options{m} ) {
	print "Enter message to send: ";
	$options{m} = <STDIN>;
	chomp($options{m});
}
if ( $options{m} eq "" ) { exit 1; }

my %body = (
	'to'	=> $options{n},
	'body'	=> $options{m},
);

## If we specified a From using -f, provide it in the body
if ( $options{f} ) {
	$body{'from'} = $options{f};
}

## Get an OAuth token if required.
get_token(%config);

my $req = HTTP::Request->new( 'POST', 'https://tapi.telstra.com/v2/messages/sms' );
$req->header( 'Content-Type' => 'application/json' );
$req->header( 'Authorization' => 'Bearer ' . $config{token} );
$req->content( to_json(\%body) );
print "Sending: " . $req->content() . "\n";

my $ua = LWP::UserAgent->new;
my $res = $ua->request($req);
print "Result: " . $res->status_line . "\n";
print $res->decoded_content . "\n";
