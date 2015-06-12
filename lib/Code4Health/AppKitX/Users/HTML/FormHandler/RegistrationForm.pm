package Code4Health::AppKitX::Users::HTML::FormHandler::RegistrationForm;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

with 'HTML::FormHandler::Widget::Wrapper::Bootstrap3';

has '+widget_wrapper' => (
    default => 'Bootstrap3'
);

has_field username => ();
has_field password => (
    type => 'Password'
);
has_field title => ();
has_field first_name => ();
has_field surname => ();
has_field email_address => ();

1;
