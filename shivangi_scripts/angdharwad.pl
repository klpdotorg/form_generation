#!/usr/bin/perl

use strict;
use warnings;

use Template;
use XML::Parser;
use Data::Dumper;
use File::Path;
use File::Find;
use LaTeX::Encode;
use Getopt::Std;
use Utility::FormID;
use XML::Dumper;
use XML::SAX;
use Utility::FormXMLParser;



use Utility::KLPDB qw(pgconnect);

my %opts;

sub get_students {
    my $dbh = shift;

my $children = $dbh->prepare(q{
select  distinct stu.id as sid,
        ARRAY_TO_STRING(ARRAY[c.first_name,c.middle_name,c.last_name],' ') as cname,
        ARRAY_TO_STRING(ARRAY[r.first_name,r.middle_name,r.last_name],' ') as pname,
        lower(r.relation_type) as ptype,
        ARRAY_TO_STRING(ARRAY[t.first_name,t.middle_name,t.last_name],' ') as tname,
        to_char(c.dob, 'DD-MON-YYYY') as cdob,
        c.gender as csex,
        sg.name as class,
        s.id as scode,
        sc.name as stype,
        trim(s.name) as sname,
        trim(b2.name) as dist,
        trim(b1.name) as b1,
        trim(b.name) as b
from schools_studentgroup sg,
     schools_student_studentgrouprelation stusg,
     schools_student stu,
     schools_child c  left outer join schools_relations r on (c.id=r.child_id),
     schools_institution s left outer join schools_staff t on (s.id=t.institution_id and t.staff_type_id=3),
     schools_boundary b,
     schools_boundary b1,
     schools_boundary b2,
     schools_institution_category sc
where
	s.boundary_id= b.id
        and b.parent_id= b1.id
        and b1.parent_id = b2.id
        and b.boundary_type_id=2
        and s.cat_id= sc.id
        and s.id = sg.institution_id
        and sg.id = stusg.student_group_id
        and stusg.student_id = stu.id
        and stu.active = 2
        and stusg.academic_id = 122
        and stu.child_id = c.id
        and stusg.active=2
        and s.active=2
        and (extract(YEAR FROM age(c.dob))*12+extract(month from age(c.dob)))>=31
        and (extract(YEAR FROM age(c.dob))*12+extract(month from age(c.dob)))<=55
        and b1.id in (8776,8777,8775,8779,8778,9059,8774,9116,9065,9081)
});
    $children->execute();
    my (%data, %children, %parents, %schools, %bh);
    while (my $row = $children->fetchrow_arrayref) {
        my $sid = $row->[$children->{NAME_lc_hash}{sid}];
        my $scode = $row->[$children->{NAME_lc_hash}{scode}];
        my $d = $row->[$children->{NAME_lc_hash}{dist}];
        my $b = $row->[$children->{NAME_lc_hash}{b1}];
        my $c = $row->[$children->{NAME_lc_hash}{b}];
        my $pt = $row->[$children->{NAME_lc_hash}{ptype}];
        # next unless (int($row->[$children->{NAME_lc_hash}{class}]) < 8);
        $children{$sid} = {
            'sid' =>  $sid,
            'name' => latex_encode($row->[$children->{NAME_lc_hash}{cname}]),
            'sex' => $row->[$children->{NAME_lc_hash}{csex}],
            'dob' => $row->[$children->{NAME_lc_hash}{cdob}],
            'class' => $row->[$children->{NAME_lc_hash}{class}]
        };
        $schools{$scode}{details}= {
            'scode' => $row->[$children->{NAME_lc_hash}{scode}],
            'stype' => $row->[$children->{NAME_lc_hash}{stype}],
            'b1' => $row->[$children->{NAME_lc_hash}{b1}],
            'b' => $row->[$children->{NAME_lc_hash}{b}],
            'name' => latex_encode($row->[$children->{NAME_lc_hash}{sname}]),
            'tname' => latex_encode($row->[$children->{NAME_lc_hash}{tname}]),
            'moi' => $row->[$children->{NAME_lc_hash}{moi}]
        };
        $schools{$scode}{pupils}{$sid} = 1;
        $parents{$sid}{$pt} = latex_encode($row->[$children->{NAME_lc_hash}{pname}]);
        $bh{$d}{$b}{$c}{$scode} = 1;
    }

    $data{children} = \%children;
    $data{parents} = \%parents;
    $data{schools} = \%schools;
    $data{hierarchy} = \%bh;
    
    return \%data;
}

