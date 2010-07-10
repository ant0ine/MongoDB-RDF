package MongoDB::RDF;

use warnings;
use strict;

use MongoDB::RDF::Graph;
use MongoDB::RDF::Namespace;
use MongoDB::RDF::Resource;

our $VERSION = '0.01';

=head1 NAME

MongoDB::RDF - Stores RDF-JSON documents in MongoDB.

=head1 SYNOPSIS

 my $mrdf = MongoDB::RDF->new(
     database => MongoDB::Connection->new(host => 'localhost', port => 27017)->test_rdf
 );
 
 my $graph = $mrdf->default_graph;
 
 my $r = MongoDB::RDF::Resource->new('http://example.org/0');
 $r->dc_title('my title');
 $graph->save($r);

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $db = $args{database}
        or die 'database required';
    return bless { database => $db }, $class;
}

=head2 database

Returns the MongoDB::Database object.

=cut

sub database { $_[0]->{database} }

=head2 default_graph

Returns the default graph object.

=cut

sub default_graph {
    my $self = shift;
    return $self->get_graph('default');
}

=head2 get_graph( $name )

Returns the graph named $name, creates it if it doesn't exist.
(A graph is mapped to a MongoDB::Collection)

=cut

sub get_graph {
    my $self = shift;
    my ($name) = @_;
    return MongoDB::RDF::Graph->new(
        name => $name,
        mrdf => $self,
    );
}

=head1 AUTHOR

Antoine Imbert, C<< <antoine.imbert at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodb-rdf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDB-RDF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MongoDB::RDF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDB-RDF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDB-RDF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDB-RDF>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDB-RDF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Antoine Imbert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
