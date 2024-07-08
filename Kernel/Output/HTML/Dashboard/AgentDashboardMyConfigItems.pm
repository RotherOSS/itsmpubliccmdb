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

package Kernel::Output::HTML::Dashboard::AgentDashboardMyConfigItems;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # get needed parameters
    for my $Needed (qw( Config Name UserID )) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    $Self->{PrefKey}  = 'UserDashboardPref' . $Self->{Name} . '-Shown';
    $Self->{CacheKey} = $Self->{Name} . '-' . $Self->{UserID};

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    return;
}

sub Config {
    my ( $Self, %Param ) = @_;

    return ( %{ $Self->{Config} } );
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $Config = $ConfigObject->Get("ITSMConfigItem::Frontend::AgentITSMConfigItem");

    my $SortBy = $ParamObject->GetParam( Param => 'SortBy' )
        || $Config->{'SortBy::Default'}
        || 'Age';

    if ( $SortBy eq 'LastChanged' ) {
        $SortBy = 'Changed';
    }

    # Determine the default ordering to be used.
    my $DefaultOrderBy = $Config->{'Order::Default'}
        || 'Up';

    # Set the sort order from the request parameters, or take the default.
    my $OrderBy = $ParamObject->GetParam( Param => 'OrderBy' )
        || $DefaultOrderBy;

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # get filter from web request
    my $Filter = $ParamObject->GetParam( Param => 'Filter' ) || 'All';

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # my config item object
    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    # get general catalog object
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # get filters stored in the user preferences
    my %Preferences = $UserObject->GetPreferences(
        UserID => $Self->{UserID},
    );
    my $StoredFiltersKey = 'UserStoredFilterColumns-' . $Self->{Action} . '-' . $Filter;
    my $JSONObject       = $Kernel::OM->Get('Kernel::System::JSON');
    my $StoredFilters    = $JSONObject->Decode(
        Data => $Preferences{$StoredFiltersKey},
    );

    # delete stored filters if needed
    if ( $ParamObject->GetParam( Param => 'DeleteFilters' ) ) {
        $StoredFilters = {};
    }

    # get the column filters from the web request or user preferences
    my %ColumnFilter;
    my %GetColumnFilter;

    COLUMNNAME:
    for my $ColumnName (
        qw(DeplState CurDeplState InciState CurInciState Class)
        )
    {
        # get column filter from web request
        my $FilterValue = $ParamObject->GetParam( Param => 'ColumnFilter' . $ColumnName )
            || '';

        # if filter is not present in the web request, try with the user preferences
        if ( $FilterValue eq '' ) {
            $FilterValue = $StoredFilters->{ $ColumnName . 'IDs' }->[0] || '';
        }
        next COLUMNNAME if $FilterValue eq '';
        next COLUMNNAME if $FilterValue eq 'DeleteFilter';

        push @{ $ColumnFilter{ $ColumnName . 'IDs' } }, $FilterValue;
        $GetColumnFilter{$ColumnName} = $FilterValue;
    }

    # get class list
    my $ClassList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );

    # get possible deployment state list for config items to be shown
    my $StateList = $GeneralCatalogObject->ItemList(
        Class       => 'ITSM::ConfigItem::DeploymentState',
        Preferences => {
            Functionality => [ 'preproductive', 'productive' ],
        },
    );

    # set the deployment state IDs parameter for the search
    my $DeplStateIDs;
    for my $DeplStateKey ( sort keys %{$StateList} ) {
        push @{$DeplStateIDs}, $DeplStateKey;
    }

    # viewable deployment states
    my @ViewableDeplStateIDs = keys %{
        $GeneralCatalogObject->ItemList(
            Class => 'ITSM::ConfigItem::DeploymentState',
            Valid => 1,
        )
    };

    # get permissions
    my $Permission = 'rw';

    # sort on default by using both (Priority, Age) else use only one sort argument
    my %Sort;

    # get if search result should be pre-sorted by priority
    my $PreSortByPriority = $Config->{'PreSort::ByPriority'};
    if ( !$PreSortByPriority ) {
        %Sort = (
            SortBy  => $SortBy,
            OrderBy => $OrderBy,
        );
    }
    else {
        %Sort = (
            SortBy  => [ 'Priority', $SortBy ],
            OrderBy => [ 'Down',     $OrderBy ],
        );
    }

    # to store the default class
    my $ClassIDAuto = '';

    # define position of the filter in the frontend
    my $PrioCounter = 1000;

    # to store the total number of config items in all classes that the user has access
    my $TotalCount;

    # to store all the clases that the user has access, used in search for filter 'All'
    my $AccessClassList;

    # to store the NavBar filters
    my %Filters;

    CLASSID:
    for my $ClassID ( sort { $ClassList->{$a} cmp $ClassList->{$b} } keys $ClassList->%* ) {

        # show menu link only if user has access rights
        my $HasAccess = $ConfigItemObject->Permission(
            Scope   => 'Class',
            ClassID => $ClassID,
            UserID  => $Self->{UserID},
            Type    => $Config->{Permission},
        );

        next CLASSID if !$HasAccess;

        # insert this class to be passed as search parameter for filter 'All'
        push @{$AccessClassList}, $ClassID;

        # count all records of this class
        my $ClassCount = $ConfigItemObject->ConfigItemCount(
            ClassID => $ClassID,
        );

        # add the config items number in this class to the total
        $TotalCount += $ClassCount;

        # increase the PrioCounter
        $PrioCounter++;

        # add filter with params for the search method
        $Filters{$ClassID} = {
            Name   => $ClassList->{$ClassID},
            Prio   => $PrioCounter,
            Count  => $ClassCount,
            Search => {
                ClassIDs     => [$ClassID],
                DeplStateIDs => $DeplStateIDs,
                %Sort,

                Limit      => $Self->{SearchLimit},
                Permission => $Permission,
                UserID     => $Self->{UserID},
            },
        };

        # remember the first class id to show this in the overview
        # if no class id was given
        $ClassIDAuto ||= $ClassID;
    }

    # if only one filter exists
    if ( scalar keys %Filters == 1 ) {

        # get the name of the only filter
        my ($FilterName) = keys %Filters;

        # activate this filter
        $Filter = $FilterName;
    }
    else {

        # add default filter, which shows all items
        $Filters{All} = {
            Name   => 'All',
            Prio   => 1000,
            Count  => $TotalCount,
            Search => {
                ClassIDs     => $AccessClassList,
                DeplStateIDs => $DeplStateIDs,
                %Sort,

                Limit      => $Self->{SearchLimit},
                Permission => $Permission,
                UserID     => $Self->{UserID},
            },
        };

        # if no filter was selected activate the filter for the default class
        $Filter ||= $ClassIDAuto;
    }

    # check if filter is valid
    if ( !$Filters{$Filter} ) {
        $LayoutObject->FatalError(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Invalid Filter: %s!', $Filter ),
        );
    }

    my $View = $ParamObject->GetParam( Param => 'View' ) || '';

    # lookup latest used view mode
    if ( !$View && $Self->{ 'UserConfigItemOverview' . $Self->{Action} } ) {
        $View = $Self->{ 'UserConfigItemOverview' . $Self->{Action} };
    }

    # otherwise use Preview as default as in LayoutConfigItem
    $View ||= 'Small';

    # Check if selected view is available.
    my $Backends = $ConfigObject->Get('ITSMConfigItem::Frontend::Overview');
    if ( !$Backends->{$View} ) {

        # Try to find fallback, take first configured view mode.
        KEY:
        for my $Key ( sort keys %{$Backends} ) {
            $View = $Key;
            last KEY;
        }
    }

    my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';
    my $HeaderColumn   = $ElementChanged;
    $HeaderColumn =~ s{\A ColumnFilter }{}msxg;

    # get data (viewable config items...)
    # search all config items
    my @ViewableConfigItems;
    my @OriginalViewableConfigItems;

    if (@ViewableDeplStateIDs) {

        # get config item values
        if (
            !IsStringWithData($HeaderColumn)
            || (
                IsStringWithData($HeaderColumn)
                && (
                    $ConfigObject->Get('OnlyValuesOnConfigItem')
                )
            )
            )
        {
            my $OwnerDynamicField = $Self->{Config}->{OwnerDynamicField};
            @OriginalViewableConfigItems = $ConfigItemObject->ConfigItemSearch(
                "DynamicField_$OwnerDynamicField" => { Equals => $Self->{UserID} },
                %{ $Filters{$Filter}->{Search} },
                Result => 'ARRAY',
            );

            my $Start = $ParamObject->GetParam( Param => 'StartHit' ) || 1;

            @ViewableConfigItems = $ConfigItemObject->ConfigItemSearch(
                %{ $Filters{$Filter}->{Search} },
                %ColumnFilter,
                "DynamicField_$OwnerDynamicField" => { Equals => $Self->{UserID} },
                Result                            => 'ARRAY',
            );
        }

    }

    $Self->{Filter}  = $Filter;
    $Self->{Filters} = \%Filters;

    my $CountTotal = 0;
    my %NavBarFilter;
    for my $FilterColumn ( sort keys %Filters ) {
        my $Count = 0;
        if (@ViewableDeplStateIDs) {
            my $OwnerDynamicField = $Self->{Config}->{OwnerDynamicField};
            $Count = $ConfigItemObject->ConfigItemSearch(
                %{ $Filters{$FilterColumn}->{Search} },
                %ColumnFilter,
                "DynamicField_$OwnerDynamicField" => { Equals => $Self->{UserID} },
                Result                            => 'COUNT',
            ) || 0;
        }

        if ( $FilterColumn eq $Filter ) {
            $CountTotal = $Count;
        }

        $NavBarFilter{ $Filters{$FilterColumn}->{Prio} } = {
            Count  => $Count,
            Filter => $FilterColumn,
            %{ $Filters{$FilterColumn} },
        };
    }

    my $ColumnFilterLink = '';
    COLUMNNAME:
    for my $ColumnName ( sort keys %GetColumnFilter ) {
        next COLUMNNAME if !$ColumnName;
        next COLUMNNAME if !defined $GetColumnFilter{$ColumnName};
        next COLUMNNAME if $GetColumnFilter{$ColumnName} eq '';
        $ColumnFilterLink
            .= ';' . $LayoutObject->Ascii2Html( Text => 'ColumnFilter' . $ColumnName )
            . '=' . $LayoutObject->LinkEncode( $GetColumnFilter{$ColumnName} );
    }

    my $LinkPage = 'Filter='
        . $LayoutObject->Ascii2Html( Text => $Filter )
        . ';View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
        . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderBy )
        . $ColumnFilterLink
        . ';';

    my $LinkSort = 'View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';Filter='
        . $LayoutObject->Ascii2Html( Text => $Filter )
        . $ColumnFilterLink
        . ';';

    my $LinkFilter = 'SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
        . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderBy )
        . ';View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';';

    my $LastColumnFilter = $ParamObject->GetParam( Param => 'LastColumnFilter' ) || '';

    if ( !$LastColumnFilter && $ColumnFilterLink ) {

        # is planned to have a link to go back here
        $LastColumnFilter = 1;
    }

    # show config items
    return $Self->_ITSMConfigItemDashboardShow(
        $LayoutObject,
        Filter                => $Filter,
        Filters               => \%NavBarFilter,
        ConfigItemIDs         => \@ViewableConfigItems,
        OriginalConfigItemIDs => \@OriginalViewableConfigItems,
        GetColumnFilter       => \%GetColumnFilter,
        LastColumnFilter      => $LastColumnFilter,
        Action                => 'AgentDashboard',
        Total                 => $CountTotal,
        RequestedURL          => $Self->{RequestedURL},
        View                  => $View,
        Bulk                  => 1,
        Env                   => $Self,
        LinkPage              => $LinkPage,
        LinkSort              => $LinkSort,
        LinkFilter            => $LinkFilter,
        OrderBy               => $OrderBy,
        SortBy                => $SortBy,
        EnableColumnFilters   => 1,
        ColumnFilterForm      => {
            Filter => $Filter || '',
        },

        # do not print the result earlier, but return complete content
        Output => 1,
    );

}

