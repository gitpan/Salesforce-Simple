package Salesforce::Simple;

use 5.008007;
use strict;
use warnings;
use Carp;
use Exporter;
use Salesforce;

#handle versioning and exporting
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );
$VERSION = '0.04';
@ISA = qw(
    Exporter
);
@EXPORT = qw( );
@EXPORT_OK = qw( );

#add some scoping help to the module
{
    #**************************************************************************
    # new( %params ) ------CONSTRUCTOR
    #   -- make a connection to salesforce using the API
    #**************************************************************************
    sub new {
        my ( $class, %params ) = @_;

        #setup the object's defaults
        my $self = {
            sf_service => '',
            sf_port => '',
            sf_username => $params{'username'},
            sf_password => $params{'password'},
        };

        bless $self, $class;

        #connect using the proper username and password
        my $service = Salesforce::SforceService->new();
        my $port = $service->get_port_binding( 'Soap' );
        $port->login(
            'username' => $self->{'sf_username'},
            'password' => $self->{'sf_password'}
        ) or croak( "Couldn't login to salesforce! $!" );

        #set the service and port
        $self->{'sf_service'} = $service;
        $self->{'sf_port'} = $port;

        return $self;
    }

    #**************************************************************************
    # do_query( $query )
    #   -- returns an array of hash refs
    #**************************************************************************
    sub do_query {
        my ( $self, $query ) = @_;

        croak( 'Param1 of do_query() should be a string SQL query' )
            unless defined $query and $query =~ m/^select/i;

        my @rows = (); #to be returned

        my $res = $self->{'sf_port'}->query( query => $query, limit => 2000 );

        croak( $res->faultstring() ) if $res->fault();

        push @rows, $res->valueof( '//queryResponse/result/records' )
            if ( $res->valueof( '//queryResponse/result/size' ) > 0 );

        #we get the results in batches of 2,000... so continue getting them
        #if there are more to get
        my $done = $res->valueof( '//queryResponse/result/done' );
        my $ql = $res->valueof( '//queryResponse/result/queryLocator' );
        while ( $done eq 'false' ) {
            $res = $self->{'sf_port'}->queryMore(
                queryLocator => $ql,
                limit => 2000
            );

            croak( $res->faultstring() ) if $res->fault();
            $done = $res->valueof( '//queryMoreResponse/result/done' );
            $ql = $res->valueof( '//queryMoreResponse/result/queryLocator' );
            push @rows, $res->valueof( '//queryMoreResponse/result/records' )
                if ( $res->valueof( '//queryMoreResponse/result/size' ) );
        }

        return \@rows;
    }

    #**************************************************************************
    # get_field_list( $table_name )
    #   -- returns a ref to an array of hash refs for each field name...
    #       --field name keyed as 'name'
    #**************************************************************************
    sub get_field_list {
        my ( $self, $table_name ) = @_;

        croak( 'Param1 of get_field_list() should be a string' )
            unless defined $table_name and length $table_name;

        my $res = $self->{'sf_port'}->describeSObject( 'type' => $table_name );
        croak( $res->faultstring() ) if $res->fault();

        my @fields = $res->valueof( '//describeSObjectResponse/result/fields' );
        return \@fields;
    }

    #**************************************************************************
    # get_tables()
    #   -- returns an array reference to a list of tables salesforce has
    #**************************************************************************
    sub get_tables {
        my ( $self ) = @_;

        my $res = $self->{'sf_port'}->describeGlobal();
        croak( $res->faultstring() ) if $res->fault();

        my @globals = $res->valueof( '//describeGlobalResponse/result/types' );
        return \@globals;
    }

} #end of package scope

1; #magically delicious

=pod

=head1 NAME

Salesforce::Simple.pm v0.04

=head1 DESCRIPTION

Because the Salesforce API is somewhat cumbersome to deal with, this class
was created to make it a little simpler to get information.

=head1 METHODS

=head2 new( %parameters )

Handles creating new Salesforce objects as well as the login process
to use the salesforce objects. You can optionally set the username and
password to login to salesforce with a hash ref with a username and or
password key if you need to use a user other than the default user.

=head2 do_query( $sql_query_string )

Executes a query against the information in Salesforce.  Returns a reference
to an array of hash references keyed by the column names. Strict attention
should be paid to the case of the field names.

=head2 get_field_list( $table_name )

Gathers a list of fields contained in a given table.  Returns a reference
to an array of hash references.  The hash references have several keys
which provide information about the field's type, etc.  The key 'name'
will provide the name of the field itself.

=head2 get_tables( )

Gathers a list of tables available for use from salesforce.  Returns a
reference to an array of strings representing each table name.


=head1 EXAMPLES

=head2 new()

    use Salesforce::Simple;

    my $sforce = Salesforce::Simple->new();
    #or
    my $sforce = Salesforce::Simple->new(
        -username=>'someuser',
        -password=>'somepass'
    );

=head2 do_query( $query )

    my $query = 'select Id from Account';

    my $res = $sforce->do_query( $query );

    foreach my $field ( @{ $res } ) {
        print $field->{'Id'} . "\n";
    }
    print "Found " . scalar @{$res} . " results\n";    

=head2 get_field_list( $table_name )

    my $fields_ref = $sforce->get_field_list( 'Account' );

    foreach my $field( @{$fields_ref} ) {
        print $field->{'name'} . "\n";
        foreach my $key ( keys %{$field} ) {
            print "\t $key --> ";
            print $field->{$key} if ( $field->{$key} );
            print "\n";
        }
        print "\n";
    }

=head2 get_tables()

    my $tables_ref = $sforce->get_tables();

    foreach my $table ( @{$tables_ref} ) {
        print "$table\n";
    }
    print "\n";

=head1 SUPPORT

Please visit Salesforce.com's user/developer forums online for assistance with
this module. You are free to contact the author directly if you are unable to
resolve your issue online.

=head1 AUTHORS

Chase Whitener <cwhitener at gmail dot com>

=head1 VERSION INFORMATION

version 0.04
released 2006-01-06
    -fixed some documentation errors, made the module ready to be posted to CPAN

version 0.03
released 2005-10-31
    -fixed some line length issues, added ability to change username
    and password by parameters to the constructor -username => ''
    -password => ''

=head1 COPYRIGHT

No Copyright
