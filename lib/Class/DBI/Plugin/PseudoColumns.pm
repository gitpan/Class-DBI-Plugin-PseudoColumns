package Class::DBI::Plugin::PseudoColumns;

use strict;
use warnings;
use Carp;
use Data::Dumper ();
use vars qw($VERSION);
$VERSION = 0.01;

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    no strict 'refs';
    *{"$pkg\::pseudo_columns"} = sub {
        my($class, $parent_column, @colnames) = @_;
        for my $p_column (@colnames) {
            *{"$class\::$p_column"} = sub {
                my $self = shift;
                my $dumped = $self->$parent_column();
                my $property = defined $dumped ? eval qq{ $dumped } : {};
                if (ref($property) ne 'HASH') {
                    $property = {};
                }
                if (@_) {
                    $property->{$p_column} = shift;
                    $self->$parent_column($self->_dumped_string($property));
                }
                return $property->{$p_column};
            };
        }
    };
    *{"$pkg\::_dumped_string"} = \&_dumped_string;
}

sub _dumped_string {
    my($self, $var) = @_;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;
    return Data::Dumper::Dumper($var);
}

1;

__END__

=head1 NAME

Class::DBI::Plugin::PseudoColumns - an interface to use some pseudo columns

=head1 SYNOPSIS

 package Music::CD;
 use base 'Music::DBI';
 
 Music::CD->table('cd');
 Music::CD->columns(All => qw/cdid artist title year reldate properties/);
 use Class::DBI::Plugin::PseudoColumns;
 Music::CD->pseudo_columns(properties => qw/asin tag/);
 
 use Music::CD;
 my $cds = Music::CD->search(artist => 'Steve Vai');
 while (my $cd = $cds->next) {
     if ($cd->title =~ /^Real\s+Illusions/i) {
         $cd->asin('B0007GADZO');
     }
     $cd->tag(['rock', 'guitar', 'tricky play']);
     $cd->update;
 }

=head1 DESCRIPTION

This module provides an easy way to use B<pseudo> column in your C<Class::DBI> based table classes.
The ``pseudo column'' means a kind of column that is including an optical hashref string (via C<Data::Dumper>).
You can get and set with using the pseudo column accessors (same as always).
But, you can't use the columns' name into your SQL, SQL interfaced methods, C<ORDER BY> clause and C<GROUP BY> clause, etc.
This module is useful when you'd like to add an unimportant column without issuing C<ALTER TABLE>, and when you'd like to have related multiple data without normalizing table.

=head1 HOW TO USE

=head2 Create a column

You should create a huge size column into your table. like this:

 CREATE TABLE cd (
   cdid int UNSIGNED auto_increment,
   artist varchar(255),
   title varchar(255),
   year int,
   reldate date,
   properties text, # create for using pseudo column
   PRIMARY KEY (cdid)
 );

=head2 Create a table class

Almost same as usual.

 package Music::CD;
 use base 'Music::DBI';
 
 Music::CD->table('cd');
 Music::CD->columns(All => qw/cdid artist title year reldate properties/);

=head2 Use it

You will be able to use pseudo column with only to C<use> this module.

 use Class::DBI::Plugin::PseudoColumns;

=head2 Set your pseudo columns as your like

 Music::CD->pseudo_columns(properties => qw/asin tag/);

=head1 METHOD

=over 4

=item * pseudo_columns(parent_colname => ('pseudo_column1'[, 'pseudo_column2' ...]));

You can set a pseudo columns' name with parent column's name. ``pseudo_column1'' ... will provide to you each pseudo column's accessor.

=back

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Koichi Taniguchi. Japan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Data::Dumper>

=cut