sub make_cdata {
    my ($stu, $ch, $p) = @_;
   #print STDERR Dumper($stu);
   #print STDERR Dumper($ch);

    my @cdata;
    my @headers = qw(sid name sex dob class);
    # Sort kids by name
    my @keys = sort { $ch->{$a}{name} cmp $ch->{$b}{name} } keys %$stu;
    foreach my $s (@keys) {
        my %h = map { $_, $ch->{$s}{$_} } @headers;
        $h{father} = $p->{$s}{father};
        $h{mother} = $p->{$s}{mother};
        push(@cdata, (\%h));
        # push(@cdata, [ @{ $ch->{$s} }{@headers},
        #               $p->{$s}{father} || '-',
        #               $p->{$s}{mother} || '-' ]);
    }
    return \@cdata;
}

sub rearrange {
    my ($d, $f, $sz) = @_;

    use PDF::API2;
    use File::Copy;
    use Cwd;

    my $odir = getcwd();
    chdir($d);
    copy($f . '.pdf', 'q.pdf');
    
    system("gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -o q.pdf ${f}.pdf") == 0 
        or die("$d $f could not be changed to PDFv1.4");
  
    my $pdf = PDF::API2->open('q.pdf');
    my $np = $pdf->pages;

    unless (($np % $sz) == 0) {
        unlink('q.pdf');
        chdir($odir);
        open(ERRORS, ">> errors.txt") or die("Cannot open error file: $!");
        print ERRORS $d . $f, "\n";
        close(ERRORS);
        return;
    }

    my $step = $np/$sz;
    my $order;
    for (my $i=0; $i<$step; $i++) {
        for (my $j=1; $j<=$np; $j+=$step) {
            $order .= ($i+$j) . ' ';
            
        }
    }
    system("pdftk q.pdf cat $order output ${f}.reordered.pdf") == 0 
        or die("$d $f could not be rearranged");
    
    unlink('q.pdf');
    chdir($odir);
}

sub format_children_pdf {
    my $data = shift;

    my $tt = Template->new({
        # DEBUG => 'all',
        INCLUDE_PATH => '',
        OUTPUT_PATH => 'assessments/angdharwad',
        LATEX_PATH => '/usr/bin/xelatex',
        PDFLATEX_PATH => '/usr/bin/xelatex',
        LATEX_FORMAT => 'pdf'
    });
    foreach my $d (keys %{ $data->{hierarchy} }) {
        foreach my $b (keys %{ $data->{hierarchy}{$d} }) {
            foreach my $c (keys %{ $data->{hierarchy}{$d}{$b} }) {
                foreach my $sc (keys %{ $data->{hierarchy}{$d}{$b}{$c} }) {
                    my $dir = "assessments/angdharwad/${d}/${b}/${c}/";
                    (-d $dir) || 
                        (mkpath($dir) or die("Could not create dir $dir: $!"));
                    my $cdata = make_cdata($data->{schools}{$sc}{pupils}, 
                                           $data->{children},
                                           $data->{parents});
                    #print STDERR Dumper($cdata);
                    my $tdata = {
                        school => $data->{schools}{$sc}{details},
                        students => $cdata,
                        num_stu => scalar(@$cdata)
                    };
                    (my $filename = $tdata->{school}{name}) =~ s/[^[:alpha:][:digit:]]//g;
                    $filename = $sc . '-' . $filename;
                    $tt->process("$opts{t}", $tdata, "${d}/${b}/${c}/" . $filename . '.tex',{ binmode => ':encoding(UTF-8)' }) || warn $tt->error();
                    system("cd '$dir' && xelatex '$filename' && xelatex '$filename'");
                    rearrange($dir, $filename, 2);
                }
            }
        }
    }
}

#
# Start here

getopt('t', \%opts);
my $dbh = pgconnect;
my $d = get_students($dbh);
my $rc = format_children_pdf($d);

__END__
