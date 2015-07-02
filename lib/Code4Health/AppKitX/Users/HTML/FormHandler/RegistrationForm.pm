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

sub validate_confirm_password {
    my ($self, $field) = @_;
    my $pass = $self->field('password');

    $field->add_error("Passwords do not match!"), $pass->add_error('') 
        unless $field->value eq $pass->value;
}
1;
