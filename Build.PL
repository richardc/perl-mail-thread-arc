use strict;
use Module::Build;

Module::Build->new(
    module_name => "Mail::Thread::Arc",
    license     => 'perl',
    requires    => {
        'Mail::Thread' => 0,
        'Date::Parse'  => 0,
        'List::Util'   => 0,
        'Test::More'   => 0,
    },
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;
