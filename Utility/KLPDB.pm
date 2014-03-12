package Utility::KLPDB;

use strict;
use warnings;

require Exporter;
use DBI;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
        connect
        pgconnect
        pgconnect_repl
        db_get_value
        last_inserted_key
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

$ENV{PGPASSWORD}='never3v3r4g4in';

sub connect {
     print $ENV{KLP_DB};
    return (DBI->connect_cached('dbi:Oracle:' . $ENV{KLP_DB}, 
                                $ENV{KLP_USER}, 
                                $ENV{KLP_PASSWD}, 
                                { AutoCommit => 0 ,
                                  RaiseError => 1,
                                  FetchHashKeyName => "NAME_lc" }) 
                or die "Could not connect to the database\n");
}


sub pgconnect {
    return (DBI->connect_cached('dbi:Pg:database=klpproduction;host=localhost',
                         'klp',$ENV{PGPASSWORD},
                         { AutoCommit => 0 ,
                           RaiseError => 1 })
                or die "Could not connect to the database\n");
}

sub pgconnect_repl {
    return (DBI->connect_cached('dbi:Pg:database=klpmaster_repl;host=localhost',
                         'klp',$ENV{PGPASSWORD},
                         { AutoCommit => 0 ,
                           RaiseError => 1 })
                or die "Could not connect to the database\n");
}

    
