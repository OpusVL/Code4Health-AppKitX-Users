package Code4Health::AppKitX::Users::Controller::Users;

use Moose;
use Code4Health::AppKitX::Users::HTML::FormHandler::RegistrationForm;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
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

has 'registration_form' => (
    is => 'ro',
    isa => 'Object',
    builder => '_build_registration_form'
);

has 'prf_model' => (
    is => 'ro',
    default => 'Users',
);

has 'prf_owner' => (
    is => 'ro',
    default => 'Person'
);

with 'OpusVL::AppKitX::PreferencesAdmin::Role::ObjectPreferences';

sub _build_registration_form {
    my $form = Code4Health::AppKitX::Users::HTML::FormHandler::RegistrationForm->new(
        name => "registration_form",
        field_list => [
            submit => {
                type => 'Submit',
                value => 'Register',
            }
        ]
    );

    return $form;
}

sub register
    : Public
    : Path('/register')
    : Args(0)
{
    my ($self, $c) = @_;

    my $form = $self->registration_form;

    if ($form->process(ctx => $c, params => scalar $c->req->parameters)) {
        $c->model('Users')->resultset('Person')->add_user({
            %{$form->value},
            full_name => $form->value->{first_name} . " " . $form->value->{surname}
        });
        $c->authenticate({
            username => $c->req->param('username'),
            password => $c->req->param('password'),
        });
        $c->flash->{status_msg} = "Registration successful! Welcome to Code4Health";
        $c->res->redirect('/');
    }

    $c->stash(
        render_form => $form->render
    );

    $c->detach(qw/Controller::Root default/);
}

sub profile
    : Public
    : Path('/profile')
    : Args(0)
    : AppKitForm
{
    my ($self, $c) = @_;
    my $user = $c->user;
    my $form = $c->stash->{form};
    $self->construct_global_data_form($c, { object => $user });
    $form->process;

    my $defaults = $self->_object_defaults($user);
    $self->add_prefs_defaults($c, { 
        defaults => $defaults,
        object => $user,
    }); 
    $form->default_values($defaults);
    
    if($form->submitted_and_valid) {
        $user->update({
            email_address => $form->param_value('email_address'),
            title => $form->param_value('title'),
            first_name => $form->param_value('first_name'),
            surname => $form->param_value('surname'),
        });
        $self->update_prefs_values($c, $user);
        $c->res->redirect($c->req->uri);
        $c->flash->{status_msg} = "Profile saved";
    }

    $c->stash( render_form => $form->render );
    $c->detach(qw/Controller::Root default/);
}

sub _object_defaults {
    my ($self, $object) = @_;

    return {
        email_address => $object->email_address,
        title => $object->title,
        first_name => $object->first_name,
        surname => $object->surname,
    };
}

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

1;
