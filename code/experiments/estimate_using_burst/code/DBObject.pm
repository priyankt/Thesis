package DBObject;

use strict;
use warnings;
use DBI;

my $dsn = 'dbi:mysql:priti063:www-und.ida.liu.se:3306';
my $user = 'priti063';
my $passwd = 'priti063258c';

sub new {
    my $class = shift;
    my $dbh = DBI->connect($dsn, $user, $passwd) or die "Unable to connect to db - $!";
    my $self = {
	dbh => $dbh,
    };

    bless $self, $class;
    return $self;
}

sub close {
    my $self = shift;
    $self->{dbh}->disconnect();
}

1;
