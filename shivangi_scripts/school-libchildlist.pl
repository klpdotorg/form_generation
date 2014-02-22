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
       stu."otherStudentId" as otherid,
       ARRAY_TO_STRING(ARRAY[c."firstName",c."middleName",c."lastName"],' ') as cname,
       ARRAY_TO_STRING(ARRAY[r.first_name,r.middle_name,r.last_name],' ') as pname,
       lower(r.relation_type) as ptype,
       to_char(c.dob,'DD-MON-YYYY') as cdob,
       c.gender as csex,
       l.name as clang,
       sg.name as class, 
       sg.section as section,
       s.id as scode, 
       s.name as sname,
       b2.name as b2,
       b1.name as b1,
       b.name as b
from schools_institution s, schools_studentgroup sg, schools_student_studentgrouprelation stusg, schools_student stu, schools_child c left outer join schools_moi_type l on (c.mt_id=l.id) left outer join schools_relations r on (c.id=r.child_id),schools_boundary b, schools_boundary b1, schools_boundary b2, schools_boundary_type bt  where s.boundary_id = b.id and b.parent_id= b1.id and b1.parent_id = b2.id and b.boundary_type_id = 1  and s.id = sg.institution_id and sg.id = stusg.student_group_id and sg.group_type='Class' and stusg.student_id = stu.id and stu.active = 2 and stusg.academic_id = 121 and stu.child_id = c.id and sg.name in ('1','2','3','4','5','6','7') and b2.id=8877 and s.active=2 
--and s.id in (32319,32326,32321,32327,32317,32331,32333,32176,32614,32620,33431,33432,32809,32626,32633,32814,32615,32621,32625,32617,32632,32616,32815,33388,32627,32629,32630,32803,32805,32813,32318,32618,32628,32622,32624,32332,32322,33439,32804,32810,33443,32801,32808,32811,32807,32802,32852,32853,33394,32704,32712,32713,33375,32948,32851,32855,32859,32860,33398,32915,32913,33389,32861,32857,32854,32858,33393,33399,33396,32917,32918,32920,32923,32914,33203,33378,32946,32951,32956,32960,32961,32962,32963,33391,32922,32949,32952,32953,32959,32944,33382,33390,33379,32162,32161,32163,32470,32472,32471,32165,32164,32473,32166,33176,33175,33164,32024,32025,32028,32031,32032,32029,32030,32027,32026,32507,32205,32211,32213,32689,32693,32688,32692,32203,32204,33151,33150,33153,33147,33149,33156,33158,33161,33148,33152,33155,33159,32102,32095,32104,32610,32612,32613,33145,32179,32169,32177,32171,32696,32694,32508,33154,32074,32073,32180,32181,32184,32697,32309,32075,32509,33160,33264,33268,33258,33261,33257,33255,33256,33259,33202,32170,32033,32479,33201,33203,33205,32034,32035,32936,32880,32887,32888,32889,32886,32884,32894,32878,33137,33127,32263,32268,33131,33134,33133,32554,32259,32264,32265,32553,32560,33119,33122,33123,32557,32356,32357,32562,32139,32142,33107,33109,33108,32556,32552,32146,32144,32561,32145,32147,32148,32096,32551,32550,32555,32558,32559,32138,32140,33110,32103,32094,32262,32267,32258,33117,32788,32792,32794,32795,32728,32503,32505,32506,32504,32895,32908,32911,32912,32646,32649,32897,32900,32905,32898,32904,33338,33341,33340,33335,32790,32791,32800,32799,32789,32797,32796,32594,32591,32593,32840,32598,32786,32787,32604,32605,33326,33330,32793,33328,33321,33320,33323,33322,33325,33324,32495,32501,33313,33319,33318,32206)
and s.id in (32615)
and stu.id not in (select stusg1.student_id from schools_student_studentgrouprelation stusg1,schools_studentgroup sg1 where stusg1.academic_id=102 and stusg1.student_group_id=sg1.id and 
--sg1.institution_id in (32319,32326,32321,32327,32317,32331,32333,32176,32614,32620,33431,33432,32809,32626,32633,32814,32615,32621,32625,32617,32632,32616,32815,33388,32627,32629,32630,32803,32805,32813,32318,32618,32628,32622,32624,32332,32322,33439,32804,32810,33443,32801,32808,32811,32807,32802,32852,32853,33394,32704,32712,32713,33375,32948,32851,32855,32859,32860,33398,32915,32913,33389,32861,32857,32854,32858,33393,33399,33396,32917,32918,32920,32923,32914,33203,33378,32946,32951,32956,32960,32961,32962,32963,33391,32922,32949,32952,32953,32959,32944,33382,33390,33379,32162,32161,32163,32470,32472,32471,32165,32164,32473,32166,33176,33175,33164,32024,32025,32028,32031,32032,32029,32030,32027,32026,32507,32205,32211,32213,32689,32693,32688,32692,32203,32204,33151,33150,33153,33147,33149,33156,33158,33161,33148,33152,33155,33159,32102,32095,32104,32610,32612,32613,33145,32179,32169,32177,32171,32696,32694,32508,33154,32074,32073,32180,32181,32184,32697,32309,32075,32509,33160,33264,33268,33258,33261,33257,33255,33256,33259,33202,32170,32033,32479,33201,33203,33205,32034,32035,32936,32880,32887,32888,32889,32886,32884,32894,32878,33137,33127,32263,32268,33131,33134,33133,32554,32259,32264,32265,32553,32560,33119,33122,33123,32557,32356,32357,32562,32139,32142,33107,33109,33108,32556,32552,32146,32144,32561,32145,32147,32148,32096,32551,32550,32555,32558,32559,32138,32140,33110,32103,32094,32262,32267,32258,33117,32788,32792,32794,32795,32728,32503,32505,32506,32504,32895,32908,32911,32912,32646,32649,32897,32900,32905,32898,32904,33338,33341,33340,33335,32790,32791,32800,32799,32789,32797,32796,32594,32591,32593,32840,32598,32786,32787,32604,32605,33326,33330,32793,33328,33321,33320,33323,33322,33325,33324,32495,32501,33313,33319,33318,32206)
sg1.institution_id in (32615)
)
and stu."otherStudentId" is not null
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
        next unless (int($row->[$children->{NAME_lc_hash}{class}]) < 8);
        $children{$sid} = {
            'sid' =>  $sid,
            'otherid' => $row->[$children->{NAME_lc_hash}{otherid}],
            'name' => latex_encode($row->[$children->{NAME_lc_hash}{cname}]),
            'sex' => $row->[$children->{NAME_lc_hash}{csex}],
            'dob' => $row->[$children->{NAME_lc_hash}{cdob}],
            'lang' => $row->[$children->{NAME_lc_hash}{clang}],
            'class' => int($row->[$children->{NAME_lc_hash}{class}]),
            'sec' => $row->[$children->{NAME_lc_hash}{sec}],
        };
        $schools{$scode}{details} = {
            'scode' => $row->[$children->{NAME_lc_hash}{scode}],
            'b1' => $row->[$children->{NAME_lc_hash}{b1}],
            'b' => $row->[$children->{NAME_lc_hash}{b}],
            'name' => latex_encode($row->[$children->{NAME_lc_hash}{sname}]),
        };
        $schools{$scode}{pupils}{$sid} = 1;
        $parents{$sid}{$pt} = latex_encode($row->[$children->{NAME_lc_hash}{pname}]);
        $bh{$b2}{$b1}{$b}{$scode} = 1;
    }
    print scalar(keys %children), " children to be verified\n";

    $data{children} = \%children;
    $data{parents} = \%parents;
    $data{schools} = \%schools;
    $data{hierarchy} = \%bh;
    
    return \%data;
}

