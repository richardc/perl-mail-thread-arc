use strict;
package Mail::Thread::Arc;
use Imager;
our $VERSION = '1.00';

=head1 NAME

Mail::Thread::Arc - Generates a Thread Arc reperesentation of a thread

=head1 SYNOPSIS

 my $threader = Mail::Thread->new( @messages );
 my $arc = Mail::Thread::Arc->new;

 $threader->thread;

 my $i;
 for my $thread ($threader->rootset) {
     ++$i;
     my $imager = $arc->render( $thread );
     $imager->write( file => "thread_$i.png" )
       or die $imager->errstr;
 }

=head1 DESCRIPTION

Mail::Thread::Arc takes a Mail::Thread::Container and generates an
image of the Thread Arc.  Thread Arcs are described in the
documentation for IBM's remail project.

http://www.research.ibm.com/remail/

=cut

sub new {
}

1;
__END__
