use strict;
package Mail::Thread::Arc;
use base qw( Class::Accessor::Fast );
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

=head1 METHODS

=head2 new

Generic constructor

=cut

sub new {
    my $class = shift;
    bless {}, ref $class || $class;
}

=head2 render( $root_container, %options )

Renders the thread tree as an image arc.  Returns an Imager object.

=cut

sub render {
    my $self = shift;

    $self->imager( Imager->new );

    my @messages;
    # sort all the messages chronologically
    # find the generation depth of each message

    for my $message (@messages) {
        # place the message
        $self->draw_message( $message );
        next unless $message->parent;
        $self->draw_arc( $message->parent, $message );
    }

    return $self->imager;
}

sub draw_message {
}

sub draw_arc {
}

1;
__END__
