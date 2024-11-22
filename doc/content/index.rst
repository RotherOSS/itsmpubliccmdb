.. image:: ../images/otobo-logo.png
   :align: center

.. toctree::
    :maxdepth: 2
    :caption: Contents

Sacrifice to Sphinx
===================

Overview
========
Summary
-------
Provides the Public interface with a view of the CMDB Config Items.

Introduction
------------
This package provides the Public interface with a feature to view the defined CMDB Config Items. Item searching and zooming into item details are also possible. The access is limited to read-only mode, meaning that no insertions, updates or deletions are possible. Item version details are not available by default and backlinks are not displayed either.

Configuration
=============

System requirements
-------------------

Framework
^^^^^^^^^
OTOBO 11.0.x

Packages
^^^^^^^^
ITSMConfigurationManagement 11.0.1

Third-party software
^^^^^^^^^^^^^^^^^^^^
Not applicable

Basic Configuration
-------------------
Open the Package Manager module from the Administration group in the Agent Interface. Select the package named ITSMPublicCMDB from the Online Repository. Click the associated  *Install* link on that line and
respond affirmatively to any confirmation questions that may follow.

For each class to be viewed, add the *Public* item to its Interfaces list (through *Admin->Config Items->Change Class Definition*).

Custom Configuration and Advanced Features
------------------------------------------
By default, item version details are not traceable. However, that feature may be activated by enabling the system configs *ITSMConfigItem::Frontend::PublicITSMConfigItemZoom###VersionsEnabled* and *ITSMConfigItem::Frontend::PublicITSMConfigItemZoom###VersionsSelectable*.

Configuration Reference
-----------------------

Core::ITSMConfigItem
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Public::ConfigItem::PermissionConditions###01
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Define a set of conditions under which a config item can be publicly seen. Name is the only mandatory attribute. If no other options are given, all config items will be visible under that category.

Public::ConfigItem::PermissionConditions###02
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Define a set of conditions under which a config item can be publicly seen. Name is the only mandatory attribute. If no other options are given, all config items will be visible under that category.

Public::ConfigItem::PermissionConditions###03
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Define a set of conditions under which a config item can be publicly seen. Name is the only mandatory attribute. If no other options are given, all config items will be visible under that category.

Public::ConfigItem::PermissionConditions###05
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Define a set of conditions under which a config item can be publicly seen. Name is the only mandatory attribute. If no other options are given, all config items will be visible under that category.

Public::ConfigItem::PermissionConditionColumns###01
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


Public::ConfigItem::PermissionConditionColumns###03
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


Public::ConfigItem::PermissionConditionColumns###05
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


Public::ConfigItem::PermissionConditions###04
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Define a set of conditions under which a config item can be publicly seen. Name is the only mandatory attribute. If no other options are given, all config items will be visible under that category.

Public::ConfigItem::PermissionConditionColumns###Default
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


Public::ConfigItem::PermissionConditionColumns###02
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


Public::ConfigItem::PermissionConditionColumns###04
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


Frontend::Public
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

AutoComplete::Public###Default
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the config options for the autocompletion feature.

PublicColorDefinitions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Color definitions for the public interface.

Frontend::Public::ITSMConfigItemOverview
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ITSMConfigItem::Frontend::PublicOverview###Small
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines an overview module to show the small view of a configuration item list.

Frontend::Public::ModuleRegistration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

PublicFrontend::Module###PublicITSMConfigItem
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Frontend module registration for the public interface.

PublicFrontend::Module###PublicITSMConfigItemZoom
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Frontend module registration for the public interface.

PublicFrontend::Module###PublicITSMConfigItemSearch
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Frontend module registration for the public interface.

PublicFrontend::Module###PublicITSMConfigItemAttachment
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Frontend module registration for the public interface.

Frontend::Public::ModuleRegistration::Loader
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Loader::Module::PublicITSMConfigItemSearch###003-ITSMConfigItem
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the public interface.