sub _ITSMConfigItemDashboardShow {
    my ( $Self, $LayoutObject, %Param ) = @_;

    # set frontend per default to agent
    $Param{Frontend} //= 'Agent';

    # take object ref to local, remove it from %Param (prevent memory leak)
    my $Env = delete $Param{Env};

    # lookup latest used view mode
    if ( !$Param{View} && $LayoutObject->{ 'UserITSMConfigItemOverview' . $Env->{Action} } ) {
        $Param{View} = $LayoutObject->{ 'UserITSMConfigItemOverview' . $Env->{Action} };
    }

    # set default view mode to 'small'
    my $View = $Param{View} || 'Small';

    # store latest view mode
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $LayoutObject->{SessionID},
        Key       => 'UserITSMConfigItemOverview' . $Env->{Action},
        Value     => $View,
    );

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # update preferences if needed
    my $Key = 'UserITSMConfigItemOverview' . $Env->{Action};
    if ( $Param{Frontend} ne 'Customer' ) {
        if ( !$ConfigObject->Get('DemoSystem') && ( $LayoutObject->{$Key} // '' ) ne $View ) {
            $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
                UserID => $LayoutObject->{UserID},
                Key    => $Key,
                Value  => $View,
            );
        }
    }

    # get backend from config
    my $Backends = $ConfigObject->Get('ITSMConfigItem::Frontend::Overview');

    if ( !$Backends ) {
        return $LayoutObject->FatalError(
            Message => 'Need config option ITSMConfigItem::Frontend::Overview',
        );
    }
    if ( ref $Backends ne 'HASH' ) {
        return $LayoutObject->FatalError(
            Message => 'Config option ITSMConfigItem::Frontend::Overview needs to be HASH ref!',
        );
    }

    # check if selected view is available
    if ( !$Backends->{$View} ) {

        # try to find fallback, take first configured view mode
        KEY:
        for my $Key ( sort keys %{$Backends} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No Config option found for view mode $View, took $Key instead!",
            );
            $View = $Key;
            last KEY;
        }
    }

    $LayoutObject->AddJSData(
        Key   => 'View',
        Value => $View,
    );

    # load overview backend module
    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Backends->{$View}->{Module} ) ) {
        return $Env->{LayoutObject}->FatalError();
    }

    my $Object = $Backends->{$View}->{Module}->new( %{$Env}, Action => "AgentITSMConfigItem" );

    return if !$Object;

    # retrieve filter values
    if ( $Param{FilterContentOnly} ) {
        return $Object->FilterContent(
            %Param,
        );
    }

    # run action row backend module
    $Param{ActionRow} = $Object->ActionRow(
        %Param,
        Config => $Backends->{$View},
    );

    # run overview backend module
    $Param{SortOrderBar} = $Object->SortOrderBar(
        %Param,
        Config => $Backends->{$View},
    );

    # check start option, if higher then tickets available, set
    # it to the last ticket page (Thanks to Stefan Schmidt!)
    my $StartHit = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'StartHit' ) || 1;

    # get personal page shown count
    my $PageShownPreferencesKey = 'UserConfigItemOverview' . $View . 'PageShown';
    my $PageShown               = $LayoutObject->{$PageShownPreferencesKey} || 10;
    my $Group                   = 'ConfigItemOverview' . $View . 'PageShown';

    # get data selection
    my %Data;
    my $Config = $ConfigObject->Get('PreferencesGroups');
    if ( $Config && $Config->{$Group} && $Config->{$Group}->{Data} ) {
        %Data = %{ $Config->{$Group}->{Data} };
    }

    # calculate max. shown per page
    if ( $StartHit > $Param{Total} ) {
        my $Pages = int( ( $Param{Total} / $PageShown ) + 0.99999 );
        $StartHit = ( ( $Pages - 1 ) * $PageShown ) + 1;
    }

    # build nav bar
    my $Limit   = $Param{Limit} || 20_000;
    my %PageNav = $LayoutObject->PageNavBar(
        Limit     => $Limit,
        StartHit  => $StartHit,
        PageShown => $PageShown,
        AllHits   => $Param{Total} || 0,
        Action    => 'Action=' . $LayoutObject->{Action},
        Link      => $Param{LinkPage},
        IDPrefix  => $LayoutObject->{Action},
    );

    # build shown ticket per page
    $Param{RequestedURL}    = $Param{RequestedURL} || "Action=$LayoutObject->{Action};$Param{LinkPage}";
    $Param{Group}           = $Group;
    $Param{PreferencesKey}  = $PageShownPreferencesKey;
    $Param{PageShownString} = $LayoutObject->BuildSelection(
        Name        => $PageShownPreferencesKey,
        SelectedID  => $PageShown,
        Data        => \%Data,
        Translation => 0,
        Sort        => 'NumericValue',
        Class       => 'Modernize',
    );

    # nav bar at the beginning of a overview
    $Param{View} = $View;
    $LayoutObject->Block(
        Name => 'OverviewNavBar',
        Data => \%Param,
    );

    # back link
    if ( $Param{LinkBack} ) {
        $LayoutObject->Block(
            Name => 'OverviewNavBarPageBack',
            Data => \%Param,
        );
        $LayoutObject->AddJSData(
            Key   => 'ITSMConfigItemSearch',
            Value => {
                Profile => $Param{Profile},
                ClassID => $Param{ClassID},
            },
        );
    }

    # filter selection
    if ( $Param{Filters} ) {
        my @NavBarFilters;
        for my $Prio ( sort keys %{ $Param{Filters} } ) {
            push @NavBarFilters, $Param{Filters}->{$Prio};
        }
        $LayoutObject->Block(
            Name => 'OverviewNavBarFilter',
            Data => {
                %Param,
            },
        );
        my $Count = 0;
        for my $Filter (@NavBarFilters) {
            $Count++;
            if ( $Count == scalar @NavBarFilters ) {
                $Filter->{CSS} = 'Last';
            }
            $LayoutObject->Block(
                Name => 'OverviewNavBarFilterItem',
                Data => {
                    %Param,
                    %{$Filter},
                },
            );
            if ( $Filter->{Filter} eq $Param{Filter} ) {
                $LayoutObject->Block(
                    Name => 'OverviewNavBarFilterItemSelected',
                    Data => {
                        %Param,
                        %{$Filter},
                    },
                );
            }
            else {
                $LayoutObject->Block(
                    Name => 'OverviewNavBarFilterItemSelectedNot',
                    Data => {
                        %Param,
                        %{$Filter},
                    },
                );
            }
        }
    }

    # view mode
    for my $Backend (
        sort { $Backends->{$a}->{ModulePriority} <=> $Backends->{$b}->{ModulePriority} }
        keys %{$Backends}
        )
    {
        $LayoutObject->Block(
            Name => 'OverviewNavBarViewMode',
            Data => {
                %Param,
                %{ $Backends->{$Backend} },
                Filter => $Param{Filter},
                View   => $Backend,
            },
        );
        if ( $View eq $Backend ) {
            $LayoutObject->Block(
                Name => 'OverviewNavBarViewModeSelected',
                Data => {
                    %Param,
                    %{ $Backends->{$Backend} },
                    Filter => $Param{Filter},
                    View   => $Backend,
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'OverviewNavBarViewModeNotSelected',
                Data => {
                    %Param,
                    %{ $Backends->{$Backend} },
                    Filter => $Param{Filter},
                    View   => $Backend,
                },
            );
        }
    }

    if (%PageNav) {
        $LayoutObject->Block(
            Name => 'OverviewNavBarPageNavBar',
            Data => \%PageNav,
        );

        # don't show context settings in AJAX case (e. g. in customer ticket history),
        #   because the submit with page reload will not work there
        if ( !$Param{AJAX} ) {
            $LayoutObject->Block(
                Name => 'ContextSettings',
                Data => {
                    %PageNav,
                    %Param,
                },
            );

            # show column filter preferences
            if ( $View eq 'Small' ) {

                # set preferences keys
                my $PrefKeyColumns = 'UserFilterColumnsEnabled' . '-' . $Env->{Action} . '-' . $Param{Filter};

                # create extra needed objects
                my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

                # configure columns
                my @ColumnsEnabled = @{ $Object->{ColumnsEnabled} };
                my @ColumnsAvailable;

                # remove duplicate columns
                my %UniqueColumns;
                my @ColumnsEnabledAux;

                for my $Column (@ColumnsEnabled) {
                    if ( !$UniqueColumns{$Column} ) {
                        push @ColumnsEnabledAux, $Column;
                    }
                    $UniqueColumns{$Column} = 1;
                }

                # set filtered column list
                @ColumnsEnabled = @ColumnsEnabledAux;

                for my $ColumnName ( sort { $a cmp $b } @{ $Object->{ColumnsAvailable} } ) {
                    if ( !grep { $_ eq $ColumnName } @ColumnsEnabled ) {
                        push @ColumnsAvailable, $ColumnName;
                    }
                }

                my %Columns;
                for my $ColumnName ( sort @ColumnsAvailable ) {
                    $Columns{Columns}->{$ColumnName} = ( grep { $ColumnName eq $_ } @ColumnsEnabled ) ? 1 : 0;
                }

                $LayoutObject->Block(
                    Name => 'FilterColumnSettings',
                    Data => {
                        Columns          => $JSONObject->Encode( Data => \%Columns ),
                        ColumnsEnabled   => $JSONObject->Encode( Data => \@ColumnsEnabled ),
                        ColumnsAvailable => $JSONObject->Encode( Data => \@ColumnsAvailable ),
                        NamePref         => $PrefKeyColumns,
                        Desc             => Translatable('Shown Columns'),
                        Name             => $Env->{Action},
                        FilterAction     => $Env->{Action} . '-' . $Param{Filter},
                        View             => $View,
                        GroupName        => 'ConfigItemOverviewFilterSettings',
                        %Param,
                    },
                );
            }
        }    # end show column filters preferences

        # check if there was stored filters, and print a link to delete them
        if ( IsHashRefWithData( $Object->{StoredFilters} ) ) {
            $LayoutObject->Block(
                Name => 'DocumentActionRowRemoveColumnFilters',
                Data => {
                    CSS => "ContextSettings RemoveFilters",
                    %Param,
                },
            );
        }
    }

    return $Self->_BuildObject(
        $Object,
        %Param,
        Config    => $Backends->{$View},
        Limit     => $Limit,
        StartHit  => $StartHit,
        PageShown => $PageShown,
        AllHits   => $Param{Total}  || 0,
        Output    => $Param{Output} || '',
    );

}

