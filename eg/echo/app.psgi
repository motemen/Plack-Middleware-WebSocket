#!perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Plack::Builder;
use Plack::Request;
use AnyEvent;
use AnyEvent::Handle;

my $DATA = do { local $/; scalar <DATA> };

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);

    if (not $env->{'psgi.streaming'}) {
        die 'this handler does not support psgi.streaming';
    }

    if ($req->path eq '/') {
        my $data = $DATA;
        $data =~ s/{{{HOST}}}/$env->{HTTP_HOST}/g;
        $res->content_type('text/html; charset=utf-8');
        $res->content($data);
    }
    elsif ($req->path eq '/echo') {
        if (my $fh = $env->{'websocket.impl'}->handshake) {
            return start_ws_echo($fh);
        }
        $res->code($env->{'websocket.impl'}->error_code);
    }
    else {
        $res->code(404);
    }
    
    return $res->finalize;
};

sub start_ws_echo {
    my ($fh) = @_;

    my $handle = AnyEvent::Handle->new(fh => $fh);
    return sub {
        my $respond = shift;

        on_read $handle sub {
            shift->push_read(
                'AnyEvent::Handle::Message::WebSocket',
                sub {
                    my $msg = $_[1];
                    my $w; $w = AE::timer 1, 0, sub {
                        $handle->push_write(
                            'AnyEvent::Handle::Message::WebSocket',
                            $msg,
                        );
                        undef $w;
                    };
                },
            );
        };

        on_error $handle sub {
            warn "error: $_[2]";
            $respond->([
                500, [ 'Content-Type', 'text/plain' ], [ "error: $_[2]" ],
            ]);
        };
    };
}

builder {
    enable 'WebSocket';
    $app;
};

__DATA__
<!DOCTYPE html>
<html>
  <head>
    <title>Plack::Middleware::WebSocket</title>
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
    <style type="text/css">
#log {
  border: 1px solid #DDD;
  padding: 0.5em;
}
    </style>
  </head>
  <body>
    <script type="text/javascript">
function log (msg) {
  $('#log').text($('#log').text() + msg + "\n");
}

$(function () {
  var ws = new WebSocket('ws://{{{HOST}}}/echo');

  log('WebSocket start');

  ws.onopen = function () {
    log('connected');
  };

  ws.onmessage = function (ev) {
    log('received: ' + ev.data);
  };

  ws.onerror = function (ev) {
    log('error: ' + ev.data);
  }

  ws.onclose = function (ev) {
    log('closed');
  }

  $('#form').submit(function () {
    var data = $('#message').val();
    ws.send(data);
    $('#message').val('');
    log('sent: ' + data);
    return false;
  });
});
    </script>
    <form id="form">
      <input type="text" name="message" id="message" />
      <input type="submit" />
    </form>
    <pre id="log"></pre>
  </body>
</html>
