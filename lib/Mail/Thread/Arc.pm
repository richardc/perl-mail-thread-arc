use strict;
package Mail::Thread::Arc;
use SVG;
use Date::Parse qw( str2time );
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( messages width height svg ));

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
     my $svg = $arc->render( $thread );
     write_file( "thread_$i.svg", $svg->xmlify );
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

    $self->width( ( @messages + 1 ) * $self->message_radius * 3 );
    $self->height( $self->width );
    $self->svg( SVG->new( width => $self->width, height => $self->height ) );

    $self->messages( {} );
    my $i;
    for my $message (@messages) {
        # place the message
        $self->messages->{$message} = ++$i;
        $self->draw_message( $message );
        next unless $message->parent;
        $self->draw_arc( $message->parent, $message );
    }

    return $self->svg;
}

sub message_radius {
    7;
}

sub date_of {
    my ($self, $container) = @_;
    return str2time $container->header( 'date' );
}

sub message_style {
    my ($self, $message) = @_;

    return +{
        stroke         => 'red',
        fill           => 'white',
        'stroke-width' => $self->message_radius / 4,
    };
}

sub draw_message {
    my ($self, $message) = @_;

    my $group = $self->svg->group;
    $group->title->cdata( $message->header('from') );
    $group->desc->cdata( "Date: " . $message->header('date') );
    $group->circle(
        cx => $self->message_x( $message ),
        cy => $self->message_y,
        r  => $self->message_radius,
        style => $self->message_style( $message ),
       );
}

sub message_x {
    my ($self, $message) = @_;
    return $self->messages->{ $message } * $self->message_radius * 3;
}

sub message_y {
    my $self = shift;
    return $self->height / 2;
}

sub arc_style {
    return {
        fill   => 'none',
        stroke => 'black',
        'stroke-width' => 2,
    }
}

sub draw_arc {
    my ($self, $from, $to) = @_;

    my $distance = $self->message_x( $to ) - $self->message_x( $from );
    my $radius = $distance/ 2;

    my $top = $self->thread_generation( $to ) % 2;
    my $x = $self->message_x( $from );
    my $y = $self->message_y + ( $top ? -$self->message_radius : $self->message_radius);
    $self->svg->path(
        d => "M $x,$y a$radius,$radius 0 1,$top $distance,0",
        style => $self->arc_style( $from, $to ),
       );
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
