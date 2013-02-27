package MongoDB::RDF::Serializer;
use strict;
use warnings;

=head2 $class->dump( resource => ... )

or

 $class->dump( graph => ... )
 $class->dump( graph => ..., filename => ... )
 $class->dump( graph => ..., find => ...,  filename => ... )
 $class->dump( graph => ..., find => ..., limit => ..., sort => ..., filename => ... )

=cut

sub dump {
    my $class = shift;
    my %args = @_;

    my $fh;
    if (my $fn = $args{filename}) {
        $fh = IO::File->new(">$fn")
            or die "cannot open $fn for writing";
    }

    if ($args{resource}) {
        $class->_print($fh, $class->serialize_resource($args{resource}) );
    }
    elsif (my $graph = $args{graph}) {
        my $query = $args{find} || {};
        my $cursor = $graph->find($query);
        $cursor->sort($args{sort}) if $args{sort};
        $cursor->limit($args{limit}) if $args{limit};

        while (my $resource = $cursor->next()) {
            $class->_print($fh, $class->serialize_resource($resource));
        }

    }
    else {
        die "graph or resource required";
    }

    $fh->close if $fh;
}

sub _print {
    my $class = shift;
    my ($fh, $string) = @_;
    if ($fh) {
        print $fh $string;
    }
    else {
        print STDOUT $string;
    }
}

=head2 $class->serialize_resource($resource)

To be overwritten in the subclasses
Used by dump.

=cut

sub serialize_resource { die 'to be overwritten' }

=head2 $class->load( graph => ..., filename => ... )

or
 $class->load( graph => ... ); # read STDIN

=cut

sub load {
    my $class = shift;
    my %args = @_;

    my $fh;
    if (my $fn = $args{filename}) {
        $fh = IO::File->new("<$fn")
            or die "cannot open $fn for reading";
    }

    my $graph = $args{graph} or die "graph required";


    while (my $string_ref = $class->_next_string_ref($fh)) {
       $class->deserialize_string_ref($string_ref, $graph);
    }

    $fh->close if $fh;
}

# The default _next_string_ref returns a line
# can be overwritten to fit the need of the subclass.

# potential prefered input for a subclass:
# - filehandle
# - a ref to the complete file content
# - a ref to a chunk of the file content
# - a line
sub _next_string_ref {
    my $class = shift;
    my ($fh) = @_;
    my $line = $fh ? <$fh> : <>;
    return $line ? \$line  : undef;
}

=head2 $class->deserialize_string_ref( $string_ref )

=cut

sub deserialize_string_ref { die 'to be overwritten' }

1;
