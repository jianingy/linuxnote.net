#!/usr/bin/env perl
# 解析迅雷的 HTML 页面，得到要下载的 LINK
# 2012.1.23 luoyi.ly AT gmail dot com

use utf8;
use strict;
use XML::LibXML;
use Getopt::Std;
use JSON::XS;
use Encode;

# Data::Dumper trick make utf8 string pretty
use Data::Dumper;
$Data::Dumper::Useqq = 1;

{ 
	no warnings 'redefine';
    sub Data::Dumper::qquote {
        my $s = shift;
        return "'$s'";
    }
}

my %opts;

getopt('p:j:h', \%opts); 

if ( $opts{"h"} ) {
	die "xunlei_parser.pl [-p page.html]   [-j d.json] -h\n"
}

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $verbose = $ENV{"VERBOSE"};

my $parser = XML::LibXML->new({recover=>2, 
	no_defdtd=>1, recover_silently=>1, no_network=>1,
    suppress_warnings=>1, suppress_errors=>1});


sub dump_xpath {
	my ($xc, $list_xpath) = @_;
	if ( $verbose ) {
		my $name_node = ( $xc->findnodes($list_xpath ) );
		foreach my $n ( @$name_node ) {
			print STDERR $n->toStringC14N(), "\n";
			print STDERR "====================================================\n";
		}
	}
}

sub parse_file {
    my $file = shift;
    my $dom = $parser->parse_html_file($file);
    my $xc = XML::LibXML::XPathContext->new($dom);
	
	my $id_xpath = "/html/body/div[3]/div[2]/div/div[2]/h2[2]/a";
	&dump_xpath($xc, $id_xpath);
	my $id_node = ($xc->findnodes($id_xpath))[0];
	my $user_id_url = $id_node->getAttribute("href");
	my $user_id = "";
	if ( $user_id_url =~ m,http://dynamic\.cloud\.vip\.xunlei\.com/cloud\?userid=(\d+), ) {
		$user_id = $1;
	} else {
		die "Can't find User Id, Please check the page.html file ...";
	}

	foreach my $i ( 1 .. 10000 ) {
		                  
		my $list_xpath = "/html/body/div[3]/div[2]/div[2]/div/div[3]/div[2]/div/div[$i]/div";
		$list_xpath =    "/html/body/div[3]/div[2]/div[2]/div/div[3]/div[2]/div/div/div" if ( $i == 1 );
		if ( $verbose ) {
			my $name_node = ( $xc->findnodes($list_xpath ) );
			foreach my $n ( @$name_node ) {
				print STDERR $n->toStringC14N(), "\n";
				print STDERR "====================================================\n";
			}
		}
		my @nodes = $xc->findnodes($list_xpath);
		last unless ( scalar @nodes );
		my $node = $nodes[0];

		my $name_node = ( $xc->findnodes($list_xpath . "/input[2]") )[0];
		my $infoid_node = ( $xc->findnodes($list_xpath . "/input[3]") )[0];
		my $url_node = ( $xc->findnodes($list_xpath . "/input[4]") )[0];



		my $name = $name_node->getAttribute("value");
		$name =~ s/\t/ /g;
		my $name_id = $name_node->getAttribute("id");
		my $infoid = $infoid_node->getAttribute("value");
		my $url = $url_node->getAttribute("value");

		if ( $verbose ) {
			print STDERR $name, "\n";
			print STDERR $infoid, "\n";
			print STDERR $url, "\n";
			print STDERR "====================================================\n";
		}

		# BT File doesn't have URL in the first page
		# http://dynamic.cloud.vip.xunlei.com/interface/fill_bt_list?callback=fill_bt_list&tid=54994799623&infoid=A31294ADC40BCC2FA9A7093E9D638655ED2BBDBA&g_net=1&p=1&uid=203085105&noCacheIE=1327324105856
		if ( length $url < 10 ) {
			if ( $name_id =~ /durl(\d+)/ ) {
				my $tid = $1;
				my $bt_url = "http://dynamic.cloud.vip.xunlei.com/interface/fill_bt_list?" .
				             "callback=fill_bt_list&tid=$tid&infoid=$infoid&g_net=1&p=1&uid=$user_id";
				print "$name\t$bt_url\n";
			}
		} else {
			print "${name}\t${url}\n";
		}

	}
}

sub parse_json {
    my $file = shift;
	my $content = "";
	{
		open my $fh, "<:encoding(UTF-8)", "$file" or die $!;
		local $/; # enable localized slurp mode
		$content = <$fh>;
		close $fh;
	}
	$content =~ s/fill_bt_list\(//g;
	$content =~ s/\)//g;
	my $j = decode_json $content;
	if ( $verbose ) {
		print STDERR  decode("utf8", encode_json $j);
		print STDERR  Dumper($j) if ( $verbose);
	}
	foreach ( @{$j->{"Result"}->{"Record"}} ) {
		print $_->{"title"}, "\t", $_->{"downurl"}, "\n";
	}

}

if ( $opts{"p"} ) {
	&parse_file($opts{"p"});
} elsif ( $opts{"j"} ) {
	&parse_json($opts{"j"});
}

