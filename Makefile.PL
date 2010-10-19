use inc::Module::Install;

name 'Plack-Middleware-WebSocket';
all_from 'lib/Plack/Middleware/WebSocket.pm';

# requires '';

test_requires 'Test::More';

tests 't/*.t';
# author_tests 'xt';

auto_include;

WriteAll;
