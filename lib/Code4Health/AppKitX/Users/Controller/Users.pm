package Code4Health::AppKitX::Users::Controller::Users;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'Users',
    # appkit_icon                 => 'static/images/flagA.jpg',
    appkit_myclass              => 'Code4Health::AppKitX::Users',
    # appkit_method_group         => 'Extension A',
    # appkit_method_group_order   => 2,
    # appkit_shared_module        => 'ExtensionA',
);

# sub home
#     :Path
#     :Args(0)
#     :NavigationHome
#     :AppKitFeature('Extension A')
# {
#     my ($self, $c) = @_;
# }

=head1 NAME

Code4Health::AppKitX::Users::Controller:Users - 

=head1 DESCRIPTION

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT and LICENSE

Copyright (C) 2015 OpusVL

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

