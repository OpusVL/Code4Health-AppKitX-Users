requires 'Moose';
requires 'namespace::autoclean';
requires 'OpusVL::AppKit';
requires 'OpusVL::AppKitX::PreferencesAdmin';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Code4Health::DB';
requires 'String::Compare::ConstantTime';
requires 'HTML::FormHandlerX::Field::noCAPTCHA';

test_requires 'OpusVL::AppKitX::PasswordReset';

build_requires 'Catalyst::Runtime' => '5.80015';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

