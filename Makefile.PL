use inc::Module::Install;

name 'Plack-Middleware-WebSocket';
all_from 'lib/Plack/Middleware/WebSocket.pm';

requires 'Plack::Middleware';
requires 'Plack::Util::Accessor';
requires 'parent';
requires 'Scalar::Util';
requires 'IO::Handle';
requires 'Digest::MD5';

test_requires 'Test::More';

tests 't/*.t';
# author_tests 'xt';

auto_include;

WriteAll;
