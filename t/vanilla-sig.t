use Test::Most;

use Code4Health::AppKitX::Users::Vanilla qw/vanilla_signature/;

my $data = {
    uniqueid => 10,
    email => 'support@opusvl.com',
    name => 'support', 
    photourl => '',
    client_id => 'test',
};
is '0a7246db17540a579a23195633fcc3a712811484', vanilla_signature($data,'test');

done_testing;
