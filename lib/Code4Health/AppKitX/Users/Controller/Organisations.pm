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

    if ($c->req->query_params->{want_other}) {
        unshift @{$response->{suggestions}}, {
            value => "OTHER",
            data => '',
        };
    }

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
    my $other = $c->req->body_params->{other};

    try {
        $c->user->update({
            primary_organisation_id => $org || undef,
            primary_organisation_other => $other,
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

sub user_secondary_org
    : Does('NeedsLogin')
    : Local
    : Public
    : Args
    : Path('/organisations/user_secondary_org')
    : ActionClass('REST')
{
    my ($self, $c, $code) = @_;
    $c->stash->{code} = $code;
}

sub user_secondary_org_POST
    : Action
    : Public
    : PathPart('')
    : Chained('user_secondary_org')
{
    my ($self, $c) = @_;
    my $code = $c->req->body_params->{code};

    my $org = $c->model('Users::Organisation')->find($code);

    $c->user->add_to_secondary_organisations($org);

    $self->status_ok($c, {
        entity => {
            name => $org->name,
            code => $org->code,
        }
    })
}

sub user_secondary_org_DELETE
    : Action
    : Public
    : PathPart('')
    : Chained('user_secondary_org')
{
    my ($self, $c) = @_;
    my $code = $c->stash->{code};

    my @link = $c->user->secondary_organisation_links->search({
        organisation_id => $code
    });

    if (! @link) {
        $c->status_not_found($c, { message => "User is not associated with this organisation" });
        $c->detach;
    }

    $link[0]->delete;
    $self->status_no_content($c);
}

1;
