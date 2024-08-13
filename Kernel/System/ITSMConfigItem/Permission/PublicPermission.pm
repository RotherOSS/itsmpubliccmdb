# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::System::ITSMConfigItem::Permission::PublicPermission;

use strict;
use warnings;

use List::Util qw(any none);

our @ObjectDependencies = (
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::Config',
);

use parent qw(
    Kernel::System::ITSMConfigItem
);

=head2 new()

create an object

    use Kernel::System::ObjectManager;

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $CheckObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Permission::ItemClassGroupCheck');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};

    $Self->{CacheType} = 'ITSMConfigurationManagement';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    # allocate new hash for object
    bless( $Self, $Type );

    return $Self;

}

=head1 NAME

Kernel::System::ITSMConfigItem::Permission::PublicPermission - check if the public module can access an item

=head1 DESCRIPTION

All config item functions.

=head1 PUBLIC INTERFACE

=head2 PublicPermission()

returns whether the user public module has permissions or not

    my $Access = $ConfigItemObject->PublicPermission(
        ConfigItemID => 123,
        LogNo        => 1,    # optional, do not log, default: 0
    );

=cut

sub PublicPermission {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ConfigItemID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %Conditions = %{ $Kernel::OM->Get('Kernel::Config')->Get('Public::ConfigItem::PermissionConditions') // {} };
    my $ConfigItem = $Self->ConfigItemGet(
        ConfigItemID  => $Param{ConfigItemID},
        DynamicFields => any { $_->{CustomerUserDynamicField} || $_->{CustomerCompanyDynamicField} } values %Conditions,
    );

    CONDITION:
    for my $ConditionSet ( values %Conditions ) {
        if ( $ConditionSet->{Classes} ) {
            my @Classes = ref $ConditionSet->{Classes} ? $ConditionSet->{Classes}->@* : ( $ConditionSet->{Classes} );

            next CONDITION if @Classes && !grep { $_ eq $ConfigItem->{Class} } @Classes;
        }

        if ( $ConditionSet->{DeploymentStates} ) {
            my @DeplStates = ref $ConditionSet->{DeploymentStates} ? $ConditionSet->{DeploymentStates}->@* : ( $ConditionSet->{DeploymentStates} );

            next CONDITION if @DeplStates && !grep { $_ eq $ConfigItem->{DeplState} } @DeplStates;
        }

        if ( $ConditionSet->{DynamicFieldValues} ) {
            for my $FieldName ( keys $ConditionSet->{DynamicFieldValues}->%* ) {
                my $FieldValue = $ConditionSet->{DynamicFieldValues}{$FieldName};
                next CONDITION if $FieldValue && !$ConfigItem->{"DynamicField_$FieldName"} eq $FieldValue;
            }
        }

        # grant access
        return 1;
    }

    if ( !$Param{LogNo} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied (Public access "
                . "on ConfigItem: " . $Param{ConfigItemID} . ")!",
        );
    }

    # don't grant access
    return;
}

1;
