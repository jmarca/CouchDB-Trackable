use Test::Class::Sugar;
use Test::Moose;

use FindBin;
use lib "$FindBin::Bin/lib";

testclass exercises CouchDB::Trackable {

  use Exception::Class ( 'CouchDBError', );

    # Test::Most has been magically included
    # 'warnings' and 'strict' are turned on

    startup >> 2 {
        use_ok $test->subject;
        use_ok 'TrackableThing';
      }

my $cdb_user   = $ENV{COUCHDB_USER} || q{};
my $cdb_pass   = $ENV{COUCHDB_PASS} || q{};
my $cdb_host   = $ENV{COUCHDB_HOST} || '127.0.0.1';
my $cdb_dbname = $ENV{COUCHDB_DB}   || 'bananapancakes';
my $cdb_port   = $ENV{COUCHDB_PORT} || '5984';

                diag(   "environment vars used for testing CouchDB access\n"
                      . "CDB_USER          "
                      . $cdb_user . "\n"
                      . "CDB_PASS          "
                      . $cdb_pass . "\n"
                      . "CDB_PORT          "
                      . $cdb_port . "\n"
                      . "CDB_HOST          "
                      . $cdb_host
                      . "\n" );

    test creating a new tracking object >> 22{
       lives_and {
         my $tracker;
         my $e = eval{ $tracker = TrackableThing->new('host'=>'localhost','port'=>5984,'dbname'=>'bananapancakes','username'=>'james','password'=>'babasb'); };
         # catch
         isnt $e || $@ , undef, 'tracker creation should fail due to wrong parameter set';

         $tracker = TrackableThing->new('host_couchdb'=>'localhost','port_couchdb'=>5984,'dbname_couchdb'=>'bananapancakes','username_couchdb'=>'james','password_couchdb'=>'bababa');
         my $puke = eval{$tracker->create_db();} ;
         # catch
         $e = Exception::Class->caught('CouchDBError');
         isnt $e, undef , "database creation should fail here too...create bit unset, e is *$e*";
        $tracker = TrackableThing->new(
            'host_couchdb'     => $cdb_host,
            'port_couchdb'     => $cdb_port,
            'dbname_couchdb'   => $cdb_dbname,
            'username_couchdb' => $cdb_user,
            'password_couchdb' => $cdb_pass,
            'create'           => 1
        );
         eval{$tracker->create_db();} ;
         # catch
         $e = Exception::Class->caught('CouchDBError');
         is $e, undef , 'using proper parameterized parameter set';


         # test tracking a document
         my $row;
         $row = $tracker->track('id'=>'my document.tgz');
         is $row, 1, 'created a tracking document';

         my  $idlist = $tracker->all_docs();
         is $idlist->count,1,'expect one documen.t stored in db';
         my $doc = $idlist->next_key();
         is $doc, 'my document.tgz', "tracking a document called 'my document.tgz', and got $doc";
         is $row, 1, 'created a tracking document';

         $row = $tracker->track('id'=>'my document.tgz','row'=>30);
         is $row,30, "assign a value of 30 to the document, and row is  $row" ;
         $row = $tracker->track('id'=>'my document.tgz');
         is $row,30, "fetch the status of row value of 30 from a tracked document, and row is  $row" ;
         $row = $tracker->track('id'=>'my document.tgz','row'=>30, 'processed'=>1);
         is $row,-1, "tell the track db that the document is processed row=$row";
         
         $row = $tracker->track('id'=>'my document.tgz');
         is $row,-1, "see if the track db still thinks that the document is processed row=$row";
         
         # check names with slashes
         $row = $tracker->track('id'=>'/home/james/data/document.tgz','row'=>30);
         is $row,30, 'check names with slashes';
         $row = $tracker->track('id'=>'/home/james/data/document.tgz');
         is $row,30, 'check names with slashes';
         my $slashdoc = $tracker->get_doc('/home/james/data/document.tgz');
         is $slashdoc->{'row'},30, 'check names with slashes';

         # check that other data can also be stored in the document
         $row = $tracker->track('id'=>'/home/james/data/document.tgz','otherdata'=>{'my'=>'test','is'=>20});
         is $row,30, 'check that other data can be saved';
         my $moredoc = $tracker->get_doc('/home/james/data/document.tgz');
         diag( 'fetched document is ' , Data::Dumper::Dumper( $moredoc ) );
         is $moredoc->{'my'},'test', 'check that other data can be saved';
         is $moredoc->{'is'},20, 'check that other data can be saved';

         # check that other data can also be stored in a new document
         $row = $tracker->track('id'=>'/home/james/data/newdocument.tgz','otherdata'=>{'my'=>'test','is'=>20});
         is $row,1, 'check that other data can be saved in a new doc';
         my $moredoc = $tracker->get_doc('/home/james/data/newdocument.tgz');
         diag( 'fetched document is ' , Data::Dumper::Dumper( $moredoc ) );
         is $moredoc->{'my'},'test', 'check that other data can be saved in a new doc';
         is $moredoc->{'is'},20, 'check that other data can be saved in a new doc';


         # delete the test db

        my $rs =  $tracker->delete_db();
         diag( 'response to delete call is ' , Data::Dumper::Dumper( $rs ) );

         isa_ok $rs, 'DB::CouchDB::Result' , 'database deletion should pass here';
         is $rs->err, undef , 'database deletion should pass here';

       }
     };

}

Test::Class->runtests unless caller;
