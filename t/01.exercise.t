use Test::Class::Sugar;
use Test::Moose;
use Data::Dumper;

testclass exercises CouchDB::Trackable {

{
package TrackableThing;
use Moose;
with 'CouchDB::Trackable';
}

    # Test::Most has been magically included
    # 'warnings' and 'strict' are turned on

    startup >> 1 {
        use_ok $test->subject;
      }

    test creating a new tracking object >> 13{
       lives_and {
         my $tracker = TrackableThing->new('host'=>'localhost','port'=>5984,'dbname'=>'bananapancakes','username'=>'james','password'=>'mgicn0mb3r');
         isa_ok  $tracker => 'TrackableThing';
         Test::Moose::does_ok  $tracker => $test->subject;
         is $tracker->create, 0, 'auto create is not on';
         eval{my $snuff = $tracker->create_db();
            } ;
         my $e;

         # catch
         $e = Exception::Class->caught('CouchDBError');
         isnt $e, undef , 'database creation should fail here';

         $tracker = TrackableThing->new('host'=>'localhost','port'=>5984,'dbname'=>'bananapancakes','username'=>'james','password'=>'mgicn0mb3r','create'=>1);
         eval{$tracker->create_db();} ;
         # catch
         $e = Exception::Class->caught('CouchDBError');
         is $e, undef , 'database creation should pass here';


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
