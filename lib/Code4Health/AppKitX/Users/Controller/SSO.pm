package Code4Health::AppKitX::Users::Controller::SSO;

use Moose;
use namespace::autoclean;
use Cpanel::JSON::XS;
use Code4Health::AppKitX::Users::Vanilla qw/vanilla_signature/;
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
    my $client_id = $c->req->param('client_id');
    my $callback = $c->req->param('callback');
    my $timestamp = $c->req->param('timestamp');
    # FIXME: verify the timestamp.
    my $signature = $c->req->param('signature');
    $self->_bad_request('Invalid callback function') unless $callback =~ /^\w[\w_]*$/;
    $c->stash->{callback_func} = $callback;
    $self->_bad_request('Specify client id') unless $client_id;
    $self->_bad_request('Incorrect client id') unless $client_id eq $c->config->{vanilla_client_id};

    my $secret = $c->config->{vanilla_secret};

    if($c->user)
    {
        # FIXME: need somewhere to get the photourl from.
        if($timestamp)
        {
            # FIXME: add roles
            $c->stash->{data} = {
                uniqueid => $c->user->id,
                email => $c->user->email,
                name => $c->user->username, 
                photourl => '',
                client_id => $client_id,
            };
            $c->stash->{data}->{signature} = vanilla_signature($c->stash->{data}, $secret);
        }
        else
        {
            $c->stash->{data} = {
                name => $c->user->username, 
                photourl => '',
            };
        }
    }
    else
    {
        $c->stash->{data} = {name => '', photourl => ''};
    }
}

sub _bad_request
{
    my ($self, $c, $problem) = @_;
    $c->res->status(400);
    $c->res->content(encode_json({ error => $problem }));
    $c->detach;
}

1;
