use strict;
package Mail::Thread::Arc;
use Imager;
use Date::Parse qw( str2time );
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( messages imager ));

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
    my $root = shift;

    # extract just the containers with messages
    my @messages;
    $root->iterate_down(
        sub {
            my $container = shift;
            push @messages, $container if $container->message;
        } );

    # sort on date
    @messages = sort {
        $self->date_of( $a ) <=> $self->date_of( $b )
    } @messages;

    my $imager = Imager->new(
        xsize => ( @messages + 1 ) * $self->message_radius * 3,
        ysize => $self->message_radius * 2 + $self->max_arc_radius * 2,
       )
      or die Imager->errstr;

    $self->imager( $imager );

    $self->imager->flood_fill( x => 1, y => 1, color => '#ffffff' );


    $self->messages( {} );
    my $i;
    for my $message (@messages) {
        # place the message
        $self->messages->{$message} = ++$i;
        $self->draw_message( $message );
        next unless $message->parent;
        $self->draw_arc( $message->parent, $message );
    }

    return $self->imager;
}

sub message_radius {
    20;
}

sub max_arc_radius {
    20;
}

sub date_of {
    my ($self, $container) = @_;
    return str2time( Email::Thread->_get_hdr( $container->message, 'date' ) );
}

sub draw_message {
    my ($self, $message) = @_;
    $self->imager->circle(
        color => '#000000',
        r => $self->message_radius,
        x => $self->message_x( $message ),
        'y' => $self->max_arc_radius + $self->message_radius,
       );
}

sub message_x {
    my ($self, $message) = @_;
    return $self->messages->{ $message } * $self->message_radius * 3;
}

sub draw_arc {
    my ($self, $from, $to) = @_;

    my $radius = ($self->message_x( $to ) - $self->message_x( $from )) / 2;
    my $center = $self->message_x( $from ) + $radius;

    my %args = (
        color => '#000000',
        fill  => 0,
        r => $radius,
        x => $center,
    );

    if ($self->thread_generation( $to ) % 2) {
        # draw arc above
        @args{qw( d1 d2 y )} = (180, 0, $self->max_arc_radius);
    }
    else {
        # draw arc below
        @args{qw( d1 d2 y )} = (0, 180, $self->max_arc_radius + $self->message_radius * 2);
    }

    $self->imager->arc( %args );
}

sub thread_generation {
    my ($self, $container) = @_;

    my $count = 0;
    while ($container->parent) {
        ++$count;
        $container = $container->parent;
    }

    return $count;
}

1;
__END__
