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
        my $user = $c->model('Users')->resultset('Person')->add_user({
            %{$form->value},
            username => $form->value->{email_address},
            full_name => $form->value->{first_name} . " " . $form->value->{surname}
        });
        $c->authenticate({
            username => $form->value->{email_address},
            password => $form->value->{password},
        });
        
        $self->_verification_email($c, $user);

        $c->flash->{status_msg} = "Registration successful! Please check your email for a verification link.";
        $c->res->redirect('/');
    }

    $c->stash(
        render_form => $form->render
    );

    $c->detach(qw/Controller::Root default/);
}

sub resend_verification_email
    : Public
    : Path('/resend_verification_email')
    : Does('NeedsLogin')
    : Args(0)
{
    my ($self, $c) = @_;
    my $user = $c->user;

    $self->_verification_email($c, $user);

    $c->flash->{status_msg} = "Verification email sent.";
    $c->res->redirect($c->uri_for($self->action_for('profile')));
}

sub _verification_email {
    my ($self, $c, $user) = @_;

    my $verification = $c->model('Users::EmailVerification')->generate($user->username);
    $c->stash->{user_name} = $user->full_name;
    $c->stash->{email_hash} = $verification->hash;
    $c->stash->{no_wrapper} = 1;
    $c->stash->{template} = 'modules/users/email_verification.tt';
    $c->forward($c->view('AppKitTT'));
    my $email_body = $c->res->body;

    ## TT view tends to leave a bunch of newlines
    $email_body =~ s/(?:^\s*$)+//m;

    $c->log->debug($email_body);

    $c->stash->{email} = {
        to => $user->username,
        from => $c->config->{system_email_address},
        subject => "Code4Health Email Verification",
        body => $email_body,
    };

    $c->forward($c->view('Email'));

}

# Note that this is a GET request that changes things. This felt bad but the
# consensus on the internet is that it's OK.
sub verify_email
    : Public
    : Path('/verify_email')
    : Args(1)
{
    my ($self, $c, $token) = @_;

    my $verification = $c->model('Users::EmailVerification')->find({
        hash => $token
    })
        or $c->go('/not_found');

    my $user = $c->model('Users::Person')->find({
        username => $verification->email
    })
        or $c->go('/not_found');

    $user->add_to_group('Verified');
    $verification->delete;

    $c->flash->{status_msg} = "Verification complete!";
    $c->res->redirect('/');
}

sub profile
    : Public
    : Path('/profile')
    : Args(0)
    : AppKitForm
    : Does('NeedsLogin')
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