sub _BuildObject {
    my ( $Self, $Object, %Param ) = @_;

    # set frontend per default to agent
    $Param{Frontend} //= 'Agent';

    #push @{$Object->{ColumnsAvailable}}, "Name";

    # determine template dependent on interface
    my $TemplateFile = 'AgentDashboardMyConfigItems';

    # If $Param{EnableColumnFilters} is not sent, we want to disable all filters
    #   for the current screen. We localize the setting for this sub and change it
    #   after that, if needed. The original value will be restored after this function.
    local $Object->{AvailableFiltrableColumns} = $Object->{AvailableFiltrableColumns};
    if ( !$Param{EnableColumnFilters} ) {
        $Object->{AvailableFiltrableColumns} = {};    # disable all column filters
    }

    for my $Item (qw(ConfigItemIDs PageShown StartHit)) {
        if ( !$Param{$Item} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Item!",
            );
            return;
        }
    }

    # define incident signals
    my %InciSignals = (
        Translatable('operational') => 'greenled',
        Translatable('warning')     => 'yellowled',
        Translatable('incident')    => 'redled',
    );

    # store deployment signals
    my %DeplSignals;

    # get general catalog object
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # get list of deployment states
    my $DeploymentStatesList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::DeploymentState',
    );

    # set deployment style colors
    my $StyleClasses = '';

    ITEMID:
    for my $ItemID ( sort keys %{$DeploymentStatesList} ) {

        # get deployment state preferences
        my %GeneralCatalogPreferences = $GeneralCatalogObject->GeneralCatalogPreferencesGet(
            ItemID => $ItemID,
        );

        # check if a color is defined in preferences
        next ITEMID if !$GeneralCatalogPreferences{Color};

        # get deployment state
        my $DeplState = $DeploymentStatesList->{$ItemID};

        # remove any non ascii word characters
        $DeplState =~ s{ [^a-zA-Z0-9] }{_}msxg;

        # store the original deployment state as key
        # and the ss safe converted deployment state as value
        $DeplSignals{ $DeploymentStatesList->{$ItemID} } = $DeplState;

        # convert to lower case
        my $DeplStateColor = ( lc $GeneralCatalogPreferences{Color} ) =~ s/[^0-9a-f]//msgr;

        # add to style classes string
        $StyleClasses .= "
            .Flag span.$DeplState {
                background-color: #$DeplStateColor;
            }
        ";
    }

    # wrap into style tags
    if ($StyleClasses) {
        $StyleClasses = "<style>$StyleClasses</style>";
    }

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if bulk feature is enabled
    my $BulkFeature = 0;
    if ( $Param{Bulk} && $ConfigObject->Get('ITSMConfigItem::Frontend::BulkFeature') ) {
        my @Groups;
        if ( $ConfigObject->Get('ITSMConfigItem::Frontend::BulkFeatureGroup') ) {
            @Groups = @{ $ConfigObject->Get('ITSMConfigItem::Frontend::BulkFeatureGroup') };
        }
        if ( !@Groups ) {
            $BulkFeature = 1;
        }
        else {
            my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
            GROUP:
            for my $Group (@Groups) {
                my $HasPermission = $GroupObject->PermissionCheck(
                    UserID    => $Object->{UserID},
                    GroupName => $Group,
                    Type      => 'rw',
                );
                if ($HasPermission) {
                    $BulkFeature = 1;
                    last GROUP;
                }
            }
        }
    }

    my $Counter = 0;
    my @ConfigItemBox;

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    for my $ConfigItemID ( @{ $Param{ConfigItemIDs} } ) {
        $Counter++;
        if ( $Counter >= $Param{StartHit} && $Counter < ( $Self->{Config}->{Limit} + $Param{StartHit} ) ) {

            # Get config item data.
            my $ConfigItemRef = $ConfigItemObject->ConfigItemGet(
                ConfigItemID  => $ConfigItemID,
                DynamicFields => 0,
            );
            my %ConfigItem = $ConfigItemRef->%*;

            # set deployment and incident signals
            $ConfigItem{CurDeplSignal} = $DeplSignals{ $ConfigItem{CurDeplState} };
            $ConfigItem{CurInciSignal} = $InciSignals{ $ConfigItem{CurInciStateType} };

            # fill column name attribute with corresponding item attribute
            $ConfigItem{Created}     = $ConfigItem{CreateTime};
            $ConfigItem{LastChanged} = $ConfigItem{ChangeTime};

            # get ACL restrictions
            my %PossibleActions;
            my $Counter = 0;

            # get all registered Actions
            if ( ref $ConfigObject->Get('ITSMConfigItem::Frontend::Module') eq 'HASH' ) {

                my %Actions = %{ $ConfigObject->Get('ITSMConfigItem::Frontend::Module') };

                # only use those Actions that stats with AgentITSMConfigItem
                %PossibleActions = map { ++$Counter => $_ }
                    grep { substr( $_, 0, length 'AgentITSMConfigItem' ) eq 'AgentITSMConfigItem' }
                    sort keys %Actions;
            }

            my $ACL;
            my %AclAction = %PossibleActions;
            if ( $Param{Frontend} ne 'Customer' ) {
                $ACL = $ConfigItemObject->ConfigItemAcl(
                    Data          => \%PossibleActions,
                    Action        => $Object->{Action},
                    ConfigItemID  => $ConfigItem{ConfigItemID},
                    ReturnType    => 'Action',
                    ReturnSubType => '-',
                    UserID        => $Object->{UserID},
                );
                if ($ACL) {
                    %AclAction = $ConfigItemObject->ConfigItemAclActionData();
                }
            }

            # run config item pre menu modules
            my @ActionItems;
            if ( ref $ConfigObject->Get('ITSMConfigItem::Frontend::PreMenuModule') eq 'HASH' ) {
                my %Menus = %{ $ConfigObject->Get('ITSMConfigItem::Frontend::PreMenuModule') };
                MENU:
                for my $Menu ( sort keys %Menus ) {

                    # load module
                    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Menus{$Menu}->{Module} ) ) {
                        return $LayoutObject->FatalError();
                    }
                    my $Object = $Menus{$Menu}->{Module}->new(
                        %{$Object},
                        ConfigItemID => $ConfigItem{ConfigItemID},
                    );

                    # run module
                    my $Item = $Object->Run(
                        %Param,
                        ConfigItem => \%ConfigItem,
                        ACL        => \%AclAction,
                        Config     => $Menus{$Menu},
                    );
                    next MENU if !$Item;
                    next MENU if ref $Item ne 'HASH';

                    # add session id if needed
                    if ( !$LayoutObject->{SessionIDCookie} && $Item->{Link} ) {
                        $Item->{Link}
                            .= ';'
                            . $LayoutObject->{SessionName} . '='
                            . $LayoutObject->{SessionID};
                    }

                    # create id
                    $Item->{ID} = $Item->{Name};
                    $Item->{ID} =~ s/(\s|&|;)//ig;

                    my $Output;
                    if ( $Item->{Block} ) {
                        $LayoutObject->Block(
                            Name => $Item->{Block},
                            Data => $Item,
                        );
                        $Output = $LayoutObject->Output(
                            TemplateFile => $TemplateFile,
                            Data         => $Item,
                        );
                    }
                    else {
                        $Output = '<li id="'
                            . $Item->{ID}
                            . '"><a href="#" title="'
                            . $LayoutObject->{LanguageObject}->Translate( $Item->{Description} )
                            . '">'
                            . $LayoutObject->{LanguageObject}->Translate( $Item->{Name} )
                            . '</a></li>';
                    }

                    $Output =~ s/\n+//g;
                    $Output =~ s/\s+/ /g;
                    $Output =~ s/<\!--.+?-->//g;

                    push @ActionItems, {
                        HTML        => $Output,
                        ID          => $Item->{ID},
                        Link        => $LayoutObject->{Baselink} . $Item->{Link},
                        Target      => $Item->{Target},
                        PopupType   => $Item->{PopupType},
                        Description => $Item->{Description},
                    };
                    $ConfigItem{ActionItems} = \@ActionItems;
                }
            }
            push @ConfigItemBox, \%ConfigItem;
        }
    }

    # check if columnsenabled is a filled array referencd
    if ( IsArrayRefWithData( $Object->{ColumnsEnabled} ) ) {

        # check if column is really filterable
        COLUMNNAME:
        for my $ColumnName ( @{ $Object->{ColumnsEnabled} } ) {
            next COLUMNNAME if !$Object->{AvailableFiltrableColumns}->{$ColumnName};
            $Object->{ValidFiltrableColumns}->{$ColumnName} = 1;
        }
    }

    my $ColumnValues = $Object->_GetColumnValues(
        OriginalConfigItemIDs => $Param{OriginalConfigItemIDs},
    );

    # send data to JS
    $LayoutObject->AddJSData(
        Key   => 'LinkPage',
        Value => $Param{LinkPage},
    );

    $LayoutObject->Block(
        Name => 'DocumentContent',
        Data => \%Param,
    );

    # array to save the column names to do the query
    my @Col = @{ $Object->{ColumnsEnabled} };

    # define special config item columns
    my %SpecialColumns = (
        Number        => 1,
        CurDeplSignal => 1,
        CurInciSignal => 1,
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    $Param{OrderBy} = $Param{OrderBy} || 'Up';
    $Param{SortBy}  = $Param{SortBy}  || 'Number';

    my $ConfigItemData = scalar @ConfigItemBox;
    if ($ConfigItemData) {

        $LayoutObject->Block(
            Name => 'OverviewTable',
            Data => {
                StyleClasses => $StyleClasses,
            },
        );
        $LayoutObject->Block( Name => 'TableHeader' );

        if ($BulkFeature) {
            $LayoutObject->Block(
                Name => 'GeneralOverviewHeader',
            );
        }

        my $CSS = '';

        # show special config item columns, if needed
        my $Counter = 0;
        COLUMN:
        for my $Column (@Col) {
            my $StaticColumn = !$Counter;
            $Counter++;

            $LayoutObject->Block(
                Name => 'GeneralOverviewHeader',
            );

            $CSS = $Column . ( $StaticColumn ? ' StaticColumn' : '' );
            my $Title   = $LayoutObject->{LanguageObject}->Translate($Column);
            my $OrderBy = $Param{OrderBy};

            # Transform filter name to column name
            if ( $Param{SortBy} eq 'Changed' ) {
                $Param{SortBy} = 'LastChanged';
            }

            # output overall block so Number as well as other columns can be ordered
            $LayoutObject->Block(
                Name => 'OverviewNavBarPageConfigItemHeader',
                Data => {},
            );

            if ( $SpecialColumns{$Column} ) {

                if ( $Param{SortBy} && ( $Param{SortBy} eq $Column ) ) {
                    my $TitleDesc;

                    # Change order for sorting column.
                    $OrderBy = $OrderBy eq 'Up' ? 'Down' : 'Up';

                    if ( $OrderBy eq 'Down' ) {
                        $CSS .= ' SortAscendingLarge';
                        $TitleDesc = Translatable('sorted ascending');
                    }
                    else {
                        $CSS .= ' SortDescendingLarge';
                        $TitleDesc = Translatable('sorted descending');
                    }

                    $TitleDesc = $LayoutObject->{LanguageObject}->Translate($TitleDesc);
                    $Title .= ', ' . $TitleDesc;
                }

                # translate the column name to write it in the current language
                my $TranslatedWord;
                if ( $Column eq 'CurDeplSignal' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Current Deployment State');
                }
                elsif ( $Column eq 'CurInciSignal' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Current Incident State');
                }
                else {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate($Column);
                }

                my $FilterTitle     = $TranslatedWord;
                my $FilterTitleDesc = Translatable('filter not active');
                if (
                    $Object->{StoredFilters} &&
                    (
                        $Object->{StoredFilters}->{$Column} ||
                        $Object->{StoredFilters}->{ $Column . 'IDs' }
                    )
                    )
                {
                    $CSS .= ' FilterActive';
                    $FilterTitleDesc = Translatable('filter active');
                }
                $FilterTitleDesc = $LayoutObject->{LanguageObject}->Translate($FilterTitleDesc);
                $FilterTitle .= ', ' . $FilterTitleDesc;

                $LayoutObject->Block(
                    Name => "OverviewNavBarPage$Column",
                    Data => {
                        %Param,
                        OrderBy              => $OrderBy,
                        ColumnName           => $Column         || '',
                        CSS                  => $CSS            || '',
                        ColumnNameTranslated => $TranslatedWord || $Column,
                        Title                => $Title,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageColumnEmpty',
                    Data => {
                        %Param,
                        ColumnName           => $Column,
                        CSS                  => $CSS,
                        ColumnNameTranslated => $TranslatedWord || $Column,
                        Title                => $Title,
                    },
                );
                next COLUMN;
            }
            elsif ( $Column !~ m{\A DynamicField_}xms ) {

                if ( $Param{SortBy} && ( $Param{SortBy} eq $Column ) ) {
                    my $TitleDesc;

                    # Change order for sorting column.
                    $OrderBy = $OrderBy eq 'Up' ? 'Down' : 'Up';

                    if ( $OrderBy eq 'Down' ) {
                        $CSS .= ' SortAscendingLarge';
                        $TitleDesc = Translatable('sorted ascending');
                    }
                    else {
                        $CSS .= ' SortDescendingLarge';
                        $TitleDesc = Translatable('sorted descending');
                    }

                    $TitleDesc = $LayoutObject->{LanguageObject}->Translate($TitleDesc);
                    $Title .= ', ' . $TitleDesc;
                }

                # translate the column name to write it in the current language
                my $TranslatedWord;
                if ( $Column eq 'DeplState' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Deployment State');
                }
                elsif ( $Column eq 'CurDeplState' || $Column eq 'CurDeplSignal' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Current Deployment State');
                }
                elsif ( $Column eq 'CurDeplStateType' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Deployment State Type');
                }
                elsif ( $Column eq 'InciState' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Incident State');
                }
                elsif ( $Column eq 'CurInciState' || $Column eq 'CurInciSignal' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Current Incident State');
                }
                elsif ( $Column eq 'CurInciStateType' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Current Incident State Type');
                }
                elsif ( $Column eq 'LastChanged' ) {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate('Last changed');
                }
                else {
                    $TranslatedWord = $LayoutObject->{LanguageObject}->Translate($Column);
                }

                my $FilterTitle     = $TranslatedWord;
                my $FilterTitleDesc = Translatable('filter not active');
                if ( $Object->{StoredFilters} && $Object->{StoredFilters}->{ $Column . 'IDs' } ) {
                    $CSS .= ' FilterActive';
                    $FilterTitleDesc = Translatable('filter active');
                }
                $FilterTitleDesc = $LayoutObject->{LanguageObject}->Translate($FilterTitleDesc);
                $FilterTitle .= ', ' . $FilterTitleDesc;

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageColumn',
                    Data => {
                        %Param,
                        ColumnName           => $Column,
                        CSS                  => $CSS,
                        ColumnNameTranslated => $TranslatedWord || $Column,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageColumnEmpty',
                    Data => {
                        %Param,
                        ColumnName           => $Column,
                        CSS                  => $CSS,
                        ColumnNameTranslated => $TranslatedWord || $Column,
                        Title                => $Title,
                    },
                );

            }

            # show the DFs
            else {

                my $DynamicFieldConfig;
                my $DFColumn = $Column;
                $DFColumn =~ s/DynamicField_//g;
                DYNAMICFIELD:
                for my $DFConfig ( @{ $Object->{DynamicField} } ) {
                    next DYNAMICFIELD if !IsHashRefWithData($DFConfig);
                    next DYNAMICFIELD if $DFConfig->{Name} ne $DFColumn;

                    $DynamicFieldConfig = $DFConfig;
                    last DYNAMICFIELD;
                }
                next COLUMN if !IsHashRefWithData($DynamicFieldConfig);

                my $Label = $DynamicFieldConfig->{Label};
                $Title = $Label;
                my $FilterTitle = $Label;

                # get field sortable condition
                my $IsSortable = $DynamicFieldBackendObject->HasBehavior(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    Behavior           => 'IsSortable',
                );

                if ($IsSortable) {
                    my $CSS = 'DynamicField_' . $DynamicFieldConfig->{Name};
                    if (
                        $Param{SortBy}
                        && ( $Param{SortBy} eq ( 'DynamicField_' . $DynamicFieldConfig->{Name} ) )
                        )
                    {
                        my $TitleDesc;

                        # Change order for sorting column.
                        $OrderBy = $OrderBy eq 'Up' ? 'Down' : 'Up';

                        if ( $OrderBy eq 'Down' ) {
                            $CSS .= ' SortAscendingLarge';
                            $TitleDesc = Translatable('sorted ascending');
                        }
                        else {
                            $CSS .= ' SortDescendingLarge';
                            $TitleDesc = Translatable('sorted descending');
                        }

                        $TitleDesc = $LayoutObject->{LanguageObject}->Translate($TitleDesc);
                        $Title .= ', ' . $TitleDesc;
                    }

                    my $FilterTitleDesc = Translatable('filter not active');
                    if ( $Object->{StoredFilters} && $Object->{StoredFilters}->{$Column} ) {
                        $CSS .= ' FilterActive';
                        $FilterTitleDesc = Translatable('filter active');
                    }
                    $FilterTitleDesc = $LayoutObject->{LanguageObject}->Translate($FilterTitleDesc);
                    $FilterTitle .= ', ' . $FilterTitleDesc;

                    $LayoutObject->Block(
                        Name => 'OverviewNavBarPageDynamicField',
                        Data => {
                            %Param,
                            CSS => $CSS,
                        },
                    );

                    my $DynamicFieldName = 'DynamicField_' . $DynamicFieldConfig->{Name};

                    if ( $Object->{ValidFiltrableColumns}->{$DynamicFieldName} ) {

                        # variable to save the filter's HTML code
                        my $ColumnFilterHTML = $Object->_InitialColumnFilter(
                            ColumnName    => $DynamicFieldName,
                            Label         => $Label,
                            ColumnValues  => $ColumnValues->{$DynamicFieldName},
                            SelectedValue => $Param{GetColumnFilter}->{$DynamicFieldName} || '',
                        );

                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicFieldFiltrableSortable',
                            Data => {
                                %Param,
                                OrderBy          => $OrderBy,
                                Label            => $Label,
                                DynamicFieldName => $DynamicFieldConfig->{Name},
                                ColumnFilterStrg => $ColumnFilterHTML,
                                Title            => $Title,
                                FilterTitle      => $FilterTitle,
                            },
                        );
                    }

                    else {
                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicFieldSortable',
                            Data => {
                                %Param,
                                OrderBy          => $OrderBy,
                                Label            => $Label,
                                DynamicFieldName => $DynamicFieldConfig->{Name},
                                Title            => $Title,
                            },
                        );
                    }

                    # example of dynamic fields order customization
                    $LayoutObject->Block(
                        Name => 'OverviewNavBarPageDynamicField_' . $DynamicFieldConfig->{Name},
                        Data => {
                            %Param,
                            CSS => $CSS,
                        },
                    );

                    if ( $Object->{ValidFiltrableColumns}->{$DynamicFieldName} ) {

                        # variable to save the filter's HTML code
                        my $ColumnFilterHTML = $Object->_InitialColumnFilter(
                            ColumnName    => $DynamicFieldName,
                            Label         => $Label,
                            ColumnValues  => $ColumnValues->{$DynamicFieldName},
                            SelectedValue => $Param{GetColumnFilter}->{$DynamicFieldName} || '',
                        );

                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicField'
                                . $DynamicFieldConfig->{Name}
                                . '_FiltrableSortable',
                            Data => {
                                %Param,
                                OrderBy          => $OrderBy,
                                Label            => $Label,
                                DynamicFieldName => $DynamicFieldConfig->{Name},
                                ColumnFilterStrg => $ColumnFilterHTML,
                                Title            => $Title,
                            },
                        );
                    }
                    else {
                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicField_'
                                . $DynamicFieldConfig->{Name}
                                . '_Sortable',
                            Data => {
                                %Param,
                                OrderBy          => $OrderBy,
                                Label            => $Label,
                                DynamicFieldName => $DynamicFieldConfig->{Name},
                                Title            => $Title,
                            },
                        );
                    }
                }
                else {

                    my $DynamicFieldName = 'DynamicField_' . $DynamicFieldConfig->{Name};
                    my $CSS              = $DynamicFieldName;

                    $LayoutObject->Block(
                        Name => 'OverviewNavBarPageDynamicField',
                        Data => {
                            %Param,
                            CSS => $CSS,
                        },
                    );

                    if ( $Object->{ValidFiltrableColumns}->{$DynamicFieldName} ) {

                        # variable to save the filter's HTML code
                        my $ColumnFilterHTML = $Object->_InitialColumnFilter(
                            ColumnName    => $DynamicFieldName,
                            Label         => $Label,
                            ColumnValues  => $ColumnValues->{$DynamicFieldName},
                            SelectedValue => $Param{GetColumnFilter}->{$DynamicFieldName} || '',
                        );

                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicFieldFiltrableNotSortable',
                            Data => {
                                %Param,
                                Label            => $Label,
                                DynamicFieldName => $DynamicFieldConfig->{Name},
                                ColumnFilterStrg => $ColumnFilterHTML,
                                Title            => $Title,
                                FilterTitle      => $FilterTitle,
                            },
                        );
                    }
                    else {
                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicFieldNotSortable',
                            Data => {
                                %Param,
                                Label => $Label,
                                Title => $Title,
                            },
                        );
                    }

                    # example of dynamic fields order customization
                    $LayoutObject->Block(
                        Name => 'OverviewNavBarPageDynamicField_' . $DynamicFieldConfig->{Name},
                        Data => {
                            %Param,
                        },
                    );

                    if ( $Object->{ValidFiltrableColumns}->{$DynamicFieldName} ) {

                        # variable to save the filter's HTML code
                        my $ColumnFilterHTML = $Object->_InitialColumnFilter(
                            ColumnName    => $DynamicFieldName,
                            Label         => $Label,
                            ColumnValues  => $ColumnValues->{$DynamicFieldName},
                            SelectedValue => $Param{GetColumnFilter}->{$DynamicFieldName} || '',
                        );

                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicField_'
                                . $DynamicFieldConfig->{Name}
                                . '_FiltrableNotSortable',
                            Data => {
                                %Param,
                                Label            => $Label,
                                DynamicFieldName => $DynamicFieldConfig->{Name},
                                ColumnFilterStrg => $ColumnFilterHTML,
                                Title            => $Title,
                            },
                        );
                    }
                    else {
                        $LayoutObject->Block(
                            Name => 'OverviewNavBarPageDynamicField_'
                                . $DynamicFieldConfig->{Name}
                                . '_NotSortable',
                            Data => {
                                %Param,
                                Label => $Label,
                                Title => $Title,
                            },
                        );
                    }
                }

            }

        }

        $LayoutObject->Block( Name => 'TableBody' );
    }
    else {
        $LayoutObject->Block( Name => 'NoConfigItemFound' );
    }

    for my $ConfigItemRef (@ConfigItemBox) {

        # get config item data
        my %ConfigItem = %{$ConfigItemRef};

        $LayoutObject->Block(
            Name => 'Record',
            Data => {%ConfigItem},
        );

        # check if bulk feature is enabled
        if ($BulkFeature) {
            $LayoutObject->Block(
                Name => 'GeneralOverviewRow',
            );
            $LayoutObject->Block(
                Name => Translatable('Bulk'),
                Data => {%ConfigItem},
            );
        }

        my $UserObject = $Kernel::OM->Get('Kernel::System::User');

        # save column content
        my $DataValue;

        my $Counter = 0;

        # show all needed columns
        CONFIGITEMCOLUMN:
        for my $ConfigItemColumn (@Col) {
            $LayoutObject->Block(
                Name => 'GeneralOverviewRow',
            );
            my $StaticColumn = !$Counter;
            $Counter++;

            if ( $ConfigItemColumn !~ m{\A DynamicField_}xms ) {
                $LayoutObject->Block(
                    Name => 'RecordConfigItemData',
                    Data => {},
                );

                if ( $SpecialColumns{$ConfigItemColumn} ) {
                    $LayoutObject->Block(
                        Name => 'Record' . $ConfigItemColumn,
                        Data => {
                            %ConfigItem,
                            StaticColumn => $StaticColumn,
                        },
                    );

                    next CONFIGITEMCOLUMN;
                }

                if ( $ConfigItemColumn eq 'CreatedBy' ) {

                    my %ConfigItemCreatedByInfo = $UserObject->GetUserData(
                        UserID => $ConfigItem{CreateBy},
                    );

                    $LayoutObject->Block(
                        Name => 'RecordConfigItemCreatedBy',
                        Data => {
                            %ConfigItemCreatedByInfo,
                            StaticColumn => $StaticColumn,
                        },
                    );
                    next CONFIGITEMCOLUMN;
                }

                my $BlockType = '';
                my $CSSClass  = $StaticColumn ? 'StaticColumn' : '';
                if (
                    $ConfigItemColumn eq 'DeplState'
                    || $ConfigItemColumn eq 'CurDeplState'
                    || $ConfigItemColumn eq 'InciState'
                    || $ConfigItemColumn eq 'CurInciState'
                    || $ConfigItemColumn eq 'Class'
                    )
                {
                    $BlockType = 'Translatable';
                    $DataValue = $ConfigItem{$ConfigItemColumn};
                }
                elsif ( $ConfigItemColumn eq 'Created' || $ConfigItemColumn eq 'Changed' ) {
                    $BlockType = 'Time';
                    $DataValue = $ConfigItem{$ConfigItemColumn};
                }
                else {
                    $DataValue = $ConfigItem{$ConfigItemColumn};

                    # If value is in date format, change block type to 'Time' so it can be localized. See bug#14542.
                    if (
                        defined $DataValue
                        && $DataValue =~ /^\d\d\d\d-(\d|\d\d)-(\d|\d\d)\s(\d|\d\d):(\d|\d\d):(\d|\d\d)$/
                        )
                    {
                        $BlockType = 'Time';
                    }
                }

                $LayoutObject->Block(
                    Name => "RecordConfigItemColumn$BlockType",
                    Data => {
                        GenericValue => $DataValue || '-',
                        Class        => $CSSClass  || '',
                    },
                );
            }

            # dynamic fields
            else {

                # cycle trough the activated dynamic fields for this screen
                my $DynamicFieldConfig;
                my $DFColumn = $ConfigItemColumn;
                $DFColumn =~ s/DynamicField_//g;
                DYNAMICFIELD:
                for my $DFConfig ( @{ $Object->{DynamicField} } ) {
                    next DYNAMICFIELD if !IsHashRefWithData($DFConfig);
                    next DYNAMICFIELD if $DFConfig->{Name} ne $DFColumn;

                    $DynamicFieldConfig = $DFConfig;
                    last DYNAMICFIELD;
                }
                next CONFIGITEMCOLUMN if !IsHashRefWithData($DynamicFieldConfig);

                # get field value
                my $Value = $DynamicFieldBackendObject->ValueGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $ConfigItem{VersionID},
                );

                my $ValueStrg = $DynamicFieldBackendObject->DisplayValueRender(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    Value              => $Value,
                    ValueMaxChars      => 20,
                    LayoutObject       => $LayoutObject,
                );

                $LayoutObject->Block(
                    Name => 'RecordDynamicField',
                    Data => {
                        Value => $ValueStrg->{Value},
                        Title => $ValueStrg->{Title},
                    },
                );

                if ( $ValueStrg->{Link} ) {
                    $LayoutObject->Block(
                        Name => 'RecordDynamicFieldLink',
                        Data => {
                            Value                       => $ValueStrg->{Value},
                            Title                       => $ValueStrg->{Title},
                            Link                        => $ValueStrg->{Link},
                            $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                        },
                    );
                }
                else {
                    $LayoutObject->Block(
                        Name => 'RecordDynamicFieldPlain',
                        Data => {
                            Value => $ValueStrg->{Value},
                            Title => $ValueStrg->{Title},
                        },
                    );
                }

                # example of dynamic fields order customization
                $LayoutObject->Block(
                    Name => 'RecordDynamicField_' . $DynamicFieldConfig->{Name},
                    Data => {
                        Value => $ValueStrg->{Value},
                        Title => $ValueStrg->{Title},
                    },
                );

                if ( $ValueStrg->{Link} ) {
                    $LayoutObject->Block(
                        Name => 'RecordDynamicField_' . $DynamicFieldConfig->{Name} . '_Link',
                        Data => {
                            Value                       => $ValueStrg->{Value},
                            Title                       => $ValueStrg->{Title},
                            Link                        => $ValueStrg->{Link},
                            $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                        },
                    );
                }
                else {
                    $LayoutObject->Block(
                        Name => 'RecordDynamicField_' . $DynamicFieldConfig->{Name} . '_Plain',
                        Data => {
                            Value => $ValueStrg->{Value},
                            Title => $ValueStrg->{Title},
                        },
                    );
                }
            }
        }

        # add action items as js
        if ( $ConfigItem{ActionItems} ) {

            # replace TT directives from string with values
            for my $ActionItem ( @{ $ConfigItem{ActionItems} } ) {
                $ActionItem->{Link} = $LayoutObject->Output(
                    Template => $ActionItem->{Link},
                    Data     => {
                        ConfigItemID => $ConfigItem{ConfigItemID},
                    },
                );
            }

            # $ActionRowConfigItems{ $ConfigItem{ConfigItemID} } = $LayoutObject->JSONEncode( Data => $ConfigItem{ActionItems} );
            $LayoutObject->AddJSData(
                Key   => 'ITSMConfigItemActionRow.' . $ConfigItem{ConfigItemID},
                Value => $ConfigItem{ActionItems},
            );
        }

    }

    # if total items outnumbers items per page, display only the first page and issue an explanation below table
    if ( $ConfigItemData == $Self->{Config}->{Limit} && $Param{Total} > $Self->{Config}->{Limit} ) {
        my $LimitedItemsMessage = $LayoutObject->{LanguageObject}->Translate( 'Showing only the first %d items of %d', $Self->{Config}->{Limit}, $Param{Total} );
        $LayoutObject->Block(
            Name => 'LimitedItemsMessage',
            Data => { Message => $LimitedItemsMessage }
        );
    }

    # set column filter form, to correctly fill the column filters is necessary to pass each
    #    overview some information in the AJAX call, for example the fixed Filters or NavBarFilters
    #    and also other values like the Queue in AgentITSMConfigItemQueue, otherwise the filters will be
    #    filled with default restrictions, resulting in more options than the ones that the
    #    available config items should provide, see Bug#9902
    if ( IsHashRefWithData( $Param{ColumnFilterForm} ) ) {
        $LayoutObject->Block(
            Name => 'DocumentColumnFilterForm',
            Data => {},
        );

        for my $Element ( sort keys %{ $Param{ColumnFilterForm} } ) {
            $LayoutObject->Block(
                Name => 'DocumentColumnFilterFormElement',
                Data => {
                    ElementName  => $Element,
                    ElementValue => $Param{ColumnFilterForm}->{$Element},
                },
            );
        }
    }

    # use template

    my $Output = $LayoutObject->Output(
        TemplateFile => $TemplateFile,
        Data         => {
            %Param,
            Type => $Object->{ViewType},
        },
    );

    return $Output;
}

1;
