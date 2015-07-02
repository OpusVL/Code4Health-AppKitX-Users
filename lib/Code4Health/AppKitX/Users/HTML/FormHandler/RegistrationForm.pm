package Code4Health::AppKitX::Users::HTML::FormHandler::RegistrationForm;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

with 'HTML::FormHandler::Widget::Wrapper::Bootstrap3';

has '+widget_wrapper' => (
    default => 'Bootstrap3'
);

has '+is_html5' => (
    default => 1
);

has_field email_address => (
    type => 'Email',
    required => 1,
);
has_field password => (
    type => 'Password',
    required => 1,
);
has_field confirm_password => (
    type => 'Password',
    required => 1,
);
has_field title => (
    type => 'Select',
    options => [
        map +{ value => $_, label => $_ }, qw/Mr Mrs Miss Ms Mx Dr/
    ],
);
has_field first_name => (
    required => 1,
);
has_field surname => (
    required => 1,
);
has_field primary_organisation => ();
has_field primary_organisation_id => (
    type => 'Hidden',
);
has_field primary_organisation_other => (
    type => 'Text',
    label => 'Other Organisation Name',
);

sub html_attributes {
    my ( $self, $obj, $type, $attrs, $result ) = @_;

    if ($type eq 'wrapper') {
        if ($obj->name eq 'primary_organisation_other') {
            # Ensure the field is visible or not, as relevant, when the form is
            # re-rendered for whatever reason.
            unless ($self->field('primary_organisation')->value eq 'OTHER') {
                $attrs->{class} = ['hidden'];
            }
        }
    }
}

sub validate {
    my $self = shift;

    PASS: {
        my $pass = $self->field('password');
        my $conf = $self->field('confirm_password');

        $conf->add_error("Passwords do not match!"), $pass->add_error('') 
            unless $conf->value eq $pass->value;
    }

    ORG: {
        my $org = $self->field('primary_organisation');
        my $org_id = $self->field('primary_organisation_id');
        my $org_other = $self->field('primary_organisation_other');

        last ORG if $org_id->value;

        if (not $org_id->value and not $org->value) {
            $org->add_error("Please select your primary organisation");
        }

        if ($org->value eq 'OTHER' and not $org_other->value) {
            $org_other->add_error("Please enter your organisation's name");
        }
    }

}

1;
