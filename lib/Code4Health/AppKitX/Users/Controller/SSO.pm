package Code4Health::AppKitX::Users::Controller::SSO;

use Moose;
use namespace::autoclean;
use Cpanel::JSON::XS;
use Code4Health::AppKitX::Users::Vanilla qw/vanilla_signature vanilla_request_validate/;
BEGIN { extends 'Catalyst::Controller'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

sub authenticate
    : Path('/authenticate.json')
    : Args(0)
    : Public
{
    my ($self, $c) = @_;
    $c->stash->{no_wrapper} = 1;
    my $client_id = $c->req->param('client_id');
    my $callback = $c->req->param('callback');
    my $timestamp = $c->req->param('timestamp');
    my $signature = $c->req->param('signature');
    $self->_bad_request($c, 'invalid_request', 'Invalid callback function') unless $callback =~ /^\w[\w_]*$/;
    $c->stash->{callback_func} = $callback;
    $self->_bad_request($c, 'invalid_request', 'The client_id parameter is missing.') unless $client_id;
    $self->_bad_request($c, 'invalid_client', 'Unknown client.') unless $client_id eq $c->config->{vanilla_client_id};

    my $secret = $c->config->{vanilla_secret};

    if($c->user)
    {
        # FIXME: need somewhere to get the photourl from.
        if($timestamp)
        {
            # FIXME: add roles
            $self->_bad_request($c, 'invalid_request', 'Missing signature parameter') unless $signature;
            $self->_bad_request($c, 'access_denied', 'Signature invalid') unless vanilla_request_validate($timestamp, $secret, $signature);

            my $current_time = time;
            my $timestamp_diff_allowed = $c->config->{vanilla_timestamp_margin} || 60*30;
            if($current_time - $timestamp_diff_allowed > $timestamp)
            {
                $self->_bad_request($c, 'invalid_request', 'The timestamp is invalid.');
            }

            $c->stash->{data} = {
                uniqueid => $c->user->id,
                email => $c->user->email_address,
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
    $c->response->headers->header('Content-Type', 'application/javascript');
}

sub _bad_request
{
    my ($self, $c, $problem, $message) = @_;
    $c->res->status(400);
    $c->res->body(encode_json({ error => $problem, message => $message }));
    $c->response->headers->header('Content-Type', 'application/javascript');
    $c->detach;
}

1;
