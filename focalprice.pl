#! /usr/bin/env perl
use strict;
use warnings;

use WWW::Mechanize;

sub get_category_urls {
	my $mech = WWW::Mechanize->new();
	my @url_ids = ( 9, 83, 102, 59, 11, 1, 12, 109, 42, 122, 8, 40 );

	my $url;
	my @category_urls;

	foreach my $url_id (@url_ids) {
		$url = "http://www.focalprice.com/goodsort_${url_id}_1_h.html";

		$mech->get($url);

                if ($mech->success() && $mech->status() == 200 && $mech->content() =~ /pageCount\s\=\s"(\d+)"/ ) {
			for (my $i = 1; $i <= $1; $i++ ) {
				push @category_urls, "http://www.focalprice.com/goodsort_${url_id}_${i}_h.html";

			}

                } else {
			print $url, "\n";
		}
	}

	open(OUTFILE, ">> cateogries.txt");
	print OUTFILE join "\n", @category_urls;
        close(OUTFILE);
}

#get_category_urls;
sub get_product_urls {
	open(OUTFILE, "< cateogries.txt");
	$/ = undef;
	my $category_urls = <OUTFILE>;
        close(OUTFILE);
	

	my @products;
	my @failed_lists;
	my $line = 1;

	open(OUTFILE, ">> products.txt");

        foreach my $url ( split /\n/, $category_urls ) {
		my $mech = WWW::Mechanize->new();
		print "getting Line $line ", $url, "...";

		$mech->get($url);

		if ($mech->success() && $mech->status() == 200) {
			print "success\n";
			@products =  $mech->content() =~ /<ul\s+class\="infoBox">\s*<li\s+class\="proImg">\s*<a\s+href\="([^"]+)">/g;
			print OUTFILE join "\n", @products;
			print OUTFILE "\n";
		} else {
			print "failed\n";
			push @failed_lists, $url;
		}
		$line++;
        }

        close(OUTFILE);

	open(OUTFILE, "> cateogries.txt");
	print OUTFILE join "\n", @failed_lists;
        close(OUTFILE);
}

get_product_urls;
