#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use WWW::Mechanize;
use DBI;

sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub get_category_urls {
	my $mech = WWW::Mechanize->new();
	my @url_ids = ( 9, 83, 102, 59, 11, 1, 12, 109, 42, 122, 8, 40 );

	my $url;
	my @category_urls;

	foreach my $url_id (@url_ids) {
		$url = "http://www.focalprice.com/goodsort_${url_id}_1_h.html";

		eval { $mech->get($url) };

		if($@) {
			print $url, "\n";
		}elsif ($mech->success() && $mech->status() == 200 && $mech->content() =~ /pageCount\s\=\s"(\d+)"/ ) {
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

		eval { $mech->get($url) };

		if($@) {
			print "failed\n";
			push @failed_lists, $url;
		}elsif ($mech->success() && $mech->status() == 200) {
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

sub get_product {
	my $dbh = DBI->connect("DBI:mysql:database=forcalbuying;host=localhost", "root", "12345", {'RaiseError' => 1}) or die $DBI::errstr;;

	open(OUTFILE, "< products.txt");

	my $line = 1;
	my @failed_lists;

	while(<OUTFILE>) {
		my $mech = WWW::Mechanize->new();
		print "getting Line $line ", $_, "...";

		my ($SKU) = $_ =~ /com\/([^\/]+)/;
		print $SKU, "\n";

		eval { $mech->get($_) };

		if($@) {
			print "failed\n";
			push @failed_lists, $_;
                } elsif ($mech->success() && $mech->status() == 200) {
			my $content = $mech->content();
			if ($content =~ /tocart12/) { # out of stock
				print "skipped\n";
				next;
			}

			print "success\n";
			my ($title) = $content =~ /<title>([^<]+)<\/title>/s;
print $title, "\n";
			my ($price) = $content =~ /Priceus">\s*\$([\d\.]+)/s;
			print $price, "\n";
			my (@category) = $content =~ /[^>]+>([^<]+)<\s*\/a\s*>\s*>\s*/sg;
			shift @category;
			my $parent = 0;
			foreach (@category) {
				$_ = trim $_;
				my $sth = $dbh->prepare('SELECT * FROM category_description where name=?');
				$sth->execute($_);
 				my @row = $sth->fetchrow_array;
				if(!@row) {
					$sth = $dbh->prepare('INSERT INTO category(`parent_id`, `top`, `column`, `status`) VALUES(?, ?, ?, ?)');
					$sth->execute($parent, 1, 1, 1);
					$parent = $dbh->last_insert_id(undef, undef, undef, undef);
					$sth = $dbh->prepare('INSERT INTO category_description(`category_id`, `language_id`, `name`) VALUES(?, ?, ?)');
					$sth->execute($parent, 1, $_);
					$sth = $dbh->prepare('INSERT INTO category_to_store(`category_id`, `store_id`) VALUES(?, ?)');
					$sth->execute($parent, 0);
				} else {
					$parent = shift @row;
				}
			}
		
#print join ' > ', @category;
#print "\n";
			my (@pics) = $content =~ /registerImage\("alt_image_\d+", "([^"]+)/sg;

			my $sth = $dbh->prepare('SELECT * FROM category_description where name=?');
print join "\n", @pics;
print "\n";
			my ($desc) = $content =~ /class="goods_text">(.*)<\/div>\s*<div\s+style="padding:10px;">/s;

#print $desc;
			my ($desc_more) = $content =~ /<div\s+style="padding:10px;">(.*)<\/div>\s*<\/div>\s*<div\s+class="TabContent"/s;
			$desc_more =~ s/×/x/sg;
print $desc_more;
			#@products =  $mech->content() =~ /<ul\s+class\="infoBox">\s*<li\s+class\="proImg">\s*<a\s+href\="([^"]+)">/g;
			#print OUTFILE join "\n", @products;
			#print OUTFILE "\n";
			my (@wholesale_price) = $content =~ /<td>\s*<font\s+color='#ff6600'>\s*\$\s*([^<]+)/sg;
print join ' ', @wholesale_price;
exit;
		} else {
			print "failed\n";
			push @failed_lists, $_;
		}
	
		$line++;
        }

#	$/ = undef;
#	my $category_urls = <OUTFILE>;
#       close(OUTFILE);
	
}
get_product;


