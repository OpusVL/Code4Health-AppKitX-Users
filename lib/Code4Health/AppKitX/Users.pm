package Code4Health::AppKitX::Users;
use Moose::Role;
use CatalystX::InjectComponent;
use File::ShareDir qw/module_dir/;
use namespace::autoclean;

with 'OpusVL::AppKit::RolesFor::Plugin';

our $VERSION = '0.05';

after 'setup_components' => sub {
    my $class = shift;
   
    $class->add_paths(__PACKAGE__);
    
    # .. inject your components here ..
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'Code4Health::AppKitX::Users::Controller::Users',
        as        => 'Controller::Modules::Users'
    );
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'Code4Health::AppKitX::Users::Controller::SSO',
        as        => 'Controller::Modules::SSO'
    );
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'Code4Health::AppKitX::Users::Controller::Organisations',
        as        => 'Controller::Modules::Organisations'
    );
    CatalystX::InjectComponent->inject(
        into      => $class,
        component => 'Code4Health::AppKitX::Users::Model::Users',
        as        => 'Model::Users'
    );
};

1;

=head1 NAME

Code4Health::AppKitX::Users - 

=head1 DESCRIPTION

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT and LICENSE

Copyright (C) 2015 OpusVL

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

