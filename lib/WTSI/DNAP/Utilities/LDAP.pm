package WTSI::DNAP::Utilities::LDAP;

use strict;
use warnings;
use Net::LDAP;
use Exporter qw(import);
use Log::Log4perl;

my $log = Log::Log4perl->get_logger();

our @EXPORT_OK = qw(
                    setup_ldap
                    unbind_ldap
                    find_group_ids
                    find_primary_gid
                   );

our $VERSION = '';

my $host = 'ldap.internal.sanger.ac.uk';

sub setup_ldap {
  my $ldap = Net::LDAP->new($host);
  $ldap->bind or $log->logcroak("LDAP failed to bind to '$host': ", $!);
  return $ldap;
}

sub unbind_ldap {
  my ($ldap) = @_;
  $ldap->unbind or $log->logwarn("LDAP failed to unbind '$host': ", $!);
  return;
}

sub find_group_ids {
  my ($ld) = @_;

  my $query_base   = 'ou=group,dc=sanger,dc=ac,dc=uk';
  my $query_filter = '(cn=*)';
  my $search = $ld->search(base   => $query_base,
                           filter => $query_filter);
  if ($search->code) {
    $log->logcroak("LDAP query base: '$query_base', filter: '$query_filter' ",
                   'failed: ', $search->error);
  }

  my %group2users;
  my %gid2group;
  foreach my $entry ($search->entries) {
    my $group   = $entry->get_value('cn');
    my $gid     = $entry->get_value('gidNumber');
    my @uids    = $entry->get_value('memberUid');
    $group2users{$group} = \@uids;
    $gid2group{$gid}    = $group;
  }

  return (\%group2users, \%gid2group);
}

sub find_primary_gid {
  my ($ld) = @_;

  my $query_base   = 'ou=people,dc=sanger,dc=ac,dc=uk';
  my $query_filter = '(sangerActiveAccount=TRUE)';
  my $search = $ld->search(base   => $query_base,
                           filter => $query_filter);
  if ($search->code) {
    $log->logcroak("LDAP query base: '$query_base', filter: '$query_filter' ",
                   'failed: ', $search->error);
  }

  my %user2gid;
  foreach my $entry ($search->entries) {
    $user2gid{$entry->get_value('uid')} = $entry->get_value('gidNumber');
  }

  return \%user2gid;
}

1;

__END__

=head1 NAME

WTSI::DNAP::Utilities::LDAP

=head1 VERSION


=head1 SYNOPSIS
This module fetches group and user ids from sanger LDAP.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 setup_ldap
 my $ldap = setup_ldap;

Sets up a new Net::LDAP connection and returns the LDAP object.

=head2 unbind_ldap
 my $ldap = setup_ldap
 #Do something
 unbind_ldap($ldap);

Closes the Net::LDAP connection.

=head2 find_group_ids
 my $ldap = setup_ldap;
 my ($group2users, $gid2group) = find_group_ids($ldap);
 unbind_ldap($ldap);

=head2 find_primary_gid
 my $ldap = setup_ldap;
 my $user2gid = find_primary_gid($ldap);
 unbind_ldap($ldap);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Net::LDAP

=item Exporter

=item Log::Log4perl

=back

=head1 INCOMPATABILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut