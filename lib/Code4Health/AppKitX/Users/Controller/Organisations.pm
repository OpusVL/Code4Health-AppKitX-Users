package Code4Health::AppKitX::Users::Controller::Organisations;

use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller::REST' }
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

sub search
    : Local
    : Public
    : Args(0)
    : Path('/organisations/search')
    : ActionClass('REST')
{
}

sub search_GET
    : Action
    : Public
{
    my ($self, $c) = @_;
    my $query = $c->req->query_params->{query};

    my @organisations = $c->model('Users::Organisation')
        ->search({
            name => { '-ilike' => "%$query%" }
        });

    my $response = {
        suggestions => [
            map { +{
                value => $_->name,
                data => $_->code,
            } } 
            @organisations
        ]
    };

    $self->status_ok($c, {
        entity => $response
    });
}

sub user_primary_org
    : Does('NeedsLogin')
    : Local
    : Public
    : Args(0)
    : Path('/organisations/user_primary_org')
    : ActionClass('REST')
{ }

sub user_primary_org_POST
    : Action
    : Public
{
    my ($self, $c) = @_;

    my $org = $c->req->body_params->{code};

    try {
        $c->user->update({
            primary_organisation_id => $org
        });
        $self->status_ok($c, {
            entity => { message => "Update successful" }
        });
    }
    catch {
        $c->response->status(500);
        $self->_set_entity($c, { message => $_ });
    };
}

1;
