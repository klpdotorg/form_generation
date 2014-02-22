#!/usr/bin/perl

use strict;
use warnings;

use Template;
use Data::Dumper;
use File::Path;
use LaTeX::Encode;
use LaTeX::Table;

use Utility::KLPDB qw(pgconnect);
use Utility::FormID;

sub get_students {
    my $dbh = shift;

    my $children = $dbh->prepare(q{
select stu.id as sid,
       ARRAY_TO_STRING(ARRAY[c.first_name,c.middle_name,c.last_name],' ') as cname,
       ARRAY_TO_STRING(ARRAY[r.first_name,r.middle_name,r.last_name],' ') as pname,
       lower(r.relation_type) as ptype,
       ARRAY_TO_STRING(ARRAY[t.first_name,t.middle_name,t.last_name],' ') as tname,
       to_char(c.dob,'DD-MON-YYYY') as cdob,
       c.gender as csex,
       l.name as clang,
       s.id as scode, 
       s.name as sname,
       b2.name as b2,
       b1.name as b1,
       b.name as b
from     schools_institution s left outer join schools_staff t on (s.id=t.institution_id and t.staff_type_id=3),
 	 schools_studentgroup sg, 
	 schools_student_studentgrouprelation stusg, 
	 schools_student stu, schools_child c left outer join schools_moi_type l on (c.mt_id=l.id) left outer join schools_relations r on (c.id=r.child_id),schools_boundary b, 
	 schools_boundary b1, 
	 schools_boundary b2, 
 	 schools_boundary_type bt  
where 	
	 s.boundary_id = b.id 	
	 and b.parent_id= b1.id 
	 and b1.parent_id = b2.id 
 	 and b.boundary_type_id = 2  
	 and s.id = sg.institution_id 
	 and sg.id = stusg.student_group_id 
	 and sg.group_type='Class' 
	 and stusg.student_id = stu.id 
	 and stu.active = 2  
	 and stusg.academic_id = 122
	 and stu.child_id = c.id 
	 and s.active=2 
	 and stusg.active=2
	 and b2.id=8773
});
    $children->execute();
    my (%data, %children, %parents, %schools, %bh);
    while (my $row = $children->fetchrow_arrayref) {
        my $sid = $row->[$children->{NAME_lc_hash}{sid}];
        my $scode = $row->[$children->{NAME_lc_hash}{scode}];
        my $b2 = $row->[$children->{NAME_lc_hash}{b2}];
        my $b1 = $row->[$children->{NAME_lc_hash}{b1}];
        my $b = $row->[$children->{NAME_lc_hash}{b}];
        my $pt = $row->[$children->{NAME_lc_hash}{ptype}];
        $children{$sid} = {
            'sid' =>  $sid,
            'name' => latex_encode($row->[$children->{NAME_lc_hash}{cname}]),
            'sex' => $row->[$children->{NAME_lc_hash}{csex}],
            'dob' => $row->[$children->{NAME_lc_hash}{cdob}],
            'lang' => $row->[$children->{NAME_lc_hash}{clang}]
        };
        $schools{$scode}{details} = {
            'scode' => $row->[$children->{NAME_lc_hash}{scode}],
            'b1' => $row->[$children->{NAME_lc_hash}{b1}],
            'b' => $row->[$children->{NAME_lc_hash}{b}],
            'name' => latex_encode($row->[$children->{NAME_lc_hash}{sname}]),
            'tname' => latex_encode($row->[$children->{NAME_lc_hash}{tname}]),
        };
        $schools{$scode}{pupils}{$sid} = 1;
        $parents{$sid}{$pt} = latex_encode($row->[$children->{NAME_lc_hash}{pname}]);
        $bh{$b2}{$b1}{$b}{$scode} = 1;
    }

    $data{children} = \%children;
    $data{parents} = \%parents;
    $data{schools} = \%schools;
    $data{hierarchy} = \%bh;
    
    return \%data;
}

sub make_cdata {
    my ($stu, $ch, $p) = @_;

    my @cdata;
    my @headers = qw(sid name sex dob lang );
    # Sort kids by class, section, name
    my @keys = sort {
                         $ch->{$a}{name} cmp $ch->{$b}{name}
                     } keys %$stu;
    foreach my $s (@keys) {
        my %h = map { $_, $ch->{$s}{$_} } @headers;
        $h{father} = $p->{$s}{father};
        $h{mother} = $p->{$s}{mother};
        push(@cdata, (\%h));
    }
    return \@cdata;
}

sub format_children_pdf {
    my $data = shift;

    my $tt = Template->new({
        # DEBUG => 'all',
        INCLUDE_PATH => '',
        OUTPUT_PATH => 'angchildren/',
        LATEX_PATH => '/usr/bin/xelatex',
        PDFLATEX_PATH => '/usr/bin/xelatex',
        LATEX_FORMAT => 'pdf'
    });
    my $formid = FormID::get();

    foreach my $b2 (keys %{ $data->{hierarchy} }) {
        foreach my $b1 (keys %{ $data->{hierarchy}{$b2} }) {
            foreach my $b (keys %{ $data->{hierarchy}{$b2}{$b1} }) {
                foreach my $sc (keys %{ $data->{hierarchy}{$b2}{$b1}{$b} }) {
                    my $dir = "angchildren/${b2}/${b1}/${b}/";
                    (-d $dir) || 
                        (mkpath($dir) or die("Could not create dir $dir: $!"));
                    my $cdata = make_cdata($data->{schools}{$sc}{pupils}, 
                                           $data->{children},
                                           $data->{parents});
                    # my $t = LaTeX::Table->new({type => 'longtable',
                    #                            coldef => '|l|p{4cm}|l|l|l|r|l|p{4cm}|p{4cm}|',
                    #                            header => [ [ 'StuCode', 'Name', 'Sex', 'DoB', 'Language', 'Class', 'Section', 'Father', 'Mother' ] ],
                    #                            data => $cdata });
                    my $tdata = {
                        school => $data->{schools}{$sc}{details},
                        students => $cdata,
                        formid => sprintf("%06d", $formid++),
                        num_stu => scalar(@$cdata)
                    };
                    (my $filename = $tdata->{school}{name}) =~ s/[^[:alpha:][:digit:]]//g;
		    $filename = $sc . '-' . $filename . '.' . 'pdf';
                    $tt->process('ang-children.tt2', $tdata, "${b2}/${b1}/${b}/" . $filename) || warn $tt->error();
                }
            }
        }
    }
    FormID::save($formid);
}

#
# Start here

my $dbh = pgconnect;
my $d = get_students($dbh);
my $rc = format_children_pdf($d);

__END__
