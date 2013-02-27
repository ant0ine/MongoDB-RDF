package MongoDB::RDF::Serializer::NTriples;
use strict;
use warnings;

use base qw( MongoDB::RDF::Serializer );

use Encode;

=head1 DESCRIPTION

NTriples serialization

=cut

sub _object2value {
    my $class = shift;
    my ($object) = @_;
    my $v = $object->{value};
    if ($object->{type} eq 'uri') {
        return "<$v>";
    }
    else {
        return '"'.$class->_encode_literal($v).'"';
    }
}

sub _encode_literal {
    my $class = shift;
    my ($l) = @_;
    $l =~ s/\\/\\\\/g;
    $l =~ s/\n/\\n/g;
    $l =~ s/\r/\\r/g;
    $l =~ s/\t/\\t/g;
    $l =~ s/\"/\\"/g;
    return $l;
}

=head2 serialize_resource

=cut

sub serialize_resource {
    my $class = shift;
    my ($resource) = @_;
    my $subject = '<'.$resource->subject.'>';
    my @r;
    my $props = $resource->properties;
    for my $key (keys %$props) {
        my $predicate  = '<'.$key.'>';
        for my $obj (@{ $props->{$key} })  {
            my $object = $class->_object2value($obj);
            push @r, join ' ', $subject, $predicate, $object, '.';
        }
    }
    return join("\n", @r)."\n";
}

sub _save_triplet {
    my $class = shift;
    my ($graph, $s, $p, $o) = @_;
    my $resource = $graph->load($s) || MongoDB::RDF::Resource->new($s);
    $resource->add($p => $o);
    $graph->save($resource);
}

sub _clean_line {
    my $class = shift;
    my ($line) = @_;
    return unless defined $line;
    return if $line =~ /^#/;
    chomp $line;
    $line = Encode::decode_utf8($line);
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    return $line;
}

sub _decode_literal {
    my $class = shift;
    my ($l) = @_;
    $l =~ s/\\n/\n/g;
    $l =~ s/\\r/\r/g;
    $l =~ s/\\t/\t/g;
    $l =~ s/\\\"/"/g;
    $l =~ s/\\\\/\\/g;
    return $l;
}

=head2 deserialize_string_ref

=cut

sub deserialize_string_ref {
    my $class = shift;
    my ($ref, $graph) = @_;
    my $line = $class->_clean_line($$ref);

    return unless $line;
    # s, p, o
    if ($line =~ /^<([^>]+)>\s+<([^>]+)>\s+(?:<|")(.+)(?:>|")\s*\.$/) {
        my ($s, $p, $o) = ($1, $2, $3);
        $o = $class->_decode_literal($o);
        $class->_save_triplet($graph, $s, $p, $o);
    }
    else {
        warn "cannot parse line: $line";
    }
}

1;
