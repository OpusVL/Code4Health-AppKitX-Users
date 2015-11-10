package Code4Health::AppKitX::Users::Controller::Users;

use Moose;
use Code4Health::AppKitX::Users::Form::RegistrationForm;
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
    my $form = Code4Health::AppKitX::Users::Form::RegistrationForm->new(
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

    my $community_code = $c->req->query_parameters->{community};
    my $community;
    if($community_code)
    {
        $community = $c->model('Users::Community')->find({ code => $community_code });
    }
    my $params = $c->req->body_parameters; # only take params via the post
    delete $params->{submit};

    if ($form->process(ctx => $c, params => $params)) {
        delete $params->{confirm_password};
        delete $params->{primary_organisation};
        # Avoid providing the empty string instead of null
        $params->{primary_organisation_id} ||= undef;
        $params->{primary_organisation_other} ||= undef;

        # When only one is selected, it's not an array
        $params->{email_preferences} = [ $params->{email_preferences} ]
            if not ref $params->{email_preferences};

        my ($user, $existed) = $c->model('Users')->resultset('Person')->add_user({
            %{$params},
            username => $form->value->{email_address},
            full_name => $form->value->{first_name} . " " . $form->value->{surname}
        });

        my $authed = $c->authenticate({
            username => $form->value->{email_address},
            password => $form->value->{password},
        });

        if ($existed) {
            if (not $authed) {
                # Send an email about this to the user, in lieu of the
                # verification link.
                $self->_reregister_email($c, $user);
            }
            else {
                $c->flash->{status_msg} = "An account with these credentials
                already exists, so we logged you in. Please update your profile
                if necessary.";

                return $c->res->redirect('/');
            }
        }
        else {
            # A new user should be set up this way, but an existing user should
            # not have their previous info clobbered.
            if($community)
            {
                $user->create_related('community_links', { community_id => $community->id });
            }

            $self->_verification_email($c, $user);
        }
        $c->flash->{status_msg} = "Registration successful! Please check your email for a verification link.";
        $c->res->redirect('/');
    }

    $c->stash(
        render_form => $form->render
    );

    push @{$c->stash->{app_scripts}}, 'js/register.js';
    push @{$c->stash->{app_css}}, 'css/organisations.css';

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

sub _reregister_email {
    my ($self, $c, $user) = @_;

    $c->stash->{user_name} = $user->full_name;
    $c->stash->{no_wrapper} = 1;
    $c->stash->{template} = 'modules/users/email_reregister.tt';
    $c->forward($c->view('AppKitTT'));
    my $email_body = $c->res->body;

    ## TT view tends to leave a bunch of newlines
    $email_body =~ s/(?:^\s*$)+//m;

    $c->log->debug($email_body);

    $c->stash->{email} = {
        to => $user->username,
        from => $c->config->{system_email_address},
        subject => "Code4Health User Registration",
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

sub join_community
    : Public
    : Local
    : Args(0)
    : Does('NeedsLogin')
    : POST
{
    my ($self, $c) = @_;
    my $params = $c->req->body_parameters; # only take params via the post
    my $community_code = $params->{community};
    $c->detach('/not_found') unless uc $c->req->method eq 'POST';
    $c->stash->{no_wrapper} = 1;
    $c->response->headers->header('Content-Type', 'application/json');
    $c->stash->{data} = $c->user->join_community($community_code);
}

sub leave_community
    : Public
    : Local
    : Args(0)
    : Does('NeedsLogin')
    : POST
{
    my ($self, $c) = @_;
    my $params = $c->req->body_parameters; # only take params via the post
    my $community_code = $params->{community};
    $c->detach('/not_found') unless uc $c->req->method eq 'POST';
    $c->stash->{no_wrapper} = 1;
    $c->response->headers->header('Content-Type', 'application/json');
    $c->stash->{data} = $c->user->leave_community($community_code);
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

    $form
        ->get_field('current_pass')
        ->constraint({
            type => 'Callback',
            callback => sub { !$_[0] || $c->user->check_password($_[0]) },
            message => "Invalid password",
        });

    my $required_with_other = sub {
        my ($params, $self) = @_;

        return $params->{'registrant_category'} eq 'other'
    };

    $form->get_all_element({name => 'registrant_category'})->constraint([
        {
            type     => 'Required',
            message  => "Please select a description",
        },
        {
            type             => 'DependOn',
            others           => [ 'registrant_category_other' ],
            attach_errors_to => ['registrant_category_other'],
            message          => "Please enter a short description",
            when             => {
                callback => $required_with_other,
            }
        }
    ]);

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
            registrant_category => $form->param_value('registrant_category'),
            registrant_category_other => $form->param_value('registrant_category_other'),
            email_preferences => [ $form->param_list('email_preferences') ],
            $form->param_value('password')
                ? (password => $form->param_value('password'))
                : (),
        });
        $self->update_prefs_values($c, $user);
        $c->flash->{status_msg} = "Profile saved";
        return $c->res->redirect($c->req->uri);
    }

    $c->stash->{secondary_organisations} = [
        $c->user
            ->secondary_organisations
            ->search({}, { order_by => \"REPLACE(name, ',', '')" })
    ];
    $c->stash->{communities} = [$c->user->communities->active->all];
    $c->stash->{template} = 'modules/users/organisations_form.tt';
    $c->stash->{no_wrapper} = 1;
    $c->forward($c->view('AppKitTT'));
    my $organisations_form = $c->res->body;

    $c->stash->{no_wrapper} = 0;
    push @{$c->stash->{app_scripts}}, '/js/organisations.js';
    push @{$c->stash->{app_scripts}}, '/js/communities.js';
    push @{$c->stash->{app_css}}, '/css/organisations.css';
    $c->stash( organisations_form => $organisations_form );

    $c->stash( profile_form => $form->render );
    $c->detach(qw/Controller::Root default/);
}

sub _object_defaults {
    my ($self, $object) = @_;

    return {
        email_address => $object->email_address,
        title => $object->title,
        first_name => $object->first_name,
        surname => $object->surname,
        registrant_category => $object->registrant_category,
        registrant_category_other => $object->registrant_category_other,
        email_preferences => $object->email_preferences,
    };
}

=head1 NAME

Code4Health::AppKitX::Users::Controller:Users -

=head1 DESCRIPTION

=head1 METHODS

=head2 register

Attempts to register a new user.

If, when the form is posted, the email address already exists in the database,
it will do one of two things. If the password was correct, the user is logged in
with a message to say to check their profile is correct (the data in the form
may differ). If the password was incorrect, an email is sent to the user asking
them if they need a password reset.

In all cases the outcome on the page will be apparent success.

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT and LICENSE

Copyright (C) 2015 OpusVL

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut

1;
