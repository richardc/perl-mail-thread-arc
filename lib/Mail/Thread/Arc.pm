use strict;
package Mail::Thread::Arc;
use SVG;
use Date::Parse qw( str2time );
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( messages width height svg ));

our $VERSION = '0.10';

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

The main method.

Renders the thread tree as a thread arc.  Returns an SVG object.

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
    $self->height( $self->maximum_arc_height * 2 + $self->message_radius * 6 );
    $self->svg( SVG->new( width => $self->width, height => $self->height ) );

    {
        # assign the numbers needed to compute X
        my $i;
        $self->messages( { map { $_ => ++$i } @messages } );
    }
    $self->draw_arc( $_->parent, $_ ) for @messages;
    $self->draw_message( $_ ) for @messages;

    return $self->svg;
}


=head2 draw_message( $message )

Draw the message on the SVG canvas.

=cut

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

=head2 draw_arc( $from, $to )

draws an arc between two messages

=cut

sub draw_arc {
    my ($self, $from, $to) = @_;

    return unless $from;

    my $distance = $self->message_x( $to ) - $self->message_x( $from );
    my $radius = $distance/ 2;

    my $top = $self->thread_generation( $to ) % 2;
    my $x = $self->message_x( $from );
    my $y = $self->message_y + ( $top ? -$self->message_radius : $self->message_radius);

    if ($radius > $self->maximum_arc_height) { # uh oh - trickyness
        my $max = $self->maximum_arc_height;
        # to Y - the relative part of the first curve
        my $toy = $top ? -$max : $max;
        my $toy2 = -$toy;
        my $x2 = $self->message_x( $to ) - $max;
        my $y2 = $y + $toy;

        $self->svg->path(
            d => join(' ',
                      "M $x,$y",                        #start the path
                      "a$max,$max 0 0,$top $max,$toy",  # arc up
                      "L $x2,$y2",                      # line across
                      "a$max,$max 0 0,$top $max,$toy2", # arc down
                     ),
            style => $self->arc_style( $from, $to ),
           );
    }
    else {
        $self->svg->path(
            d => "M $x,$y a$radius,$radius 0 1,$top $distance,0",
            style => $self->arc_style( $from, $to ),
           );
    }
}

=head2 message_radius

The radius of the message circles.  The most magic of all the magic
numbers.

=cut

sub message_radius { 5 }

=head2 message_style( $container )

Returns the style hash for the message circle.

=cut

sub message_style {
    my ($self, $message) = @_;

    return +{
        stroke         => 'red',
        fill           => 'white',
        'stroke-width' => $self->message_radius / 4,
    };
}

=head2 maximum_arc_height

the maximum height of an arc.  default is 17 message radii

=cut

sub maximum_arc_height {
    my $self = shift;
    return $self->message_radius * 17
}

=head2 arc_style( $from, $to )

Returns the style hash for the connecting arc,

=cut

sub arc_style {
    my ($self, $from, $to) = @_;
    return {
        fill   => 'none',
        stroke => 'black',
        'stroke-width' => $self->message_radius / 4,
    }
}

=head2 message_x( $container )

returns the X co-ordinate for a message

=cut

sub message_x {
    my ($self, $message) = @_;
    return $self->messages->{ $message } * $self->message_radius * 3;
}

=head2 message_y

returns the Y co-ordinate for a message (expected to be constant for
all messages)

=cut

sub message_y {
    my $self = shift;
    return $self->height / 2;
}

=head2 thread_generation( $message )

returns the thread generation of the container.

=cut

sub thread_generation {
    my ($self, $container) = @_;

    my $count = 0;
    while ($container->parent) {
        ++$count;
        $container = $container->parent;
    }

    return $count;
}

=head2 date_of( $container )

The date the message was sent, in epoch seconds

=cut

sub date_of {
    my ($self, $container) = @_;
    return str2time $container->header( 'date' );
}


1;
__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<ReMail|http://www.research.ibm.com/remail/>, the IBM Research
project that implements Thread Arcs.

L<http://unixbeard.net/~richardc/mta/> - some sample output, alongside
.pngs created with batik-rasteriser.

L<Mail::Thread>, L<Mail::Thread::Chronological>, L<SVG>

=cut
