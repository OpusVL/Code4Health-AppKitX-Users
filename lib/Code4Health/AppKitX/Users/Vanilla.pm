package Code4Health::AppKitX::Users::Vanilla;

use URI::Escape;
use Digest::SHA1 qw/sha1_hex/;
use String::Compare::ConstantTime;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/vanilla_signature vanilla_request_validate/;

sub vanilla_signature
{
    my $data = shift;
    my $secret = shift;

    my @parts = map { sprintf "%s=%s", $_, uri_escape($data->{$_}) } 
                sort { $a cmp $b } grep { $_ !~ /client_id/ } keys %$data;

    my $combined = join '&', @parts;
    my $signature = sha1_hex($combined . $secret);

    return $signature;
}

sub vanilla_request_validate
{
    my ($timestamp, $secret, $signature) = @_;
    my $expected = sha1_hex($timestamp . $secret);
    return String::Compare::ConstantTime::equals($signature, $expected);
}

1;
