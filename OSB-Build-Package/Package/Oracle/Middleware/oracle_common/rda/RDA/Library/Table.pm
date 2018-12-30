# Table.pm: Class Used for Table Management Macros

package RDA::Library::Table;

# $Id: Table.pm,v 2.4 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Table.pm,v 2.4 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Table - Class Used for Table Management Macros

=head1 SYNOPSIS

require RDA::Library::Table;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Table> class are used to interface with
macros for managing tables.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Table;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $RPT = qr/^RDA::Object::(Pipe|Report)$/i;

my %tb_alt = (
  'list'          => \&_list,
  );
my %tb_fct = (
  'addTableColumn'  => [\&_m_add_column,  'N'],
  'addTableRow'     => [\&_m_add_row,     'N'],
  'addTableUid'     => [\&_m_add_uid,     'N'],
  'createTable'     => [\&_m_create,      'N'],
  'deleteTable'     => [\&_m_delete,      'N'],
  'dumpTable'       => [\&_m_dump,        'N'],
  'getTableColumns' => [\&_m_get_columns, 'L'],
  'getTableKeys'    => [\&_m_get_keys,    'L'],
  'getTableOffset'  => [\&_m_get_offset,  'N'],
  'mergeTable'      => [\&_m_merge,       'N'],
  'setTableType'    => [\&_m_set_type,    'N'],
  'writeTable'      => [\&_m_write,       'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Table-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Table> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_tbl'> > Table hash

=back

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _tbl => {},
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(stat));

  # Return the object reference
  $slf;
}

# Clear the table hash for each module
sub clr_stats
{ shift->_reset_data;
}

sub get_stats
{ shift->_reset_data;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}->[0]}($slf, @arg);
}

=head2 S<$h-E<gt>run($tble,$arg,$ctx)>

This method executes the macro with the specified argument list in a given
context.

=cut

sub run
{ my ($slf, $tbl, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  $fct = $tb_fct{$tbl};
  $typ = $fct->[1];

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 TABLE MACROS

=head2 S<addTableColumn($tbl,$nam,$pos,$fmt[,off,...])>

This macro adds a derived column in the table. You can indicate the position
where it must insert the column. It appends after the last column when the
position is an undefined value. The column value is specified by a C<sprintf>
format. The extra arguments indicates the positions of the contributing
columns. On successful completion, it returns a true value. Otherwise, it
returns a false value.

=cut

sub _m_add_column
{ my ($slf, $ctx, $tbl, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Add the column
  $slf->{'_tbl'}->{$tbl}->add_column(@arg);
}

=head2 S<addTableRow($tbl,$lin)>

This macro adds a row in the table. To reformat time values, you must declare
the time stamp columns before loading rows. On successful completion, it
returns a true value. Otherwise, it returns a false value.

=cut

sub _m_add_row
{ my ($slf, $ctx, $tbl, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Add the row
  $slf->{'_tbl'}->{$tbl}->add_row(@arg);
}

=head2 S<addTableUid($tbl,$off)>

This macro defines an unique identifier in the table. On successful completion,
it returns a true value. Otherwise, it returns a false value.

=cut

sub _m_add_uid
{ my ($slf, $ctx, $tbl, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Define the unique identifier
  $slf->{'_tbl'}->{$tbl}->add_uid(@arg);
}

=head2 S<createTable($tbl,$def)>

This macro defines a new table. The columns definition is specified as a string
where the column names are separated by commas or by spaces.

=head2 S<createTable($tbl[,$col1,...])>

This macro defines a new table, with the column names specified as arguments.

On successful completion, it returns a true value. Otherwise, it returns a
false value.

=cut

sub _m_create
{ my ($slf, $ctx, $tbl, @arg) = @_;

  if ($tbl)
  { # Delete any previous table associated to this name
    delete($slf->{'_tbl'}->{$tbl})->delete if exists($slf->{'_tbl'}->{$tbl});

    # Create the new table
    $slf->{'_tbl'}->{$tbl} = RDA::Object::Table->new($tbl,
      ((scalar @arg) == 1) ? $arg[0] : [@arg]);

    # Indicate the successful completion
    return 1;
  }
  0;
}

=head2 S<deleteTable($tbl)>

This macro deletes a table. On successful completion, it returns a true
value. Otherwise, it returns a false value.

=cut

sub _m_delete
{ my ($slf, $ctx, $tbl) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Delete the table
  $slf->{'_tbl'}->{$tbl}->delete;
  1;
}

=head2 S<dumpTable($tbl)>

This macro returns the table definition.

=cut

sub _m_dump
{ my ($slf, $ctx, $tbl) = @_;

  # Abort when the table is not defined
  return undef unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Return the table definition
  $slf->{'_tbl'}->{$tbl}->dump;
}

=head2 S<getTableColumns($tbl)>

This macro returns the list of column names.

=cut

sub _m_get_columns
{ my ($slf, $ctx, $tbl) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Get the column names
  $slf->{'_tbl'}->{$tbl}->get_columns;
}

=head2 S<getTableKeys($tbl,$off)>

This macro returns the list of distinct values present in a column.

=cut

sub _m_get_keys
{ my ($slf, $ctx, $tbl, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Get the column keys
  $slf->{'_tbl'}->{$tbl}->get_keys(@arg);
}

=head2 S<getTableOffset($tbl,$nam)>

This macro returns the offset of the specified column name. It returns an
undefined value if it does not find the column.

=cut

sub _m_get_offset
{ my ($slf, $ctx, $tbl, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Get the column offset
  $slf->{'_tbl'}->{$tbl}->get_offset(@arg);
}

=head2 S<mergeTable($dst,$src,$off,$dst1,$src1,...)>

This macro merges source fields inside the destination table. It makes a join
between the specified destination column and the source table unique identifier.

On successful completion, it returns a true value. Otherwise, it returns a
false value.

=cut

sub _m_merge
{ my ($slf, $ctx, $dst, $src, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $dst && exists($slf->{'_tbl'}->{$dst});
                  $src && exists($slf->{'_tbl'}->{$src});

  # Merge the table
  $slf->{'_tbl'}->{$dst}->merge($slf->{'_tbl'}->{$src}, @arg);
}

=head2 S<setTableType($tbl,$typ,$off,...)>

This macro modifies the type of the specified columns. It supports the
following types:

=over 10

=item B<    NUM  > Numeric value

=item B<    STR  > String

=item B<    TSP  > Time stamp

=back

It discards inexistent column names and returns the number of modified columns.

=cut

sub _m_set_type
{ my ($slf, $ctx, $tbl, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Modify the column type
  $slf->{'_tbl'}->{$tbl}->set_type(@arg);
}

=head2 S<writeTable([$rpt,]$tbl[,$sort,...])>

This macro writes the table content in the report. You can suffix sort
directives by C</A> or C</D> for sorting the corresponding values ascending
or descending. It derives the column headings from the column names.

It returns the number of rows effectively written in the report.

=cut

sub _m_write
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_write($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_write($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_write
{ my ($slf, $ctx, $rpt, $tbl, @arg) = @_;

  # Abort when the table is not defined
  return 0 unless $tbl && exists($slf->{'_tbl'}->{$tbl});

  # Add the rows
  $slf->{'_tbl'}->{$tbl}->write($rpt, ((scalar @arg) == 1) ? $arg[0] : [@arg]);
}

# Reset the table hash
sub _reset_data
{ my ($slf) = @_;

  foreach my $tbl (values(%{$slf->{'_tbl'}}))
  { $tbl->delete;
  }
  $slf->{'_tbl'} ={};
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Table|RDA::Object::Table>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
