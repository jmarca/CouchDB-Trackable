use Test::Class::Sugar;
use Test::Moose;

use FindBin;
use lib "$FindBin::Bin/lib";

testclass exercises CouchDB::Trackable {

    # Test::Most has been magically included
    # 'warnings' and 'strict' are turned on

    startup >> 2 {
        use_ok $test->subject;
        use_ok 'TrackableThing';
      }

    test creating a new tracking object >> 13{
       lives_and {
         my $tracker;
         my $e = eval{ $tracker = TrackableThing->new('host'=>'localhost','port'=>5984,'dbname'=>'bananapancakes','username'=>'james','password'=>'mgicn0mb3r'); };
         # catch
         isnt $e || $@ , undef, 'tracker creation should fail due to wrong parameter set';

         $tracker = TrackableThing->new('host_couchdb'=>'localhost','port_couchdb'=>5984,'dbname_couchdb'=>'bananapancakes','username_couchdb'=>'james','password_couchdb'=>'mgicn0mb3r');
         eval{$tracker->create_db();} ;
         # catch
         $e = Exception::Class->caught('CouchDBError');
         isnt $e, undef , 'database creation should fail here too...create unset';
         $tracker = TrackableThing->new('host_couchdb'=>'localhost','port_couchdb'=>5984,'dbname_couchdb'=>'bananapancakes','username_couchdb'=>'james','password_couchdb'=>'mgicn0mb3r','create'=>1);
         eval{$tracker->create_db();} ;
         # catch
         $e = Exception::Class->caught('CouchDBError');
         is $e, undef , 'using proper parameterized parameter set';


         # test tracking a document
         my $row;
         $row = $tracker->track('id'=>'my document.tgz');
         is $row, 1;
         $row = $tracker->track('id'=>'my document.tgz','row'=>30);
         is $row,30;
         $row = $tracker->track('id'=>'my document.tgz');
         is $row,30;
         $row = $tracker->track('id'=>'my document.tgz','row'=>30, 'processed'=>1);
         is $row,-1;
         


         my $rs =  $tracker->delete_db();
         diag( 'response to delete call is ' , Data::Dumper::Dumper( $rs ) );

         isa_ok $rs, 'DB::CouchDB::Result' , 'database deletion should pass here';
         is $rs->err, undef , 'database deletion should pass here';

       }
     };

}

Test::Class->runtests unless caller;
