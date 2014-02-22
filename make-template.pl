#!/usr/bin/perl

use strict;
use warnings;
use feature qw(state);

use Data::Dumper;
use Getopt::Std;
use XML::Simple;
use List::Util qw(sum);
use Encode;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my %opts;

sub count_headers {
    my $h = shift;

    #print STDERR Dumper($h);
    foreach my $d (keys %{$h}) {
        #print STDERR $d;
        my $dnq = 0;
        foreach my $q (@{$h->{$d}{question}}) {
            $dnq++;
        }
        $h->{$d}{n} = $dnq;
    }
    #print STDERR Dumper($h);
}

sub packing_order {
    my ($hash, $bsize) = @_;

    # Invert the hash
    my %ihash;
    while (my($n, $v) = each(%$hash)) {
        push(@{$ihash{$v}}, $n);
    }

    # Sort the values
    my @chunks = reverse sort values %$hash;
    die("Impossible") if ($chunks[0] > $bsize);

    my @buckets;
    while (@chunks) {
        my $rem = $bsize;
        my $c = shift @chunks;
        my @bucket;
        push(@bucket, $ihash{$c});
        $rem -= $c;
        my $i = 0;
        foreach my $c1 (@chunks) {
            if (($rem - $c1) >= 0) {
                my $s = shift @{$ihash{$c1}};
                print $s, ', ';
                push(@bucket, $s);
                $rem -= $c1;
                splice(@chunks, $i, 1);
            } else {
                $i++;
            }
        }
        print "\n";
        push(@buckets, \@bucket);
    }
    return (\@buckets);
}

{
    my $count = 1;
    my $prev_text;

    sub coalesce {
        my $text = shift;

        # Seed first value
        unless(defined($prev_text)) {
            $prev_text = $text;
            return;
        }

        if ($text eq $prev_text) {
            $count++;
        } else {
            if ($count == 1) {
                print ' & ' . $prev_text;
            } else {
                print ' & \multicolumn{' . $count . '}{|c|}{' . $prev_text . '}';
            }
            reset_coalesce();
        }
        $prev_text = $text;
    }

    # Force printing
    sub flush_coalesce {
        coalesce('');
        reset_coalesce();
    }

    sub reset_coalesce {
        $count = 1;
        undef $prev_text;
    }
}

