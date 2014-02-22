#!/usr/bin/perl

use strict;
use warnings;

use Template;
use Data::Dumper;
use File::Path;
use File::Find;
use LaTeX::Encode;
use Getopt::Std;
use Utility::KLPDB qw(pgconnect);
use Utility::FormID;

my %opts;

sub get_students {
    my ($file) = @_;
    open(INP, $file) || die "Cannot open $file: $!";
    my (%data, %children, %parents, %schools, %bh);
    while (<INP>) {
      chomp;
      my @d = split(/\|/);
      my $sid = $d[0];
        my $b2 = "\U$d[1]";
        my $b1 = "\U$d[2]";
        my $b = "\U$d[3]";
        my $sname= $d[4];
        my $class = $d[5];
        next unless ($class == $opts{c});
        $children{$sid} = {
            'sid' =>  $sid,
            'name' => latex_encode($d[6]),
            'sex' => $d[7],
            'class' => $class,
            'fname' => latex_encode($d[8]),
            'mname' => latex_encode($d[9]),
        };
        $schools{$sname}{details} = {
            'b1' => $d[2],
            'b' => $d[3],
            'name' => $d[4],
            'class' => $class,
        };
        $schools{$sname}{pupils}{$sid} = 1;
        $bh{$b2}{$b1}{$b}{$sname} = 1;
    }
    print scalar(keys %children), " children selected\n";

    $data{children} = \%children;
    $data{schools} = \%schools;
    $data{hierarchy} = \%bh;

    return \%data;
}

sub make_cdata {
    my ($stu, $ch, $p) = @_;

    my @cdata;
    my @headers = qw(sid name sex dob class sec fname mname);
    # Sort kids by name
    my @keys = sort { $ch->{$a}{class} <=> $ch->{$b}{class} 
                      || $ch->{$a}{sid} cmp $ch->{$b}{sid}
                      } keys %$stu;
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
        INCLUDE_PATH => 'templates',
        OUTPUT_PATH => 'assessments',
        LATEX_FORMAT => 'pdf'
    });
    my $formid = FormID::get();
    my $count = 0;
    foreach my $b2 (keys %{ $data->{hierarchy} }) {
        foreach my $b1 (keys %{ $data->{hierarchy}{$b2} }) {
            foreach my $b (keys %{ $data->{hierarchy}{$b2}{$b1} }) {
                foreach my $sc (keys %{ $data->{hierarchy}{$b2}{$b1}{$b} }) {
                    my $dir = "assessments/${b2}/${b1}/${b}/";
                    (-d $dir) || 
                        (mkpath($dir) or die("Could not create dir $dir: $!"));
                    my $cdata = make_cdata($data->{schools}{$sc}{pupils}, 
                                           $data->{children},
                                           $data->{parents});
                    my $tdata = {
                        school => $data->{schools}{$sc}{details},
                        students => $cdata,
                        num_stu => scalar(@$cdata),
                        formid => sprintf("%06d", $formid++)
                    };
                    (my $filename = $tdata->{school}{name}) =~ s/[^[:alpha:][:digit:]]//g;
                    $filename = $filename . '.' . $opts{c};
                    $tt->process($opts{t}, $tdata, "${b2}/${b1}/${b}/" . $filename . '.pdf') || warn $tt->error();
                    $count++;
                    # system("cd '$dir' && xelatex '$filename' && xelatex '$filename'");
                    # rearrange($dir, $filename, 4);
                }
            }
        }
    }
    print $count, ' files generated', "\n";
    FormID::save($formid);
}

sub mergePdfs
{
  my $mergeby = $opts{m};
  my $data = shift;
  my $odir = getcwd();
  foreach my $b2 (keys %{ $data->{hierarchy} }) {
    foreach my $b1 (keys %{ $data->{hierarchy}{$b2} }) {
      foreach my $b (keys %{ $data->{hierarchy}{$b2}{$b1} }) {
        if( $mergeby eq 'd' || $mergeby eq 'b' || $mergeby eq 'c')
        {
          my $dir = $odir."/assessments/${b2}/${b1}/${b}/";
          ${b} =~ s/\s+//g;
          my $outputfile = $odir."/assessments/${b2}/${b1}/Cluster_${b}_$opts{c}.pdf";
          chdir($dir);
          my $inputfile = "*$opts{c}.pdf";
          system("pdftk $inputfile cat output $outputfile") == 0 
          or die("Cluster pdfs could not be merged");
          
        }
      }
      if( $mergeby eq 'd' || $mergeby eq 'b' )
      {
        my $dir = $odir."/assessments/${b2}/${b1}/";
        ${b1} =~ s/\s+//g;
        my $outputfile = $odir."/assessments/${b2}/Block_${b1}_$opts{c}.pdf";
        chdir($dir);
        my $inputfile = "*$opts{c}.pdf";
        system("pdftk $inputfile cat output $outputfile") == 0 
        or die("Block pdfs could not be merged");
      }
    }
    if( $mergeby eq 'd')
    {
      my $dir = $odir."/assessments/${b2}/";
      ${b2} =~ s/\s+//g;
      my $outputfile = $odir."/assessments/District_${b2}_$opts{c}.pdf";
      chdir($dir);
      my $inputfile = "*$opts{c}.pdf";
      system("pdftk $inputfile cat output $outputfile") == 0 
      or die("District pdfs could not be merged");
    }
  }
}

#
# Start here
# pass -t templatefile -c classname 
getopt('qctfm', \%opts);
my $file="/home/shivangi/src/assessments/bangalore_1_post.csv";

my $d = get_students($file);
my $rc = format_children_pdf($d);
if( exists($opts{m}))
{
  mergePdfs($d);
}
__DATA__
