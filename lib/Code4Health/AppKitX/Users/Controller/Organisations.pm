package Code4Health::AppKitX::Users::Controller::Organisations;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

sub search
    : Local
    : Public
    : Args(0)
    : Path('/organisations/search')
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

    $c->stash->{current_view} = 'JSON';
    $c->stash->{json} = $response;
}

1;
