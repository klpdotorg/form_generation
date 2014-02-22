package Utility::DBFunctions;

use strict;
use warnings;

require Exporter;
use DBI;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
        pgconnect
        db_get_value
	last_inserted_key
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

sub pgconnect {
    return (DBI->connect_cached('dbi:Pg:database=anginfo', 
                         'klp', 
                         'klp123', 
                         { AutoCommit => 0 ,
                           RaiseError => 1 }) 
                or die "Could not connect to the database\n");
}

sub db_get_value {
    my ($dbh, $query) = @_;
    my @row;
    my $qh;
    
    $qh = $dbh->prepare($query);
    $qh->execute() or die;
    
    @row = $qh->fetchrow_array() or return undef;
    return($row[0]);
}

# Postgres version
sub last_inserted_key {
    my ($dbh, $table, $pk) = @_;

    return $dbh->last_insert_id(undef, 'akshara', $table, undef, { sequence => $table . '_' . $pk . '_seq' });
}

# MySQL version
# sub last_inserted_key {
#     my ($dbh, $table, $pk) = @_;

#     return $dbh->last_insert_id(undef, undef, undef, undef);
# }
1;
