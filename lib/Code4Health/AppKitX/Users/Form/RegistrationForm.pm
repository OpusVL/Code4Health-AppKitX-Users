package Code4Health::AppKitX::Users::Form::RegistrationForm;

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
        map +{ value => $_, label => $_ }, qw/Mr Mrs Miss Ms Mx Dr Professor/
    ],
);
has_field first_name => (
    required => 1,
);
has_field surname => (
    required => 1,
);

# This is a shit way of adding help text, but there isn't another
has_field primary_organisation => (
    tags => {
        after_element => 
            qq{\n<span class="help-block">Enter "other" if your organisation does not appear</span>}
    }
);
has_field primary_organisation_id => (
    type => 'Hidden',
);
has_field primary_organisation_other => (
    type => 'Text',
    label => 'Other Organisation Name',
);

has_field registrant_category => (
    type => 'Select',
    widget => 'RadioGroup',
    label => "I am (select a single option that describes you)",
    options => [
        { 
            value => 'healthcare_professional',
            label => "A Healthcare Professional (including clinicians, managers and other professions)",
        },
        { 
            value => 'social_professional',
            label => "A Social Care Professional (including social workers, managers, care workers and other professions)",
        },
        { 
            value => 'software_developer',
            label => "A Software Developer (including engineers, designers and informaticians)",
        },
        { 
            value => 'civilian',
            label => "A Citizen, Patient or Carer",
        },
        { 
            value => 'other',
            label => "Other (please specify)",
        },
    ]
);
has_field registrant_category_other => (
    type => 'Text',
    label => "Other (please specify)",
);

has_field email_preferences => (
    type => 'Select',
    widget => 'CheckboxGroup',
    multiple => 1,
    label => "Email preferences",
    options => [
        {
            label => "General information, news, events and activities likely to
                be of interest to members from Code4Health",
            value => 'members'
        },
        {
            label => "Specific community information, news, events and activities 
                from those communities with which you have registered",
            value => 'communities'
        },
        {
            label => "Information about news, events and activities likely to be
                on interest to members from Code4Health Supporters",
            value => 'supporters'
        },
    ]
);

has_field submit => (
    type => 'Submit',
    value => 'Register',
);

has_block account_details => (
    tag => 'fieldset',
    label => "Account details",
    render_list => [qw/
        email_address password confirm_password
        title first_name surname primary_organisation primary_organisation_other 
    /]
);

has_block about_you => (
    tag => 'fieldset',
    label => "About you",
    render_list => [ qw/registrant_category registrant_category_other email_preferences submit/ ],
);

sub build_render_list {
    [qw/account_details about_you/]
};


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

        if ($org->value eq 'OTHER' and not $org_other->value) {
            $org_other->add_error("Please enter your organisation's name");
        }
    }

    CAT: {
        my $category = $self->field('registrant_category');
        my $other = $self->field('registrant_category_other');

        $category->add_error("Please select a description") and last CAT
            if not $category->value;

        last CAT if $category->value ne 'other';

        $other->add_error("Please enter a short description")
            if not $other->value;
    }

}

1;
