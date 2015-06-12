package Code4Health::AppKitX::Users::Controller::SSO;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

sub authenticate
    : Path('/authenticate.json')
    : Args(0)
    : Public
{
    my ($self, $c) = @_;
    $c->stash->{no_wrapper} = 1;
    # FIXME: send back with content type of json
    $c->response->headers->header('Content-Type', 'application/javascript');
    if($c->user)
    {
        # FIXME: need somewhere to get the photourl from.
        $c->stash->{data} = {name => $c->user->username, photourl => ''};
    }
    else
    {
        $c->stash->{data} = {name => '', photourl => ''};
    }
}

1;