Loader::Module::PublicITSMConfigItem###003-ITSMConfigItem
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the public interface.

Loader::Module::PublicITSMConfigItemZoom###003-ITSMConfigItem
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Loader module registration for the public interface.

Frontend::Public::ModuleRegistration::MainMenu
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

PublicFrontend::Navigation###PublicITSMConfigItem###003-ITSMConfigItem
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Main menu item registration.

Frontend::Public::View::ConfigItem
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ITSMConfigItem::Frontend::PublicITSMConfigItem###PageShown
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Number of config items to be displayed in each page of the public interface.

Frontend::Public::View::ConfigItemSearch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###SortBy::Default
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the default config item attribute for config item sorting of the config item search result of the public interface.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###Defaults###Number
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the default shown config item search attribute for config item search screen.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###ExtendedSearchCondition
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Allows extended search conditions in config item search of the public interface. With this feature you can search e. g. config item name with this kind of conditions like "(*key1*&&*key2*)" or "(*key1*||*key2*)".

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###Defaults###DeploymentStateIDs
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the default shown config item search attribute for config item search screen.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###Defaults###DynamicField
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the default shown config item search attribute for config item search screen. Example: "Key" must have the name of the Dynamic Field in this case 'X', "Content" must have the value of the Dynamic Field depending on the Dynamic Field type,  Text: 'a text', Dropdown: '1', Date/Time: 'Search_DynamicField_XTimeSlotStartYear=1974; Search_DynamicField_XTimeSlotStartMonth=01; Search_DynamicField_XTimeSlotStartDay=26; Search_DynamicField_XTimeSlotStartHour=00; Search_DynamicField_XTimeSlotStartMinute=00; Search_DynamicField_XTimeSlotStartSecond=00; Search_DynamicField_XTimeSlotStopYear=2013; Search_DynamicField_XTimeSlotStopMonth=01; Search_DynamicField_XTimeSlotStopDay=26; Search_DynamicField_XTimeSlotStopHour=23; Search_DynamicField_XTimeSlotStopMinute=59; Search_DynamicField_XTimeSlotStopSecond=59;' and or 'Search_DynamicField_XTimePointFormat=week; Search_DynamicField_XTimePointStart=Before; Search_DynamicField_XTimePointValue=7';.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###IncidentState
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Includes incident states in the config item search of the public interface.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###SearchPageShown
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Number of config items to be displayed in each page of a search result in the public interface.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###Order::Default
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the default config item order in the config item search result of the public interface. Up: oldest on top. Down: latest on top.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###Defaults###Name
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the default shown config item search attribute for config item search screen.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###Defaults###IncidentStateIDs
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the default shown config item search attribute for config item search screen.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###Permission
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Required permissions to use the ITSM configuration item search screen in the public interface.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###DeploymentState
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Includes deployment states in the config item search of the public interface.

Frontend::Public::View::ITSMConfigItemOverview
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###DynamicField
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Dynamic fields shown in the config item overview screen of the public interface.

Frontend::Public::View::ITSMConfigItemSearch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###SearchLimit
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the search limit for the PublicITSMConfigItemSearch screen.

ITSMConfigItem::Frontend::PublicITSMConfigItemSearch###SuppressFuzzyLogic
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Defines the search limit for the PublicITSMConfigItemSearch screen.

Frontend::Public::View::ITSMConfigItemZoom
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ITSMConfigItem::Frontend::PublicITSMConfigItemZoom###VersionsEnabled
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Public users can see historic CI versions.

ITSMConfigItem::Frontend::PublicITSMConfigItemZoom###VersionsSelectable
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Public users have the possibility to manually switch between historic CI versions.

ITSMConfigItem::Frontend::PublicITSMConfigItemZoom###GeneralInfo
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Which general information is shown in the header.

About
=======

Contact
-------
| Rother OSS GmbH
| Email: hello@otobo.io
| Web: https://otobo.io

Version
-------
Author: |doc-vendor| / Version: |doc-version| / Date of release: |doc-datestamp|