sub make_cdata {
    my ($stu, $ch, $p) = @_;

    my @cdata;
    my @headers = qw(sid otherid name sex dob lang class sec);
    # Sort kids by class, section, name
    my @keys = sort {$ch->{$a}{class} <=> $ch->{$b}{class} ||
                         $ch->{$a}{sec} cmp $ch->{$b}{sec} ||
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
        INCLUDE_PATH => 'templates',
        OUTPUT_PATH => 'schoolchildren'
    });
    my $formid = FormID::get();

    foreach my $b2 (keys %{ $data->{hierarchy} }) {
        foreach my $b1 (keys %{ $data->{hierarchy}{$b2} }) {
            foreach my $b (keys %{ $data->{hierarchy}{$b2}{$b1} }) {
                foreach my $sc (keys %{ $data->{hierarchy}{$b2}{$b1}{$b} }) {
                    my $dir = "schoolchildren/${b2}/${b1}/${b}/";
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
                        formid => sprintf("%06d", $formid++)
                    };
                    # print Dumper($cdata);
                    (my $filename = $tdata->{school}{name}) =~ s/[^[:alpha:][:digit:]]//g;
                    $filename = $sc . '-' . $filename . '.' . 'pdf';
                    $tt->process('school-libchildren.tt2', $tdata, "${b2}/${b1}/${b}/" . $filename) || warn $tt->error();
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
