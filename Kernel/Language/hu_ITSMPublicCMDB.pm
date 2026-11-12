# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Language::hu_ITSMPublicCMDB;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # SysConfig
    $Self->{Translation}->{'Color definitions for the public interface.'} = 'Színmeghatározások a nyilvános felülethez.';
    $Self->{Translation}->{'Defines the default config item attribute for config item sorting of the config item search result of the public interface.'} =
        'Meghatározza az alapértelmezett konfigurációelem-attribútumot a nyilvános felület konfigurációelem-keresési eredményének konfigurációelem-rendezéséhez.';
    $Self->{Translation}->{'Defines the default config item order in the config item search result of the public interface. Up: oldest on top. Down: latest on top.'} =
        'Meghatározza az alapértelmezett konfigurációelem-sorrendet a nyilvános felület konfigurációelem-keresési eredményében. Fel: legrégebbi felülre. Le: legutolsó felülre.';
    $Self->{Translation}->{'Defines the search limit for the PublicITSMConfigItemSearch screen.'} =
        'Meghatározza a keresési korlátot a PublicITSMConfigItemSearch képernyőn.';
    $Self->{Translation}->{'Dynamic fields shown in the config item overview screen of the public interface.'} =
        'A nyilvános felület konfigurációelem áttekintő képernyőjén megjelenített dinamikus mezők.';
    $Self->{Translation}->{'Includes classes in the config item search of the public interface.'} =
        'Felveszi az osztályokat a nyilvános felület konfigurációelem-keresésébe.';
    $Self->{Translation}->{'Includes deployment states in the config item search of the public interface.'} =
        'Felveszi az üzembe állítási állapotokat a nyilvános felület konfigurációelem-keresésébe.';
    $Self->{Translation}->{'Includes incident states in the config item search of the public interface.'} =
        'Felveszi az incidensállapotokat a nyilvános felület konfigurációelem-keresésébe.';
    $Self->{Translation}->{'Includes the name in the config item search of the public interface.'} =
        'Felveszi a nevet a nyilvános felület konfigurációelem-keresésébe.';
    $Self->{Translation}->{'Includes the number in the config item search of the public interface.'} =
        'Felveszi a számot a nyilvános felület konfigurációelem-keresésébe.';
    $Self->{Translation}->{'Loader module registration for the public interface.'} = 'Betöltőmodul regisztráció a nyilvános felülethez.';
    $Self->{Translation}->{'Number of config items to be displayed in each page of the public interface.'} =
        'A nyilvános felület minden egyes oldalán megjelenítendő konfigurációelemek száma.';
    $Self->{Translation}->{'Public users can see historic CI versions.'} = 'A nyilvános felhasználók láthatják a korábbi konfigurációelem-verziókat.';
    $Self->{Translation}->{'Public users have the possibility to manually switch between historic CI versions.'} =
        'A nyilvános felhasználóknak lehetőségük van kézileg váltani a korábbi konfigurációelem-verziók között.';
    $Self->{Translation}->{'Title for the public interface overview.'} = 'A nyilvános felület áttekintésének címe.';
    $Self->{Translation}->{'Title for the public interface search.'} = 'A nyilvános felület keresésének címe.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