sub make_headers {
    my ($headers, $cpp) = @_;

    my $i = $headers->{instructions};
    #print STDERR Dumper($i);
    my $c = $headers->{common};
    #print STDERR Dumper($c);
    my $h = $headers->{domain};
    #print STDERR Dumper($h);
    my $t = $headers->{titles}{title};
    #print STDERR Dumper($t);

    count_headers($h);

    my %domains;
    foreach my $d (keys %{$h}) {
        $domains{$d} =  $h->{$d}{n};
    }
    #print STDERR "\nAfter count_headers";
    #print STDERR Dumper(%domains);

    #Specifying the order in which domains must appear in the form.
    # my @dorder = packing_order(\%domains, $cpp);
    #my @dorder = ( [ 'Competencies' ] ); # NNG1&2
    my @dorder = ( [ 'Numbers','Add/Subtraction','Geometry' ] ); # Math 2 2012
    #my @dorder = ( [ 'Numbers','Addition/Subtraction','Geometry','Measurements' ] ); # Math 2012 3
    #my @dorder = ( [ 'Numbers','Addition/Subtraction','Multiplication/Division','Geometry','Measurements' ] ); # Math 2012 4
    #my @dorder = ( [ 'Multiplication/Division','Fractions/Decimals','Geometry','Measurements' ] ); # Math 2012 5
    #my @dorder = ( [ 'Competencies', 'Others' ] ); # NNG3
    #my @dorder = ( [ 'Questions' ] ); # English
    #my @dorder = ( [ 'EVS','Mathematics' ] ); # Radio
    #my @dorder = ( [ 'o','r','w' ] ); # English 2011
    #my @dorder = ( [ 'General','Questions' ] ); # English
    #my @dorder = ( [ 'Oral Test','Written Test' ] ); # Research english 2012
    #my @dorder = ( ['Oral Test'] ); # Research english 2012-1
    #my @dorder = ( [ 'General','Oral Test','Written Test' ] ); # Class 1
    print $headers->{preamble};

    my $n = 1;                  # Starting Question number
    my $j = 0;
    foreach my $p (@dorder) {
        $j++;
        #print STDERR @$p;
        #This statement gets you the number of question in each domain (look at perl map)
        #value of list becomes $_ and n gives the number of question in that domain
        my $nq = sum (map { $h->{$_}{n} } @$p);
        my $ncols = $nq + 1;

        # Alternate rows are coloured
        print '\rowcolors{2}{}{yellow}', "\n";
        print '\begin{longtable}{' . $c->{format},  'l|' x $ncols, '}', "\n", '\hline', "\n";

        # Domains
        print q(\rule{0cm}{) . $t->{domain}{size} . '}' if (exists($t->{domain}{size}));
        print ' &' x scalar(@{$c->{item}});#, $t->{domain}{content} || '';
        foreach my $d (@$p) {
            print ' & \multicolumn{' . $h->{$d}{n} . '}{|c|}{' . $d . '}';
        }
        print ' \\\\ \hline', "\n";
        
        # Questions
        unless (exists($opts{q})) {
            print ' &' x scalar(@{$c->{item}});#, $t->{question}{content} || '';
        } else {
            foreach my $comm (@{$c->{item}}) {
                print $comm->{content}, ' & ';
            }
        }
        foreach my $d (@$p) {
            foreach my $q (@{$h->{$d}{question}}) {
                print ' & \question{' . $q->{text} . '}';
            }
        }
        print q(\rule{0cm}{) . $t->{question}{size} . '}' if (exists($t->{question}{size}));
        print ' \\\\ \hline', "\n";

        # Instructions
        print ' &' x scalar(@{$c->{item}});#, $t->{instruction}{content} || '';
        foreach my $d (@$p) {
            foreach my $q (@{$h->{$d}{question}}) {
                coalesce($i->{type}{$q->{instruction}});
            }
        }
        flush_coalesce();       # Reset the merging of cols
        print q(\rule{0cm}{) . $t->{instruction}{size} . '}' if (exists($t->{instruction}{size}));
        print ' \\\\ \hline', "\n";
        
        # Numbers and common headers
        unless (exists($opts{q})) {
            print q(\rule{0cm}{) . $t->{number}{size} . '}' if (exists($t->{number}{size}));
            foreach my $comm (@{$c->{item}}) {
                print $comm->{content}, ' & ';
            }
            # print $t->{'number'}{content} || '';
            foreach my $d (@$p) {
                foreach my $q (@{$h->{$d}{question}}) {
                    print ' & ' , $n++;
                }
            }
        }
        print '\endhead \hline', "\n";
        if (defined($opts{b})) {
            # Print 15 blank rows
            for (my $i=0; $i<$opts{b}; $i++) {
                foreach my $comm (@{$c->{item}}) {
                    print $comm->{tvar}, ' & ';
                }
                print '& ' x $nq, '\\\\ \hline', "\n";
            }
        } else {
            # Print template block
            print q([% FOREACH stu = students -%]), "\n";
            foreach my $comm (@{$c->{item}}) {
                print $comm->{tvar}, ' & ';
            }
            print '& ' x $nq, '\\\\ \hline', "\n";
            print q([% END %]), "\n";
        }
            
        print << 'EOF';
\end{longtable}
\rowcolors{1}{}{}

%%\pagebreak

EOF
    }
    print $headers->{epilogue} || '';

    print q(

\end{document}
);

    unless (defined($opts{b})) {
        print q(
[% END -%]
);
    }
}

#
# Start here
getopt('qnb:f:', \%opts);
my $file = $opts{f};

#Parses XML formatted data and returns a reference to a data structure which contains the same information in a more readily accessible form. 
#It takes in the xml file and keyattributes
my $headers = XMLin($file, 
                    KeyAttr => { domain => 'name', type => 'name', title => 'name' },
                    ForceArray => [ 'question', 'title','type' ],
                    ContentKey => '-content');

#print STDERR Dumper($headers);
make_headers($headers, ($opts{n} || 20));

__DATA__
