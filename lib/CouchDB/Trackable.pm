use strict;
use warnings;
use MooseX::Declare;

role CouchDB::Trackable {

  use version; our $VERSION = qv('0.0.2');
  use DB::CouchDB;
  use Exception::Class ( 'CouchDBError', );

    method _build__connection_couchdb {
        my $conn = DB::CouchDB->new(
            host     => $self->host_couchdb,
            port     => $self->port_couchdb,
            db       => $self->dbname_couchdb,
            user     => $self->username_couchdb,
            password => $self->password_couchdb,
        );

        # create or not
        my $dbinfo = $conn->db_info();

        #returns a DB::CouchDB::Result with the db info if it exists
        if ( $dbinfo->err && $self->create ) {
            $dbinfo = $conn->create_db();
        }
        if ( $dbinfo->err ) {
            my $info_string =
              $self->dbname_couchdb . ' on host ' . $self->host_couchdb . ':' . $self->port_couchdb;
            CouchDBError->throw( error =>
                  "cannot find or create couchdb database $info_string " );
            return;
        }
        $conn->handle_blessed(1);
        return $conn;
    }


   with 'DB::Connection' => {
       'name'            => 'couchdb',
       'connection_type' => 'DB::CouchDB',
       'connection_delegation' =>
         qr/^(.*)/sxm,
     };



    has 'create' => (
        is      => 'ro',
        isa     => 'Bool',
        default => 0,
    );

    # has _connection => (
    #     is         => 'ro',
    #     isa        => 'DB::CouchDB',
    #     lazy_build => 1,
    #     handles =>
    #       qr/^(?:get.*|bulk.*|json.*|handle*|create.*|update.*|delete.*)/sxm,

    # );

    method track( Str :$id, Int :$row = 1, Int :$processed = 0, HashRef :$otherdata? ) {
        my $need_to_save = 0;
        my $canonical_id = $id;
        # $canonical_id =~ s/\//-/gsxm;
        my $doc = $self->_connection_couchdb->get_doc($canonical_id);
        if ( !$doc->err ) {

            # have an existing doc
            if ($processed) {
                $doc->{'processed'} = 1;
                $need_to_save = 1;
            }
            if ( $row > 1 ) {
                if ( !$doc->{'row'} || $doc->{'row'} <= $row ) {
                    $doc->{'row'} = $row;
                    $need_to_save = 1;
                }
            }

            # save any other data that might be relevant
            if ($otherdata) {
                map { $doc->{$_} = $otherdata->{$_} } keys %{$otherdata};
                $need_to_save = 1;
            }

            # report back where we are
            if ( $doc->{'processed'} ) {
                $row = -1;
            }
            elsif ( $doc->{'row'} ) {
                $row = $doc->{'row'};
            }
        }
        else {

            # no document exists.  create it
            $doc = { '_id' => $canonical_id, 'row'=>$row };
            if ($processed) {
                $doc->{'processed'} = 1;
            }

            # save any other data that might be relevant
            if ($otherdata) {
                map { $doc->{$_} = $otherdata->{$_} } keys %{$otherdata};
            }
            $need_to_save = 1;
        }
        if ($need_to_save) {
            $self->_connection_couchdb->create_named_doc( { 'doc' => $doc } );
        }

        # report back where we are (0, 1, or some number)
        return $row;
      }

}

1;    # Magic true value required at end of module

__END__

=head1 NAME

CouchDB::Trackable - [One line description of module's purpose here]


=head1 VERSION

This document describes CouchDB::Trackable version 0.0.1


=head1 SYNOPSIS

    use CouchDB::Trackable;

=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS


=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT

CouchDB::Trackable requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-couchdb-trackable@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  Or email them to me, as it is likely this will
never get posted to CPAN.


=head1 AUTHOR

James E. Marca  C<< <jmarca@translab.its.uci.edu> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, James E. Marca C<< <jmarca@translab.its.uci.edu> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
